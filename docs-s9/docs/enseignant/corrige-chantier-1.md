---
id: corrige-chantier-1
title: Corrigé — Chantier 1 (device)
sidebar_position: 3
---

# Corrigé — Chantier 1

Réponses attendues, erreurs fréquentes et points de notation.

## Codes de raison Wi-Fi

Le tableau que les étudiants doivent remplir par observation :

| Code | Nom ESP-IDF | Cause provoquée | Ce qu'il faut vérifier |
|---|---|---|---|
| 2 | `AUTH_EXPIRE` | aléa radio, survient seul | rien — se rétablit en 4 s |
| 8 | `ASSOC_LEAVE` | départ volontaire avant reboot | rien — comportement normal |
| 15 | `4WAY_HANDSHAKE_TIMEOUT` | clé WPA2 erronée | le mot de passe |
| 201 | `NO_AP_FOUND` | SSID inexistant ou hors portée | le SSID, la distance |

**Le point qui discrimine** : distinguer 2 et 8. Les deux apparaissent en
fonctionnement nominal et ressemblent à des pannes. Le 2 est subi — la carte
se reconnecte seule quatre secondes plus tard. Le 8 est volontaire, émis par
le device avant un redémarrage. Un binôme qui alerte sur un code 2 isolé n'a
pas compris.

:::note[Erreur fréquente]
« Le code 2 signale un problème de sécurité ». Non — c'est une expiration
d'authentification due aux conditions radio. On le voit systématiquement au
premier démarrage sur cette plateforme, et il est sans conséquence.
:::

## Convention de topics

**QoS 0 pour la télémétrie, 1 pour les événements.** On accepte de perdre une
mesure : la suivante arrive dans cinq secondes et la tendance reste lisible.
On n'accepte pas de perdre un événement : un redémarrage ou un échec de mise à
jour ne se reproduit pas, et son absence serait interprétée comme une absence
de problème.

**`st/<id>` retenu.** Le broker conserve le dernier message et le délivre
immédiatement à tout nouvel abonné. Sans cela, un superviseur qui démarre ne
saurait rien de l'état de la flotte avant le prochain changement — c'est-à-dire
potentiellement jamais pour un device stable.

**Trois préfixes plutôt qu'un topic par device.** La hiérarchie permet de
filtrer transversalement : `tel/+/temperature` capte toutes les températures de
l'îlot. Avec un topic par device, il faudrait énumérer les devices, donc les
connaître à l'avance — exactement ce qu'on ne peut pas faire à l'échelle.

Réponse attendue sur le bonus : `+/evt/+/boot` sur le broker central.

## Last Will

**Délai de détection** = `keepalive` × 1,5, soit 45 secondes avec la valeur de
30 s du firmware. Le broker n'abandonne pas un client au premier battement
manqué ; la norme MQTT prévoit une fois et demie l'intervalle.

Les étudiants mesurent généralement entre 40 et 50 secondes. Toute valeur dans
cette plage est bonne ; ce qui compte est qu'ils fassent le lien avec le
paramètre plutôt que de constater un délai arbitraire.

**Pourquoi `offline` arrive immédiatement sur un nouvel abonnement** alors que
le device est parti depuis longtemps : le message est retenu. C'est le même
mécanisme que pour `online`, et les deux occupent le même topic en se
remplaçant.

**L'alerte « device muet »**, formulation attendue :

> Alerter quand `st/<id>` vaut `offline` pendant plus de N minutes, sauf si un
> événement `evt/<id>/ota` a été reçu dans les M dernières minutes.

La clause d'exception est le point intéressant. Un device qui redémarre après
une mise à jour est muet une trentaine de secondes, et déclencher une alerte à
chaque campagne rendrait la supervision inutilisable. Les binômes qui
l'oublient le découvriront au chantier 4 — c'est une bonne chose.

**Bonus sur le `keepalive` à 1 seconde** : 10 000 devices × 1 message/s = 10 000
messages par seconde de pur maintien de connexion, avant toute donnée utile.
Côté device, la radio ne peut plus dormir, ce qui multiplie la consommation par
un facteur important sur batterie. Le `keepalive` est un arbitrage entre
réactivité de détection et coût, pas un réglage à minimiser.

## Bonus Wi-Fi 6

La carte est 802.11ax, le point d'accès est un Raspberry Pi 3B en 802.11n. La
négociation retient le plus petit dénominateur commun, d'où `phy: bgn`.

Exploiter le Wi-Fi 6 demanderait un point d'accès compatible. Le gain pour une
flotte de capteurs qui émettent quelques dizaines d'octets toutes les cinq
secondes est **nul en débit**. Les apports réels du 11ax ici seraient OFDMA et
TWT — meilleure gestion de la densité et de la consommation. Un binôme qui
mentionne TWT pour l'autonomie a fait le lien attendu.

## Barème indicatif

| Critère | Points |
|---|---|
| Quatre devices en service, identifiants distincts | 3 |
| Tableau des codes de raison, observés et interprétés | 4 |
| Distinction 2 / 8 explicitée | 2 |
| Justification QoS et message retenu | 4 |
| Last Will démontré, délai mesuré et expliqué | 4 |
| Formulation de l'alerte avec clause d'exception | 3 |
| Objectifs bonus | +3 |

## Chronométrage observé

| Étape | Prévu | Constaté |
|---|---|---|
| Flash | 40 min | à compléter |
| Démarrage | 25 min | à compléter |
| Flotte | 35 min | à compléter |
| Last Will | 20 min | à compléter |

## Ce qu'il faut surveiller en séance

**Les prérequis non faits.** C'est le risque majeur. Un étudiant sans ESP-IDF
installé immobilise son binôme pendant une heure. Prévoyez une clé USB avec
l'installeur hors ligne, et rappelez que quatre devices par îlot signifie
qu'un laptop fonctionnel par groupe suffit à avancer.

**L'installeur qui échoue silencieusement.** Le symptôme n'apparaît qu'au
premier `export.ps1` : `ESP-IDF Python virtual environment not found`. La
réparation est dans la page des pièges, mais il faut penser à `IDF_TOOLS_PATH`
sans quoi tout est retéléchargé.

**Le mauvais port USB.** Celui marqué `UART` exige un pilote. Faites-en une
consigne visuelle au tableau plutôt qu'une ligne dans l'énoncé.
