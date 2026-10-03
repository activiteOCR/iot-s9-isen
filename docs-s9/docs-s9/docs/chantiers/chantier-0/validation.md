---
id: validation
title: 4. Valider l'îlot
sidebar_position: 6
---

# Vérifier que la chaîne complète fonctionne

**10 minutes.** Deux tests, et le chantier est clos.

## Le vérificateur

Sur la passerelle :

```bash
cd ~/ilot-s9/pi && ./check-ilot.sh 3
```

Il contrôle une par une les briques dont dépendent tous les chantiers
suivants : radio, DHCP, alimentation, broker, bridge, serveur de firmware.

Sortie attendue :

```text
=== Ilot 3 ===============================

Radio
  / hostapd actif
  / dnsmasq actif (serveur DHCP)
  / wlan0 en mode point d'acces, canal 11
  / wlan0 porte 192.168.30.1
  / puissance d'emission 10.00 dBm (bridee)
  / alimentation saine (get_throttled = 0x0)

Devices
  X aucun device associe

Broker de peripherie
  / mosquitto actif
  / publication locale sur 192.168.30.1:1883

Bridge vers le laptop
  / laptop joignable en 10.10.3.2
  / broker central du laptop accessible
  / bridge MQTT tente/etabli

Serveur de firmware
  / http://192.168.30.1:8080/ repond
```

La ligne `aucun device associe` reste rouge : vos ESP32 ne sont pas encore en
jeu, c'est le chantier suivant.

Toute autre ligne rouge doit être traitée maintenant. La page
[Pièges connus](./pieges) couvre les cas rencontrés jusqu'ici.

## Le test de bout en bout

Le vérificateur teste des briques isolées. Ce second test suit un message sur
tout son parcours.

Gardez votre abonnement ouvert côté laptop :

```bash
docker exec -it ilot-mosquitto mosquitto_sub -t '#' -v
```

Et publiez depuis la passerelle :

```bash
mosquitto_pub -h 192.168.30.1 -t tel/dev01/temperature -m '{"value":21.4}'
mosquitto_pub -h 192.168.30.1 -t evt/dev01/boot -m '{"version":"1.0.0"}'
```

:::tip[Vérification]
Sur le laptop :

```text
ilot3/tel/dev01/temperature {"value":21.4}
ilot3/evt/dev01/boot {"version":"1.0.0"}
```

Le préfixe `ilot3/` n'a pas été tapé : il a été ajouté au passage du bridge.
C'est ce qui permettra aux cinq îlots de remonter vers un broker commun sans
que leurs topics entrent en collision.
:::

## Contrôler que les données sont bien stockées

Un message qui transite n'est pas un message enregistré. Dans Grafana,
**Explore**, source InfluxDB, bucket `iot` :

```flux
from(bucket: "iot")
  |> range(start: -15m)
  |> filter(fn: (r) => r._measurement == "telemetrie")
```

Votre point de température doit apparaître, avec les étiquettes `ilot`,
`device` et `metrique` extraites du topic par Telegraf.

S'il ne remonte rien alors que le message est bien passé sur le broker, le
problème est dans Telegraf, pas dans MQTT. Distinguer les deux est exactement
le genre de raisonnement que le module 3 vous demandera.

## Rendu de fin de séance

- votre schéma d'architecture
- la sortie complète du vérificateur, horodatée
- votre réponse sur le double message du bridge

:::info[Objectif bonus]
Coupez le câble Ethernet, publiez trois messages depuis la passerelle, puis
rebranchez. Combien de messages arrivent sur votre laptop ? Regardez la
directive `cleansession` dans la configuration du bridge et expliquez le
résultat.

Cette question porte sur la garantie de livraison en cas de coupure — un des
sujets centraux du cours.
:::
