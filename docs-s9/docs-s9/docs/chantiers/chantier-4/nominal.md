---
id: nominal
title: 2. Déployer une mise à jour
sidebar_position: 3
---

# Le cas qui marche

**45 minutes.** Le plus simple des quatre scénarios — et le seul que la plupart
des tutoriels montrent.

## Produire une nouvelle version

Dans `CMakeLists.txt`, à la racine du projet :

```cmake
set(PROJECT_VER "1.1.0")
```

:::danger[Avant `project()`]
Cette ligne doit rester **au-dessus** de l'appel à `project()`. Placée après,
elle est ignorée sans le moindre avertissement, et vous chercherez longtemps
pourquoi la version ne change pas.
:::

Changez aussi quelque chose de visible dans le firmware — un message de
journal, la période de télémétrie — pour pouvoir constater l'effet autrement
que par le numéro.

```powershell
idf.py build
```

## Déposer le binaire

```powershell
scp build/ilot-device.bin isen-iot@10.10.N.1:/srv/firmware/v1.1.0.bin
```

:::note[Quelle adresse ?]
`10.10.N.1` depuis votre laptop, qui est sur le lien Ethernet.
`192.168.N0.1` depuis un device, qui est sur le Wi-Fi. Même machine, deux
interfaces — et chacune n'est joignable que depuis son propre réseau.
:::

Vérifiez sur la passerelle que le fichier est servi **et** qu'il contient bien
ce que vous croyez :

```bash
curl -I http://192.168.N0.1:8080/v1.1.0.bin
dd if=/srv/firmware/v1.1.0.bin bs=1 skip=48 count=32 2>/dev/null | tr -d '\0'; echo
```

La seconde commande lit la version dans les métadonnées de l'image, à un offset
fixe. Elle doit afficher `1.1.0`. Si elle affiche l'ancienne version, vous avez
transféré un binaire qui n'a pas été recompilé.

## Déclencher et observer

Gardez le moniteur ouvert :

```powershell
idf.py monitor
```

:::danger[Jamais `flash monitor` ici]
`idf.py flash monitor` réécrirait la carte par USB et réinitialiserait
`otadata`. Vous détruiriez l'état que vous cherchez à observer.
:::

Depuis la passerelle :

```bash
mosquitto_pub -h 192.168.N0.1 -t cmd/dev01/ota -m "v1.1.0.bin"
```

Notez que la charge utile est **un nom de fichier**, pas une URL. Le device
construit l'adresse complète lui-même. Pourquoi ce choix, à votre avis ?

## Ce que vous devez voir

```text
W (xxxxx) mqtt: commande OTA recue : http://broker.ilot:8080/v1.1.0.bin
I (xxxxx) esp_https_ota: Writing to <ota_1> partition at offset 0x320000
I (xxxxx) ota: 10% (108544/1082112 octets)
...
W (xxxxx) ota: image installee — redemarrage
```

Puis, après le redémarrage :

```text
I (547) boot: Loaded app from partition at offset 0x320000
I (577) app_init: App version:      1.1.0
I (2116) ota: demarrage sur ota_1, version 1.1.0, etat en_verification
```

:::tip[Vérification]
Trois choses ont changé par rapport au chantier 1 : l'emplacement de
démarrage, le numéro de version, et l'état de l'image — `en_verification` au
lieu de `valide`. Trente secondes plus tard, `image 1.1.0 confirmee valide`.
:::

## Mesurer

Relevez dans le journal la durée du téléchargement et calculez le débit réel.
Puis répondez :

**Combien de temps pour mettre à jour les quatre devices de votre îlot**, s'ils
téléchargent en même temps ? Et les cinq îlots, soit une vingtaine de devices ?

**Et si la flotte comptait 10 000 devices ?** Le téléchargement simultané
est-il encore envisageable ? Quelle stratégie proposeriez-vous à la place ?

Cette dernière question est le sujet du module sur le passage à l'échelle.
Formulez une hypothèse maintenant, vous la confronterez plus tard.

:::info[Objectif bonus]
Le device publie chaque étape sur `evt/dev01/ota`. Abonnez-vous-y depuis le
broker central du laptop et refaites une mise à jour. Vous venez de piloter une
campagne **sans câble série** — ce qui est la seule façon de procéder en
production.
:::
