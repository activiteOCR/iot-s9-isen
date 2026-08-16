#!/usr/bin/env bash
#
# check-ilot.sh — Validation du chantier 0 sur un ilot
#
#   Usage :  ./check-ilot.sh <numero_ilot>
#
# A lancer sur le Pi. Repond vert ou rouge sur chaque brique, dans l'ordre
# ou elles se cassent en pratique.
#
set -uo pipefail

ILOT="${1:-}"
if ! [[ "$ILOT" =~ ^[1-5]$ ]]; then
    echo "Usage : $0 <numero_ilot>   (1 a 5)" >&2
    exit 1
fi

SSID="ilot-${ILOT}"
IP_PI_WIFI="192.168.$((10 * ILOT)).1"
IP_LAPTOP="10.10.${ILOT}.2"
OK=0
KO=0

vert()  { printf '  \033[32m/\033[0m %s\n' "$1"; OK=$((OK + 1)); }
rouge() { printf '  \033[31mX\033[0m %s\n' "$1"; KO=$((KO + 1)); }
info()  { printf '    %s\n' "$1"; }

echo
echo "=== Ilot ${ILOT} ==============================="
echo

# --- Radio --------------------------------------------------------------------
echo "Radio"
if systemctl is-active --quiet hostapd; then
    vert "hostapd actif"
else
    rouge "hostapd arrete"
    info "sudo hostapd -dd /etc/hostapd/hostapd.conf   (diagnostic en avant-plan)"
fi

if systemctl is-active --quiet dnsmasq; then
    vert "dnsmasq actif (serveur DHCP)"
else
    rouge "dnsmasq arrete — les devices ne recevront aucune adresse"
    info "journalctl -u dnsmasq -n 30"
fi

if iw dev wlan0 info 2>/dev/null | grep -q "type AP"; then
    CANAL=$(iw dev wlan0 info | awk '/channel/ {print $2}')
    vert "wlan0 en mode point d'acces, canal ${CANAL}"
else
    rouge "wlan0 n'est pas en mode AP"
    info "Cause frequente : code pays absent -> raspi-config nonint do_wifi_country FR"
    info "Ou NetworkManager qui reprend l'interface : verifier"
    info "/etc/NetworkManager/conf.d/99-ilot-unmanaged.conf"
fi

if ip -brief addr show wlan0 2>/dev/null | grep -q "${IP_PI_WIFI}"; then
    vert "wlan0 porte ${IP_PI_WIFI}"
else
    rouge "wlan0 n'a pas l'adresse ${IP_PI_WIFI}"
    info "systemctl restart ilot-ap-ip.service"
fi

TX=$(iw dev wlan0 info 2>/dev/null | awk '/txpower/ {print $2}')
DRIVER=$(basename "$(readlink -f /sys/class/net/wlan0/device/driver 2>/dev/null)" 2>/dev/null)
if [[ -n "${TX}" ]]; then
    if (( $(echo "${TX} <= 12" | bc -l 2>/dev/null || echo 0) )); then
        vert "puissance d'emission ${TX} dBm (bridee)"
    elif [[ "${DRIVER}" == brcmfmac* ]]; then
        info "puissance d'emission ${TX} dBm — non reglable sur WiFi integre"
        info "Broadcom. Non bloquant : la separation repose sur les canaux."
    else
        rouge "puissance d'emission ${TX} dBm — trop forte pour 5 ilots"
        info "systemctl restart wifi-txpower.service"
    fi
fi

# --- Alimentation -------------------------------------------------------------
# Sur Pi 3B, la sous-alimentation ne plante pas franchement : elle fait tomber
# le point d'acces de facon intermittente. C'est LA panne a exclure en premier.
if command -v vcgencmd >/dev/null 2>&1; then
    THR=$(vcgencmd get_throttled 2>/dev/null | cut -d= -f2)
    if [[ "${THR}" == "0x0" ]]; then
        vert "alimentation saine (get_throttled = 0x0)"
    else
        rouge "sous-tension detectee (get_throttled = ${THR})"
        info "Bloc 5V/2.5A et cable micro-USB court et epais obligatoires"
    fi
fi

# --- Stations associees -------------------------------------------------------
NB=$(iw dev wlan0 station dump 2>/dev/null | grep -c "^Station" || echo 0)
echo
echo "Devices"
if (( NB > 0 )); then
    vert "${NB} device(s) associe(s)"
    iw dev wlan0 station dump | awk '/^Station/ {mac=$2} /signal:/ {print "      " mac "   " $2 " dBm"}'
else
    rouge "aucun device associe"
    info "Allumer au moins un ESP32 configure sur ${SSID}"
fi

BAUX=$(grep -c . /var/lib/misc/dnsmasq.leases 2>/dev/null || echo 0)
if (( BAUX > 0 )); then
    vert "${BAUX} bail(s) DHCP distribue(s)"
else
    info "aucun bail DHCP visible (normal si les devices sont en IP statique)"
fi

# --- Broker de peripherie -----------------------------------------------------
echo
echo "Broker de peripherie"
if systemctl is-active --quiet mosquitto; then
    vert "mosquitto actif"
else
    rouge "mosquitto arrete"
    info "journalctl -u mosquitto -n 30"
fi

if timeout 5 mosquitto_pub -h "${IP_PI_WIFI}" -t "evt/check/ping" -m "$(date +%s)" 2>/dev/null; then
    vert "publication locale sur ${IP_PI_WIFI}:1883"
else
    rouge "publication locale impossible"
fi

# --- Bridge vers le laptop ----------------------------------------------------
echo
echo "Bridge vers le laptop"
if ping -c 2 -W 2 "${IP_LAPTOP}" >/dev/null 2>&1; then
    vert "laptop joignable en ${IP_LAPTOP}"
else
    rouge "laptop injoignable en ${IP_LAPTOP}"
    info "Verifier l'IP statique cote laptop et le pare-feu Windows"
fi

if timeout 5 mosquitto_sub -h "${IP_LAPTOP}" -t '$SYS/broker/version' -C 1 >/dev/null 2>&1; then
    vert "broker central du laptop accessible"
else
    rouge "broker central injoignable sur ${IP_LAPTOP}:1883"
    info "Cote laptop : docker compose ps"
    info "Sous WSL : le port n'est PAS expose au LAN sans portproxy — voir README"
fi

if grep -q "Bridge.*ilot${ILOT}-central.*sending CONNECT" /var/log/mosquitto/mosquitto.log 2>/dev/null \
   || grep -q "Connecting bridge" /var/log/mosquitto/mosquitto.log 2>/dev/null; then
    vert "bridge MQTT tente/etabli (voir le log pour l'etat courant)"
else
    rouge "aucune trace de bridge dans le log"
fi

# --- Serveur de firmware ------------------------------------------------------
echo
echo "Serveur de firmware"
if curl -sf -o /dev/null "http://${IP_PI_WIFI}:8080/"; then
    vert "http://${IP_PI_WIFI}:8080/ repond"
    NBFW=$(ls -1 /srv/firmware/*.bin 2>/dev/null | wc -l)
    if (( NBFW > 0 )); then
        vert "${NBFW} binaire(s) publie(s)"
    else
        info "aucun .bin dans /srv/firmware (normal avant le TP OTA)"
    fi
else
    rouge "nginx ne repond pas sur le port 8080"
fi

# --- Resultat -----------------------------------------------------------------
echo
echo "=============================================="
printf ' %d verifications OK, %d en echec\n' "${OK}" "${KO}"
echo "=============================================="
echo
exit $(( KO > 0 ))
