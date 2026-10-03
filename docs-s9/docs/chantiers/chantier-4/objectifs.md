---
id: objectifs
title: Objectifs et livrables
sidebar_position: 1
---

# Chantier 4 — Mettre à jour une flotte

**Durée : 3 heures.** À l'issue, vous savez déployer une mise à jour à
distance, et surtout : vous savez ce qui se passe quand elle échoue.

## La vraie question

Déployer une mise à jour qui fonctionne est facile. Le métier commence quand
elle ne fonctionne pas.

Un device en production n'est pas sur votre bureau. Il est au plafond d'un
entrepôt, dans un compteur scellé, sur un mât à dix mètres. **Si une mise à
jour le rend muet, personne n'ira le rechercher.** Tout l'enjeu est là : une
mise à jour ratée doit laisser le device dans un état où il reste joignable.

C'est ce que garantit le schéma A/B, et c'est ce que vous allez démontrer —
en le cassant délibérément.

## Compétences visées

- Comprendre une table de partitions A/B et le rôle de `otadata`
- Déployer une mise à jour par voie radio sur un device distant
- Distinguer les signatures d'échec d'une campagne de mise à jour
- Mettre en œuvre et déclencher un retour arrière automatique
- Formuler un critère de validation d'image, et en mesurer les effets de bord

## Livrables

| Livrable | Forme | Quand |
|---|---|---|
| Journal d'une mise à jour nominale | capture annotée | en séance |
| Trois interruptions documentées | tableau | en séance |
| Retour arrière démontré | captures avant/après | en séance |
| Note sur le critère de validation | 10 lignes | fin de séance |

## Déroulé

1. [Comprendre le mécanisme](./mecanisme) — 30 min, sans manipulation
2. [Déployer une mise à jour](./nominal) — 45 min
3. [Casser le téléchargement](./interrompre) — 40 min
4. [Casser l'image](./rollback) — 45 min
5. [Interroger le critère](./critere) — 20 min

:::info[Prérequis]
Votre device doit être en service et publier sa télémétrie — c'est l'acquis du
[chantier 1](../chantier-1/objectifs). La passerelle doit servir son dépôt de
binaires sur le port 8080, vérifié au [chantier 0](../chantier-0/validation).
:::
