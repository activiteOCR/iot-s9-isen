---
id: flasher
title: 1. Compiler et flasher
sidebar_position: 3
---

# Mettre le firmware sur la carte

**40 minutes.** Quatre devices à mettre en service, un par membre du groupe.

## Brancher la carte

La DevKitC-1 a **deux ports USB-C**. Celui marqué `USB` est l'interface
USB-Serial/JTAG native du C6 ; celui marqué `UART` passe par un pont
USB-série qui exige un pilote.

**Utilisez le port `USB`.** Aucun pilote à installer, et la carte bascule
seule en mode téléchargement : vous n'aurez jamais à maintenir le bouton BOOT.

```powershell
[System.IO.Ports.SerialPort]::GetPortNames()
```

Un nouveau port COM doit apparaître. Dans le gestionnaire de périphériques, il
se présente comme « USB JTAG/serial debug unit ».

## Configurer votre device

```powershell
cd C:\esp\ilot-device
idf.py menuconfig
```

Descendez jusqu'à **Configuration de l'ilot** et renseignez :

| Paramètre | Valeur |
|---|---|
| Numero d'ilot | le vôtre |
| SSID du point d'acces | `ilot-N` |
| Cle WPA2 | fournie par l'enseignant |
| Identifiant du device | `dev01` à `dev04` — **un par personne** |
| URI du broker MQTT | `mqtt://broker.ilot:1883` |
| Periode de telemetrie | `5` |

`S` pour sauvegarder, `Q` pour quitter.

:::note[Pourquoi un nom et pas une adresse IP]
L'URI vise `broker.ilot`, pas `192.168.N0.1`. Ce nom est résolu par le serveur
DNS de **votre** passerelle. Conséquence : le même binaire fonctionne sur les
cinq îlots sans recompilation. Retenez le principe — un firmware ne doit jamais
coder en dur ce qui dépend du site où il sera déployé.
:::

Si vous laissez l'identifiant vide, il est dérivé de l'adresse MAC sous la
forme `dev-a1b2c3`. Pratique pour flasher vingt cartes avec un seul binaire,
mais moins lisible pour ce TP : nommez-les explicitement.

## Compiler et flasher

```powershell
idf.py build
idf.py flash monitor
```

Le moniteur reste ouvert et affiche le journal de la carte. Pour en sortir :
`Ctrl` puis crochet fermant.

:::danger[`flash monitor` une seule fois]
Après ce premier flash, utilisez **`idf.py monitor`** seul pour réouvrir le
journal. `idf.py flash monitor` réécrit par USB et réinitialise l'état des
mises à jour — vous détruiriez le travail des chantiers suivants sans vous en
apercevoir.
:::

:::tip[Vérification]
Le journal se termine par une adresse obtenue et une connexion au broker :

```text
I (6181) wifi: IP obtenue : 192.168.30.84
I (6211) mqtt: connecte au broker
I (6211) mqtt: abonne a cmd/dev01/#
```

Si l'association échoue, le code de raison dans le journal désigne la cause —
c'est l'objet de l'étape suivante.
:::

Répétez pour les quatre cartes du groupe, en changeant l'identifiant à chaque
fois.
