# Brique d'îlot — S9 IoT Systems Deployment & Operations

Configuration de référence d'un îlot. À monter une fois, valider, puis cloner
sur les quatre autres.

```
ESP32 ×4 ──WiFi "ilot-N"──► Raspberry Pi ──Ethernet direct──► Laptop
                            192.168.N0.1      10.10.N.1/.2      Docker
                            hostapd + dnsmasq                   broker central
                            Mosquitto edge                      InfluxDB
                            nginx :8080                         Grafana
```

## Plan d'adressage

| Îlot | SSID | Canal | Réseau WiFi | Pi (eth) | Laptop |
|---|---|---|---|---|---|
| 1 | ilot-1 | 1 | 192.168.10.0/24 | 10.10.1.1 | 10.10.1.2 |
| 2 | ilot-2 | 6 | 192.168.20.0/24 | 10.10.2.1 | 10.10.2.2 |
| 3 | ilot-3 | 11 | 192.168.30.0/24 | 10.10.3.1 | 10.10.3.2 |
| 4 | ilot-4 | 1 | 192.168.40.0/24 | 10.10.4.1 | 10.10.4.2 |
| 5 | ilot-5 | 6 | 192.168.50.0/24 | 10.10.5.1 | 10.10.5.2 |

Les îlots 4 et 5 réutilisent les canaux 1 et 6 : **placez-les physiquement à
l'opposé** des îlots 1 et 2 dans la salle.

## Convention de topics

| Topic | Sens | Usage |
|---|---|---|
| `tel/<device>/<métrique>` | montant | télémétrie, charge utile JSON plate |
| `evt/<device>/<type>` | montant | événements : boot, ota, erreur |
| `st/<device>` | montant, retenu | état + Last Will |
| `cmd/<device>/<action>` | descendant | commandes, campagnes OTA |

Le bridge préfixe tout ce qui remonte par `ilotN/`. Sur le broker central,
`ilot3/tel/dev01/temperature`.

Cette convention n'est pas cosmétique : le préfixe par îlot est ce qui permet
de fédérer les cinq stacks au module 4 sans collision, et la séparation
`tel` / `evt` / `st` est ce qui rend les alertes de présence écrivables.

## Montage

### 1. Raspberry Pi

Image Raspberry Pi OS Bookworm ou Trixie, 64 bits, SSH activé.

**Le Pi doit avoir Internet au lancement** — branchez-le sur la box, pas sur
le laptop. Le script installe des paquets, et la dernière étape supprime
justement cet accès en basculant `eth0` en statique.

```bash
sudo ./pi/setup-ilot.sh 3                    # configuration definitive
sudo ./pi/setup-ilot.sh 3 --garder-reseau    # sans basculer eth0 (preparation)
```

Le script installe les paquets, configure le point d'accès hostapd, le serveur
DHCP, le broker de périphérie avec son bridge, le serveur de binaires, puis en
dernier le lien Ethernet — c'est à ce moment que la session SSH se coupe.

Suivre les associations en direct :

```bash
sudo journalctl -f -u hostapd -u dnsmasq
```

### 2. Laptop

Interface Ethernet en IP statique : `10.10.N.2`, masque `255.255.255.0`,
**sans passerelle**. Puis :

```bash
cd laptop
docker compose up -d
```

Grafana sur http://localhost:3000 (admin / iot-s9), source InfluxDB déjà
déclarée.

### 3. Validation

```bash
./pi/check-ilot.sh 3
```

## Pièges connus

### WSL — le point qui coûte une séance

Un service lancé dans WSL2 **n'est pas joignable depuis le réseau local**. WSL2
est derrière un NAT virtuel dont l'IP change à chaque redémarrage. Le Pi ne
verra jamais le broker.

Trois issues, par ordre de préférence :

1. **Docker Desktop** — c'est le choix retenu ici. Les ports publiés avec `-p`
   sont exposés sur l'hôte Windows, donc visibles du LAN. Rien à configurer.
2. **Mode réseau miroir** — dans `%UserProfile%\.wslconfig` :
   ```ini
   [wsl2]
   networkingMode=mirrored
   ```
   Nécessite Windows 11 et une version récente de WSL. À vérifier sur le parc
   réel avant de s'engager.
3. **Repli** — toute la stack sur le Pi, le laptop réduit à un navigateur.
   Préparez cette image de secours dès maintenant : vous ne voulez pas la
   construire en séance.

Dans tous les cas, autoriser le port 1883 en entrée dans le pare-feu Windows,
profil réseau **Privé**. Une carte Ethernet fraîchement configurée est souvent
classée en réseau Public, où tout entrant est bloqué par défaut.

### Le point d'accès diffuse mais aucun client ne s'associe

Symptôme : le SSID est visible, `iw dev wlan0 station dump` reste vide, aucune
tentative d'association n'apparaît dans les journaux. Signature dans `dmesg` :

```
ieee80211 phy0: brcmf_vif_set_mgmt_ie: vndr ie set error : -52
```

C'est la raison pour laquelle cette brique utilise **hostapd** et non le mode
AP de NetworkManager. Sur les puces Broadcom des Raspberry Pi, NM pilote le
point d'accès via `wpa_supplicant`, dont l'implémentation AP échoue à installer
les éléments d'information de gestion : la radio balise, mais aucun client ne
peut négocier son association. Constaté sur Pi 3B / Raspberry Pi OS Trixie.

Si le symptôme réapparaît, vérifier que NetworkManager ne s'est pas réapproprié
l'interface :

```bash
cat /etc/NetworkManager/conf.d/99-ilot-unmanaged.conf
nmcli device status          # wlan0 doit apparaitre "unmanaged"
```

### Code pays absent

Le noyau refuse le mode AP sans domaine réglementaire. hostapd ne démarre pas :

```bash
sudo raspi-config nonint do_wifi_country FR
sudo rfkill unblock wifi
iw reg get | head -3
```

### Cartes ST qui ne s'associent pas

Le module Inventek ISM43362 ne supporte ni WPA3 ni le Protected Management
Frames. Le script force `wifi-sec.pmf disable` et WPA2-CCMP pur. Ne le
rétablissez pas en « optional » en croyant renforcer la sécurité.

### Devices d'un îlot visibles chez le voisin

SSID identiques ou canaux qui se recouvrent. Vérifiez que chaque îlot a bien
son SSID, sa clé et son sous-réseau, et que les canaux sont 1, 6 ou 11
exclusivement — jamais de canal automatique.

### Raspberry Pi 3B — deux spécificités

**L'alimentation est le point critique.** Le 3B demande 5V / 2,5A en micro-USB.
Sous-alimenté, il ne s'arrête pas franchement : le point d'accès tombe par
intermittence, ce qui est le pire mode de panne possible en séance. Le câble
compte autant que le bloc — un micro-USB long et fin fait chuter la tension à
lui seul. Prends un câble court et épais, et vérifie :

```bash
vcgencmd get_throttled     # 0x0 = sain, toute autre valeur = sous-tension
```

Bit 0 à 1 signifie sous-tension en cours, bit 16 signifie qu'un épisode s'est
produit depuis le démarrage. La LED rouge PWR qui s'éteint ou clignote donne
la même information sans terminal.

**La puissance d'émission est réglable**, contrairement à ce qu'on lit
souvent sur les puces Broadcom : `iw dev wlan0 set txpower fixed 1000` applique
bien 10 dBm sur ce noyau. Le service `ilot-ap-ip` s'en charge. Vérification :

```bash
iw dev wlan0 info | grep txpower
```

Le Wi-Fi 2,4 GHz seul du 3B n'est pas une limitation : ESP32 et modules ST
sont mono-bande 2,4 GHz de toute façon.

### Puissance d'émission qui remonte toute seule

NetworkManager réinitialise la puissance à chaque activation de la connexion.
Le service `wifi-txpower.service` la réapplique 15 secondes après. S'il a
échoué :

```bash
sudo systemctl restart wifi-txpower.service
iw dev wlan0 info | grep txpower
```

## Avant la première séance

- [ ] Changer les clés WiFi, le token InfluxDB et le mot de passe Grafana
- [ ] Vérifier le firmware du module WiFi des cartes ST, et noter la version
- [ ] Cloner l'image SD du Pi validé sur les quatre autres
- [ ] Faire tourner `check-ilot.sh` sur les cinq îlots simultanément, tous
      les devices allumés — c'est le seul test qui révèle les collisions radio
- [ ] Mesurer le temps de téléchargement de quatre binaires en parallèle
      depuis `nginx`, pour calibrer le TP OTA
