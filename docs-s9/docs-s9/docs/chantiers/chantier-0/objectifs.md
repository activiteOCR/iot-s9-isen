---
id: objectifs
title: Objectifs et livrables
sidebar_position: 1
---

# Chantier 0 — Prise en main de l'îlot

**Durée : 1 heure.** À l'issue, votre îlot est opérationnel de bout en bout et
vous savez décrire ce qui tourne dessus.

## Ce que vous allez faire

Relier votre laptop à la passerelle, monter la chaîne de supervision, puis
**enquêter** sur la passerelle pour comprendre ce qu'elle fait — sans jamais
la modifier.

Cette dernière partie est le cœur du chantier. On vous livre une machine
configurée par quelqu'un d'autre, sans documentation. C'est la situation
normale en exploitation, et savoir la cartographier est une compétence en soi.

## Compétences visées

- Établir une liaison IP point à point sans serveur DHCP
- Déployer une pile de services conteneurisée
- Cartographier un système inconnu à partir de ses services, ports et journaux
- Lire un bridge MQTT et comprendre ce qu'il transforme

## Livrables

| Livrable | Forme | Quand |
|---|---|---|
| Schéma d'architecture de votre îlot | 1 page, à la main ou en Mermaid | fin de séance |
| Sortie du vérificateur, horodatée | capture ou copie | fin de séance |
| Réponse à la question du bridge | 5 lignes | fin de séance |

Le schéma doit faire apparaître les interfaces réseau, les adresses, les
services et les ports. Pas les logos.

## Déroulé

1. [Avant la séance](./avant-la-seance) — à faire chez vous
2. [Établir la liaison](./liaison) — 15 min
3. [Monter la supervision](./supervision) — 15 min
4. [Cartographier la passerelle](./passerelle) — 20 min
5. [Valider l'îlot](./validation) — 10 min

En cas de blocage, la page [Pièges connus](./pieges) recense les problèmes
déjà rencontrés et leur résolution. Consultez-la avant d'appeler.

:::warning[Un seul laptop suffit]
Si l'un de vos laptops refuse de coopérer — droits administrateur manquants,
Docker qui ne démarre pas — travaillez sur celui d'un camarade et notez le
problème. Vous n'êtes pas bloqués pour autant, et la panne rencontrée est
elle-même du matériau pour le module 5.
:::
