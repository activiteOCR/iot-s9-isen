---
id: pieges
title: Pièges connus
sidebar_position: 7
---

# Pièges connus

## La version ne change pas

`set(PROJECT_VER ...)` doit être **avant** `project()` dans `CMakeLists.txt`.
Après, la ligne est ignorée sans avertissement.

Vérifiez ce que contient réellement le binaire déposé sur la passerelle :

```bash
dd if=/srv/firmware/vX.Y.Z.bin bs=1 skip=48 count=32 2>/dev/null | tr -d '\0'; echo
```

## `esp_https_ota_begin : ESP_ERR_HTTP_CONNECT`

Le serveur de binaires ne répond pas. Sur la passerelle :

```bash
systemctl is-active nginx
curl -I http://192.168.N0.1:8080/
```

Si vous avez arrêté nginx avec `kill -s KILL` lors d'un essai d'interruption,
systemd le considère en échec et refuse de le redémarrer tel quel :

```bash
sudo systemctl reset-failed nginx && sudo systemctl start nginx
```

## Le fichier n'est pas trouvé (404)

Le nom publié dans la commande MQTT doit correspondre exactement au fichier
déposé. Vérifiez :

```bash
ls -l /srv/firmware/
```

## La mise à jour se déclenche mais rien ne bouge

Votre device est-il abonné ? Il n'écoute que `cmd/<son-id>/#`. Publier sur
`cmd/dev01/ota` ne touchera jamais `dev02`.

Vérifiez aussi que vous publiez sur le **broker de la passerelle**, pas sur le
broker central de votre laptop. Le bridge ne redescend les commandes qu'avec le
préfixe de l'îlot.

## J'ai reflashé par USB et l'état OTA a disparu

`idf.py flash` réinitialise `otadata` : le device repart sur `ota_0` avec une
image d'emblée considérée valide, et le retour arrière n'est plus armé.

C'est récupérable — refaites simplement une mise à jour par voie radio — mais
ça invalide la manipulation en cours. **Après le premier flash du chantier 1,
utilisez `idf.py monitor` seul.**

## Le moniteur décroche au redémarrage

```text
--- ERROR: ClearCommError failed
--- Waiting for the device to reconnect.
```

Le port USB natif se réénumère à chaque redémarrage. Le moniteur se reconnecte
seul la plupart du temps ; sinon, `Ctrl` + crochet fermant puis
`idf.py monitor`.

Conséquence pratique : vous perdrez souvent les premières lignes du chargeur
d'amorçage après une mise à jour. Les informations importantes — emplacement,
version, état — sont journalisées plus tard et restent visibles.

## Le device ne confirme jamais son image

Regardez pourquoi avant de conclure à un bug. Le critère exige un
fonctionnement nominal **continu** : une coupure Wi-Fi intermittente remet le
compteur à zéro à chaque fois, et l'image n'est jamais confirmée alors qu'elle
fonctionne par intermittence.

C'est un comportement voulu, et une bonne question : était-ce le bon choix ?
