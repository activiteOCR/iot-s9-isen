---
id: avant-la-seance
title: Avant la séance
sidebar_position: 2
---

# À faire chez vous

Quatre points, une trentaine de minutes, **avec une connexion Internet
correcte**. La salle est desservie par un accès WiFi partagé entre cinq
groupes : ce qui se télécharge tranquillement chez vous devient une demi-séance
perdue en TP.

## 1. Vérifier vos droits administrateur

Vous allez configurer une adresse IP fixe, changer un profil réseau et ouvrir
un port dans le pare-feu. Les trois exigent l'administrateur.

**Windows** — ouvrez le menu Démarrer, tapez `PowerShell`, faites un clic droit
puis « Exécuter en tant qu'administrateur ». Si Windows refuse ou réclame un
mot de passe que vous n'avez pas, signalez-le maintenant.

**macOS / Linux** — vérifiez que `sudo` fonctionne :

```bash
sudo -v
```

## 2. Installer Docker

Docker Desktop sur Windows et macOS, Docker Engine sur Linux. Puis contrôlez
que le moteur répond :

```bash
docker version
```

Sur Windows, la ligne `OS/Arch` du serveur doit indiquer `linux/amd64`. Si
elle affiche `windows/amd64`, basculez en conteneurs Linux par le menu
contextuel de l'icône Docker.

## 3. Récupérer le dépôt et les images

```bash
git clone https://github.com/activiteOCR/iot-s9-isen.git
cd iot-s9-isen/ilot-s9/ilot-s9-laptop
docker compose pull
```

C'est le point le plus important de cette page. Environ un gigaoctet à
télécharger, quelques minutes chez vous, beaucoup plus en salle.

:::tip[Vérification]

```bash
docker images
```

Quatre images doivent apparaître : `eclipse-mosquitto`, `influxdb`,
`telegraf` et `grafana/grafana`.
:::

## 4. Préparer une roue de secours

Si un camarade n'a pas pu faire le téléchargement, exportez les images sur une
clé USB pour lui :

```bash
docker save eclipse-mosquitto:2.0 influxdb:2.7 telegraf:1.30 \
    grafana/grafana:11.1.0 -o images-ilot.tar
```

Et de son côté, en séance :

```bash
docker load -i images-ilot.tar
```

## Matériel à apporter

Un câble Ethernet RJ45 par groupe, et un adaptateur USB-Ethernet si votre
laptop n'a pas de port. Vérifiez ce point : beaucoup d'ultraportables récents
n'en ont plus.
