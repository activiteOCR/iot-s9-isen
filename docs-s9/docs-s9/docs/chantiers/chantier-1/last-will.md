---
id: last-will
title: 4. Faire taire un device
sidebar_position: 6
---

# Prouver qu'un device est tombé

**20 minutes.** C'est la question centrale de l'exploitation, et elle est plus
difficile qu'elle n'en a l'air.

## Le problème

Un device qui ne publie plus peut être : éteint, hors de portée, planté, ou
simplement entre deux cycles de télémétrie. **L'absence de message ne prouve
rien** — un superviseur naïf déclencherait des alertes en permanence.

## Deux manières de disparaître

Faites les deux, et comparez ce que le broker en dit.

**Déconnexion propre.** Appuyez sur RESET. La carte prévient le broker avant de
partir.

**Disparition brutale.** Débranchez le câble USB. Rien n'est annoncé.

Gardez cet abonnement ouvert pendant les deux essais :

```bash
mosquitto_sub -h 192.168.N0.1 -t 'st/#' -v
```

Chronométrez le délai entre le débranchement et l'apparition du message
`offline`. Il n'est pas immédiat — et ce délai n'est pas arbitraire.

## Le Last Will

Le device déclare à la connexion un message que le broker publiera **à sa
place** s'il disparaît sans se déconnecter proprement. C'est le mécanisme qui
permet de distinguer un silence d'une panne.

Regardez `main/ilot_mqtt.c`, fonction `ilot_mqtt_start()`. Trois paramètres
déterminent le comportement que vous venez d'observer : le topic du testament,
son caractère retenu, et le `keepalive`.

**Calculez le délai de détection théorique** à partir de la valeur de
`keepalive`, et comparez-le à votre mesure. L'écart s'explique : le broker
n'abandonne pas un client au premier battement manqué.

:::tip[Vérification]
```bash
mosquitto_sub -h 192.168.N0.1 -t 'st/dev01' -v -C 1
```
Avec `dev01` débranché, vous recevez `offline` immédiatement — alors que le
device est parti depuis longtemps. Expliquez pourquoi en une phrase.
:::

## Ce que ça change pour la supervision

Vous disposez maintenant de tout ce qu'il faut pour écrire une alerte « device
muet ». Formulez-la en français, précisément :

> Alerter quand … pendant … sauf si …

La clause `sauf si` est la plus intéressante. Un device qui redémarre après une
mise à jour est muet pendant quelques secondes, et ce n'est pas un incident.
Vous implémenterez cette alerte au module sur la supervision ; le travail
conceptuel se fait ici.

:::info[Objectif bonus]
Réduisez le `keepalive` à 10 secondes, recompilez, et mesurez de nouveau le
délai de détection. Puis répondez : pourquoi ne pas le mettre à 1 seconde ?
Chiffrez le coût sur une flotte de 10 000 devices — en messages par seconde
côté broker, et en consommation côté device.
:::
