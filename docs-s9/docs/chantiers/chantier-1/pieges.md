---
id: pieges
title: Pièges connus
sidebar_position: 7
---

# Pièges connus

Problèmes rencontrés sur cette plateforme. Cherchez votre message d'erreur
exact avec la recherche du site avant d'appeler.

## `idf.py` n'est pas reconnu

L'environnement n'est actif que dans un terminal ESP-IDF. Un PowerShell
ordinaire ne connaît pas la commande.

Si le raccourci **ESP-IDF 5.5 PowerShell** n'existe pas dans le menu Démarrer,
l'installation s'est mal terminée. Activez l'environnement à la main :

```powershell
cd C:\Espressif\frameworks\esp-idf-v5.5.5
.\export.ps1
```

N'utilisez pas `Initialize-Idf.ps1` à la racine : il cherche ESP-IDF
relativement au répertoire courant et échoue si vous n'êtes pas au bon endroit.

Si PowerShell refuse d'exécuter le script :

```powershell
Set-ExecutionPolicy -Scope Process Bypass
```

Cette portée ne vaut que pour la fenêtre en cours.

## `ESP-IDF Python virtual environment … not found`

L'installeur s'est terminé sans construire l'environnement Python. C'est le
symptôme réel derrière les « erreurs de pilotes » que vous avez peut-être vues
passer. Réparez sans tout réinstaller :

```powershell
$env:IDF_TOOLS_PATH = "C:\Espressif"
cd C:\Espressif\frameworks\esp-idf-v5.5.5
.\install.ps1 esp32c6
.\export.ps1
```

**La première ligne est indispensable.** Sans elle, `install.ps1` installe dans
votre profil utilisateur, ignore les 1,6 Go déjà présents, et retélécharge
tout.

## La carte n'apparaît pas comme port COM

Trois causes, par ordre de fréquence.

**Le câble.** Beaucoup de câbles USB-C ne transportent que l'alimentation.
Essayez-en un autre avant toute chose.

**Le mauvais port.** La carte en a deux. Utilisez celui marqué `USB`, pas
`UART`.

**Le port occupé.** Un moniteur déjà ouvert dans une autre fenêtre garde le
port. Fermez-le avec `Ctrl` + crochet fermant.

## Erreurs de compilation incompréhensibles

Chemin trop long, avec des accents ou des espaces, ou dossier synchronisé par
OneDrive. Déplacez le projet dans `C:\esp\ilot-device` et recompilez après
`idf.py fullclean`.

## Le device ne s'associe pas au Wi-Fi

Le code de raison dans le journal désigne la cause :

| Code | Signification | Que vérifier |
|---|---|---|
| 15 | échec du handshake WPA | la clé |
| 201 | point d'accès introuvable | le SSID, la portée |
| 2 | authentification expirée | aléa radio, se rétablit seul |
| 8 | départ volontaire | normal avant un redémarrage |

Un code 2 isolé suivi d'une reconnexion n'est pas un incident.

## `couldn't get hostname for broker.ilot`

Le device a une adresse IP mais ne résout pas le nom du broker. Le problème
est la **résolution de nom**, pas le réseau — distinction importante, car le
journal Wi-Fi affiche « connecté » et donne l'illusion que tout va bien.

Vérifiez depuis la passerelle que dnsmasq déclare bien ce nom :

```bash
grep broker.ilot /etc/dnsmasq.d/ilot.conf
```

## `Checksum mismatch between flashed and built applications`

Avertissement du moniteur, pas une erreur : le binaire présent dans `build` ne
correspond pas à ce qui tourne sur la carte. Normal si vous avez recompilé sans
reflasher. C'est même un indicateur utile — il vous dit que ce que vous
observez n'est pas ce que vous venez de compiler.

## Le moniteur décroche au redémarrage

```text
--- ERROR: ClearCommError failed
--- Waiting for the device to reconnect.
```

Le port USB natif se réénumère à chaque redémarrage de la carte, et Windows
met un instant à reprendre la main. Le moniteur se reconnecte seul. Si ce n'est
pas le cas, `Ctrl` + crochet fermant puis `idf.py monitor`.
