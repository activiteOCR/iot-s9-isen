---
id: objectifs
title: Objectifs et livrables
sidebar_position: 1
---

# Chantier 1 — Mettre un device en service

**Durée : 2 heures.** À l'issue, vos quatre ESP32-C6 sont en service sur
l'îlot, publient leur télémétrie, et vous savez prouver qu'un device est tombé.

## Ce que vous allez faire

Compiler et flasher le firmware de référence, le voir rejoindre l'îlot que
vous avez cartographié au chantier précédent, puis **comprendre la convention
de topics** qui structure tout le reste du cours.

Le point d'arrivée n'est pas « ça marche ». C'est : vous savez répondre à la
question *ce device est-il vivant ?* autrement qu'en le regardant.

## Compétences visées

- Compiler et déployer un firmware sur une cible RISC-V
- Lire un journal de démarrage embarqué et y repérer ce qui compte
- Diagnostiquer un échec d'association Wi-Fi par son code de raison
- Concevoir une convention de topics MQTT exploitable à l'échelle d'une flotte
- Mettre en œuvre le Last Will et comprendre ce qu'il résout

## Livrables

| Livrable | Forme | Quand |
|---|---|---|
| Quatre devices visibles sur le broker | capture de `mosquitto_sub` | fin de séance |
| Tableau des codes de raison rencontrés | 5 lignes | fin de séance |
| Démonstration du Last Will | capture horodatée | fin de séance |

## Déroulé

1. [Avant la séance](./avant-la-seance) — **1,6 Go à télécharger chez vous**
2. [Compiler et flasher](./flasher) — 40 min
3. [Lire le démarrage](./demarrage) — 25 min
4. [Observer la flotte](./flotte) — 35 min
5. [Faire taire un device](./last-will) — 20 min

:::warning[Les prérequis ne sont pas optionnels]
L'environnement de compilation pèse 1,6 Go. La salle est desservie par un
routeur 4G partagé entre cinq groupes. Si vous arrivez sans l'avoir installé,
vous ne ferez pas le TP — et vous bloquerez les autres.
:::
