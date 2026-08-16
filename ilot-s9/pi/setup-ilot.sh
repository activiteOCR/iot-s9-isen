#!/usr/bin/env bash
#
# setup-ilot.sh — Configure un Raspberry Pi en passerelle d'ilot IoT
#
#   Usage :  sudo ./setup-ilot.sh <numero_ilot> [--garder-reseau]
#
#   <numero_ilot>     1 a 5
#   --garder-reseau   ne bascule PAS eth0 en statique (garde l'acces Internet
#                     de la box). Utile pendant la preparation ; a omettre
#                     pour la configuration definitive.
#
# Le Pi devient :
#   - point d'acces WiFi 2.4 GHz pour les ESP32 de l'ilot   (hostapd + dnsmasq)
#   - lien Ethernet statique vers le laptop de l'ilot        (eth0)
#   - broker MQTT de peripherie, bridge vers le broker central du laptop
#   - serveur HTTP des binaires firmware (OTA)
#
# IMPORTANT : le Pi doit avoir Internet au lancement (apt install).
# Branchez-le sur la box avant, pas sur le laptop.
#
# Pourquoi hostapd et pas le mode AP de NetworkManager : sur les puces
# Broadcom des Raspberry Pi, NM pilote le point d'acces via wpa_supplicant,
# dont l'implementation AP echoue avec "brcmf_vif_set_mgmt_ie: vndr ie set
# error : -52". La radio balise, mais aucun client ne peut jamais s'associer.
# Constate sur Pi 3B / Raspberry Pi OS Trixie. hostapd n'a pas ce probleme,
# et journalise chaque tentative d'association avec son motif de rejet.
#
# Teste sur Raspberry Pi OS Trixie (juin 2026), Raspberry Pi 3B.
#
set -euo pipefail

ILOT="${1:-}"
GARDER_RESEAU="${2:-}"

if ! [[ "$ILOT" =~ ^[1-5]$ ]]; then
    echo "Usage : sudo $0 <numero_ilot> [--garder-reseau]   (ilot 1 a 5)" >&2
    exit 1
fi
if [[ $EUID -ne 0 ]]; then
    echo "Ce script doit etre lance avec sudo." >&2
    exit 1
fi

# --- Plan de frequences -------------------------------------------------------
# Uniquement 1, 6 et 11 : seuls canaux 2.4 GHz sans recouvrement.
# Les ilots 4 et 5 reutilisent 1 et 6 : placez-les LOIN des ilots 1 et 2.
declare -A CANAUX=( [1]=1 [2]=6 [3]=11 [4]=1 [5]=6 )
CANAL="${CANAUX[$ILOT]}"

SSID="ilot-${ILOT}"
PSK="iot-s9-ilot-${ILOT}"            # a changer avant la premiere seance
SUBNET="192.168.$((10 * ILOT))"       # ilot 1 -> 192.168.10.0/24
IP_PI_WIFI="${SUBNET}.1"
IP_PI_ETH="10.10.${ILOT}.1"
IP_LAPTOP="10.10.${ILOT}.2"
TXPOWER_MBM=1000                      # 10 dBm : couvrir une table, pas la salle

echo "=============================================="
echo " Ilot ${ILOT}"
echo "   SSID          : ${SSID}"
echo "   Canal         : ${CANAL}"
echo "   Reseau WiFi   : ${SUBNET}.0/24  (Pi = ${IP_PI_WIFI})"
echo "   Lien laptop   : ${IP_PI_ETH} <-> ${IP_LAPTOP}"
if [[ "${GARDER_RESEAU}" == "--garder-reseau" ]]; then
echo "   eth0          : INCHANGE (--garder-reseau)"
fi
echo "=============================================="
echo

# --- 0. Connectivite ----------------------------------------------------------
# Echouer tout de suite plutot qu'a mi-parcours : le script installe des
# paquets, et il n'y a plus d'acces reseau une fois eth0 bascule en statique.
echo "[0/8] Verification de l'acces Internet"
if ! ping -c 1 -W 3 deb.debian.org >/dev/null 2>&1; then
    echo >&2
    echo "ERREUR : pas d'acces Internet." >&2
    echo "Branchez le Pi sur la box (pas sur le laptop) et relancez." >&2
    echo >&2
    echo "Si eth0 est deja en statique :" >&2
    echo "  sudo nmcli connection modify lien-laptop ipv4.method auto ipv4.addresses \"\"" >&2
    echo "  sudo nmcli connection up lien-laptop" >&2
    exit 1
fi

# --- 1. Paquets ---------------------------------------------------------------
# Tout est installe ici, tant que l'acces reseau existe encore.
echo "[1/8] Installation des paquets"
apt-get update -qq
apt-get install -y -qq \
    hostapd dnsmasq \
    mosquitto mosquitto-clients \
    nginx iw >/dev/null
systemctl unmask hostapd >/dev/null 2>&1 || true

# --- 2. Reglementation radio --------------------------------------------------
# Sans code pays, le noyau refuse le mode AP.
echo "[2/8] Domaine reglementaire -> FR"
raspi-config nonint do_wifi_country FR || iw reg set FR
rfkill unblock wifi

# --- 3. wlan0 retiree a NetworkManager ---------------------------------------
# NM et hostapd ne peuvent pas piloter la meme interface. C'est le point qui
# fait echouer la plupart des tutoriels : on installe hostapd sans dire a NM
# de lacher l'interface, et les deux se marchent dessus silencieusement.
echo "[3/8] wlan0 retiree a NetworkManager"
nmcli connection delete "${SSID}" 2>/dev/null || true
nmcli connection delete preconfigured 2>/dev/null || true
for c in $(nmcli -t -f NAME,TYPE connection show | awk -F: '$2=="802-11-wireless"{print $1}'); do
    nmcli connection delete "$c" 2>/dev/null || true
done

cat > /etc/NetworkManager/conf.d/99-ilot-unmanaged.conf <<'EOF'
[keyfile]
unmanaged-devices=interface-name:wlan0
EOF
systemctl reload NetworkManager
sleep 2

systemctl stop wpa_supplicant.service 2>/dev/null || true
systemctl disable wpa_supplicant.service 2>/dev/null || true
pkill -f "wpa_supplicant.*wlan0" 2>/dev/null || true
sleep 1

# --- 4. Adresse statique et radio sur wlan0 ----------------------------------
echo "[4/8] Adresse ${IP_PI_WIFI} et bridage radio sur wlan0"
cat > /etc/systemd/system/ilot-ap-ip.service <<EOF
[Unit]
Description=Adresse statique et reglages radio du point d'acces d'ilot
Before=hostapd.service dnsmasq.service
After=network-pre.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/sbin/ip link set wlan0 up
ExecStart=/bin/sh -c '/sbin/iw dev wlan0 set power_save off || true'
ExecStart=/sbin/ip addr flush dev wlan0
ExecStart=/sbin/ip addr add ${IP_PI_WIFI}/24 dev wlan0
ExecStartPost=/bin/sh -c 'sleep 5; /usr/sbin/iw dev wlan0 set txpower fixed ${TXPOWER_MBM} || true'
ExecStop=/sbin/ip addr flush dev wlan0

[Install]
WantedBy=multi-user.target
EOF

# --- 5. hostapd ---------------------------------------------------------------
echo "[5/8] Point d'acces ${SSID} (canal ${CANAL})"
cat > /etc/hostapd/hostapd.conf <<EOF
interface=wlan0
driver=nl80211

ssid=${SSID}
country_code=FR
ieee80211d=1

hw_mode=g
channel=${CANAL}
ieee80211n=1
wmm_enabled=1

auth_algs=1
wpa=2
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
wpa_passphrase=${PSK}

# Pas de PMF : le module Inventek ISM43362 des cartes ST ne le supporte pas,
# et certaines revisions d'ESP32 s'en accommodent mal.
ieee80211w=0

macaddr_acl=0
ignore_broadcast_ssid=0

# Journalisation verbeuse : chaque association et chaque rejet apparaissent
# dans  journalctl -u hostapd
logger_syslog=-1
logger_syslog_level=2
EOF
chmod 600 /etc/hostapd/hostapd.conf
sed -i 's|^#\?DAEMON_CONF=.*|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd

# --- 6. DHCP ------------------------------------------------------------------
echo "[6/8] Serveur DHCP sur ${SUBNET}.0/24"
cat > /etc/dnsmasq.d/ilot.conf <<EOF
interface=wlan0
bind-interfaces
except-interface=eth0

dhcp-range=${SUBNET}.50,${SUBNET}.200,255.255.255.0,12h
dhcp-option=3,${IP_PI_WIFI}
dhcp-option=6,${IP_PI_WIFI}

# Nom local du broker : les devices peuvent viser broker.ilot plutot qu'une IP.
address=/broker.ilot/${IP_PI_WIFI}

# Les baux sont dans /var/lib/misc/dnsmasq.leases : premiere chose a regarder
# quand un device ne repond plus.
log-dhcp
EOF

# --- 7. Broker MQTT et serveur de firmware -----------------------------------
echo "[7/8] Broker MQTT (bridge vers ${IP_LAPTOP}) et serveur de firmware"

cat > /etc/mosquitto/conf.d/ilot.conf <<EOF
# ---------------------------------------------------------------------------
# Broker de peripherie — ilot ${ILOT}
# ---------------------------------------------------------------------------
listener 1883 0.0.0.0

# TP2 remplacera ceci par une authentification par certificat client.
allow_anonymous true

# NE PAS redeclarer persistence, persistence_location ni log_dest : le
# /etc/mosquitto/mosquitto.conf de Debian les definit deja avant d'inclure
# conf.d/, et mosquitto 2.x refuse de demarrer sur un doublon.

log_type all
connection_messages true

# --- Bridge vers le broker central du laptop -------------------------------
connection ilot${ILOT}-central
address ${IP_LAPTOP}:1883
remote_clientid ilot${ILOT}
cleansession false
start_type automatic
restart_timeout 10
notifications true
notification_topic st/bridge/ilot${ILOT}

# Convention de topics de l'ilot :
#   tel/<device>/<metrique>   telemetrie          (montant)
#   evt/<device>/<type>       evenements          (montant)
#   st/<device>               etat + LWT retenu   (montant)
#   cmd/<device>/<action>     commandes           (descendant)
topic tel/# out 0 "" ilot${ILOT}/
topic evt/# out 0 "" ilot${ILOT}/
topic st/#  out 0 "" ilot${ILOT}/
topic cmd/# in  0 "" ilot${ILOT}/
EOF

# Valide avant de demarrer : mosquitto ne dit rien d'exploitable via
# systemctl, alors qu'en avant-plan il donne le fichier et la ligne fautive.
if timeout 3 mosquitto -c /etc/mosquitto/mosquitto.conf -v 2>&1 | grep -q "Error"; then
    echo >&2
    echo "ERREUR : configuration mosquitto invalide." >&2
    timeout 3 mosquitto -c /etc/mosquitto/mosquitto.conf -v 2>&1 | grep -i error >&2
    exit 1
fi
systemctl restart mosquitto
systemctl enable mosquitto >/dev/null

mkdir -p /srv/firmware
chown -R "${SUDO_USER:-pi}":"${SUDO_USER:-pi}" /srv/firmware

cat > /etc/nginx/sites-available/firmware <<'EOF'
server {
    listen 8080 default_server;
    root /srv/firmware;
    autoindex on;
    # Coupures volontaires du TP OTA : pas de cache, pas de compression.
    add_header Cache-Control "no-store";
    gzip off;
    location / { try_files $uri $uri/ =404; }
}
EOF
ln -sf /etc/nginx/sites-available/firmware /etc/nginx/sites-enabled/firmware
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx

# --- Demarrage du point d'acces ----------------------------------------------
systemctl daemon-reload
systemctl enable --now ilot-ap-ip.service >/dev/null
systemctl enable hostapd >/dev/null
systemctl restart hostapd
systemctl enable dnsmasq >/dev/null
systemctl restart dnsmasq
sleep 3

if ! systemctl is-active --quiet hostapd; then
    echo >&2
    echo "ERREUR : hostapd n'a pas demarre." >&2
    echo "Diagnostic :  sudo hostapd -dd /etc/hostapd/hostapd.conf" >&2
    exit 1
fi

# --- 8. Lien Ethernet vers le laptop -----------------------------------------
# EN DERNIER : cette etape coupe la session SSH et l'acces Internet.
if [[ "${GARDER_RESEAU}" == "--garder-reseau" ]]; then
    echo "[8/8] eth0 laisse en DHCP (--garder-reseau)"
    echo
    echo " Pour basculer plus tard :"
    echo "   sudo nmcli connection add type ethernet ifname eth0 con-name lien-laptop \\"
    echo "        ipv4.method manual ipv4.addresses ${IP_PI_ETH}/24 ipv6.method disabled"
    echo "   sudo nmcli connection up lien-laptop"
else
    echo "[8/8] Lien Ethernet statique vers le laptop (${IP_PI_ETH})"
    echo
    echo "  >>> La session SSH va se couper. C'est normal. <<<"
    echo
    sleep 3
    nmcli connection delete "lien-laptop" 2>/dev/null || true
    nmcli connection add \
        type ethernet \
        ifname eth0 \
        con-name "lien-laptop" \
        autoconnect yes \
        ipv4.method manual \
        ipv4.addresses "${IP_PI_ETH}/24" \
        ipv6.method disabled
    nmcli connection modify "lien-laptop" connection.autoconnect-priority 100
    for c in "Wired connection 1" "Connexion filaire 1" "netplan-eth0"; do
        nmcli connection modify "$c" connection.autoconnect no 2>/dev/null || true
    done
    nmcli connection up "lien-laptop" || true
fi

echo
echo "=============================================="
echo " Ilot ${ILOT} pret."
echo
echo "   Devices  ->  SSID ${SSID} / cle ${PSK}"
echo "   Broker   ->  ${IP_PI_WIFI}:1883   (ou broker.ilot:1883)"
echo "   Firmware ->  http://${IP_PI_WIFI}:8080/"
echo
echo " Cote laptop : IP fixe ${IP_LAPTOP}/24, sans passerelle, profil PRIVE,"
echo " puis  docker compose up -d"
echo
echo " Validation :  ./check-ilot.sh ${ILOT}"
echo " Associations :  sudo journalctl -f -u hostapd -u dnsmasq"
echo "=============================================="
