---
id: critere
title: 5. Interroger le critère
sidebar_position: 6
---

# Qu'est-ce qu'une image « qui fonctionne » ?

**20 minutes, sans manipulation.** La question paraît triviale. Elle ne l'est
pas, et c'est le vrai sujet de ce chantier.

## Le problème

Le retour arrière repose entièrement sur une décision : *cette image
fonctionne-t-elle ?* Si le critère est trop laxiste, une image défaillante est
confirmée et le dispositif ne sert à rien. S'il est trop strict, une image
saine est annulée — et vous faites reculer votre flotte sans raison.

## Un cas réel

Lors de la mise au point de cette plateforme, le critère était un **instantané
unique** : au bout de 60 secondes, le device vérifiait une fois s'il était
connecté.

Un incident de résolution DNS sur la passerelle a fait que la connexion au
broker a mis **141 secondes** à s'établir. L'image, parfaitement saine, aurait
été refusée puis annulée au redémarrage suivant.

Le firmware que vous utilisez a été corrigé : il observe en continu et confirme
dès que le fonctionnement est nominal pendant une durée suffisante, avec une
échéance au-delà de laquelle il renonce.

Relisez `attendre_fonctionnement_nominal()` dans `main.c` et répondez :

**Pourquoi le compteur est-il remis à zéro à chaque coupure** plutôt que
cumulé ? Qu'est-ce qu'on accepterait sinon ?

**Pourquoi une échéance en plus du critère ?** Que se passerait-il sans elle ?

## Trois critères à comparer

Pour chacun, dites ce qu'il laisse passer à tort et ce qu'il refuse à tort :

| Critère | Faux positifs | Faux négatifs |
|---|---|---|
| L'image a démarré | | |
| Connecté au broker 30 s d'affilée | | |
| 10 mesures acceptées par le backend | | |

Le troisième est celui qu'on utilise souvent en production. Il est plus lent,
plus complexe, et demande une coopération du backend. **Pourquoi l'accepter
quand même ?**

## Votre note

Dix lignes, à rendre. Proposez un critère de validation pour une flotte de
capteurs de température en entrepôt frigorifique, sachant que :

- les devices sont alimentés sur secteur et toujours en ligne
- le réseau Wi-Fi du site est saturé en journée, calme la nuit
- une panne non détectée de plus de deux heures déclenche une alerte sanitaire

Justifiez votre durée d'observation et votre échéance. Il n'y a pas de bonne
réponse unique — on attend un raisonnement, pas un chiffre.

:::tip[Vérification]
Votre note tient en dix lignes, propose des valeurs chiffrées, et explique ce
que vous acceptez de perdre dans chaque sens.
:::

:::info[Objectif bonus]
Le déploiement progressif consiste à mettre à jour 1 % de la flotte, observer,
puis 10 %, puis le reste. Avec le mécanisme dont vous disposez, quelles
informations devriez-vous collecter entre deux paliers pour décider de
continuer ou d'arrêter ? Rédigez la règle d'arrêt.
:::
