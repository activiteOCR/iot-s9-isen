---
id: avant-la-seance
title: Avant la séance
sidebar_position: 2
---

# À faire chez vous

Comptez une heure, avec une connexion correcte. **Ce n'est pas optionnel** :
l'installation pèse 1,6 Go et la salle partage un routeur 4G entre cinq
groupes.

## 1. Télécharger l'installeur ESP-IDF

Rendez-vous sur **https://dl.espressif.com/dl/esp-idf/** — pas sur la racine
du serveur, qui n'est qu'un index vide.

Prenez **ESP-IDF v5.5.5 – Offline Installer**, 1,62 Go. Pas l'installeur en
ligne : il télécharge la même quantité pendant l'installation, avec en prime
le risque qu'une coupure réseau laisse l'installation à moitié faite.

## 2. Installer

Gardez le chemin par défaut `C:\Espressif`. Un dossier contenant des espaces
ou des accents fait échouer la chaîne de compilation.

À l'écran de sélection des composants, choisissez **Custom installation** et
ne cochez que :

- Frameworks → ESP-IDF v5.5.5
- Development integrations → PowerShell et Command Prompt
- Chip Targets → **ESP32-C6 uniquement**

Décochez toutes les autres cibles et les pilotes USB-série. Vous n'avez qu'une
carte ESP32-C6, qui utilise son interface USB native : aucun pilote n'est
nécessaire. Vous passez ainsi d'environ 7,8 Go à 5 Go, et l'installation est
d'autant plus rapide.

## 3. Vérifier que l'installation a réussi

C'est l'étape que tout le monde saute, et celle qui fait perdre une heure en
séance. **L'installeur peut se terminer avec des erreurs tout en paraissant
avoir fonctionné.**

Ouvrez le raccourci **ESP-IDF 5.5 PowerShell** depuis le menu Démarrer, puis :

```powershell
idf.py --version
```

:::tip[Vérification]
Une version s'affiche (`v1.0.3` ou similaire — c'est la version de l'outil
`idf.py`, pas celle du framework). Si la commande n'est pas reconnue, ou si le
raccourci n'existe pas, voir [Pièges connus](./pieges#idfpy-nest-pas-reconnu).
:::

## 4. Récupérer le firmware

Le projet se trouve dans le dépôt, dossier `firmware/ilot-device`. Copiez-le
dans un chemin court :

```
C:\esp\ilot-device
```

**Évitez Documents et Bureau s'ils sont synchronisés par OneDrive** : la
synchronisation verrouille des fichiers pendant la compilation et produit des
erreurs incompréhensibles.

## 5. Compiler une première fois

Toujours dans le terminal ESP-IDF :

```powershell
cd C:\esp\ilot-device
idf.py set-target esp32c6
idf.py build
```

La première compilation prend plusieurs minutes : elle construit tout le
framework. Les suivantes sont bien plus rapides, et **c'est tout le bénéfice
de la faire chez vous**.

:::tip[Vérification]
La compilation se termine par la taille du binaire et un rappel de la commande
de flash. Si vous arrivez jusque-là, vous êtes prêt.
:::

## Matériel à apporter

Votre carte ESP32-C6-DevKitC-1 et un **câble USB-C de données**. Attention :
beaucoup de câbles fournis avec les chargeurs ne transportent que
l'alimentation. Si votre carte n'apparaît pas dans le gestionnaire de
périphériques, c'est souvent le câble.
