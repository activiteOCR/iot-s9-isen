---
id: flotte
title: 3. Observer la flotte
sidebar_position: 5
---

# Quatre devices, une convention

**35 minutes.** Quatre cartes allumées, c'est le minimum en dessous duquel
« gérer une flotte » n'a aucun sens.

## Écouter

Sur la passerelle :

```bash
mosquitto_sub -h 192.168.N0.1 -t '#' -v
```

Vous devez voir défiler quatre devices, chacun publiant quatre mesures toutes
les cinq secondes.

## La convention de topics

Elle n'est pas décorative. Chaque préfixe a un rôle, une durée de vie et un
sens de circulation différents.

| Topic | Sens | QoS | Retenu | Rôle |
|---|---|---|---|---|
| `tel/<id>/<métrique>` | montant | 0 | non | télémétrie, flux continu |
| `evt/<id>/<type>` | montant | 1 | non | événements ponctuels |
| `st/<id>` | montant | 1 | **oui** | état de présence |
| `cmd/<id>/<action>` | descendant | 1 | non | commandes |

Répondez par écrit, c'est l'essentiel de l'étape :

**Pourquoi la télémétrie est-elle en QoS 0 et les événements en QoS 1 ?**
Qu'est-ce qu'on accepte de perdre, et pourquoi ce n'est pas grave ?

**Pourquoi `st/<id>` est-il retenu alors que les autres ne le sont pas ?**
Testez : abonnez-vous à `st/#` après que les devices sont déjà en route, et
observez ce que vous recevez immédiatement.

**Pourquoi la remontée est-elle découpée en trois préfixes** plutôt qu'un seul
topic par device ? Essayez de vous abonner à toutes les températures de l'îlot
en une seule expression — vous comprendrez.

## Les métriques

Quatre mesures par device, mais elles ne se valent pas :

```bash
mosquitto_sub -h 192.168.N0.1 -t 'tel/+/+' -v
```

`temperature` et `humidite` sont **synthétiques** — produites par le firmware,
sans capteur. `rssi` et `uptime` sont réelles.

Ce choix est délibéré, et il mérite d'être discuté : un capteur réel donne des
valeurs qu'on ne peut pas faire varier à la demande. Pour apprendre à
superviser, mieux vaut des données qu'on maîtrise.

Mais les deux métriques réelles sont celles qui serviront vraiment au
diagnostic. **Comparez le RSSI de vos quatre devices.** Éloignez-en un, posez
une main sur l'antenne d'un autre, mettez-en un derrière un écran de laptop.
Notez les écarts.

:::tip[Vérification]
```bash
mosquitto_sub -h 192.168.N0.1 -t 'st/#' -v -C 4
```
Quatre lignes `online`, une par device, reçues **immédiatement** sans attendre
le prochain cycle de télémétrie.
:::

## Côté passerelle

Vos messages ne s'arrêtent pas au broker local. Sur le laptop de l'îlot :

```bash
docker exec -it ilot-mosquitto mosquitto_sub -t '#' -v
```

Les mêmes messages arrivent, préfixés du nom de votre îlot. C'est le bridge
que vous avez identifié au chantier 0 — et c'est ce qui permettra, au module
sur la scalabilité, de superviser les cinq îlots depuis un point unique.

:::info[Objectif bonus]
Écrivez l'expression d'abonnement qui capte **uniquement les événements de
redémarrage de tous les devices de tous les îlots**, sur le broker central.
Vérifiez-la en redémarrant une carte.
:::
