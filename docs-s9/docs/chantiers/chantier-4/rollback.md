---
id: rollback
title: 4. Casser l'image
sidebar_position: 5
---

# La mise à jour qui tue le device

**45 minutes.** C'est la démonstration qui justifie tout le dispositif.

## Le scénario

Vous déployez une nouvelle version. Elle s'installe correctement, l'image est
complète et vérifiée, la carte redémarre dessus. Et là, elle ne fonctionne
plus — une erreur de configuration passée inaperçue en recette.

Sur un device de production, ce serait fini. Ici, vous allez voir la carte
revenir seule à la version précédente.

## Fabriquer une image défaillante

Dans `idf.py menuconfig`, section **Configuration de l'ilot**, remplacez l'URI
du broker par :

```text
mqtt://broker-absent.ilot:1883
```

Puis `set(PROJECT_VER "1.2.0")` dans `CMakeLists.txt`, et compilez.

:::note[Pourquoi casser MQTT plutôt que le Wi-Fi]
Un device qui ne s'associe plus du tout est un cas facile. Celui-ci est plus
vicieux et plus réaliste : la carte démarre, obtient une adresse, semble
vivante — mais ne rend plus son service. C'est le type de régression qui passe
les tests superficiels.
:::

## Déployer et observer

```powershell
scp build/ilot-device.bin isen-iot@10.10.N.1:/srv/firmware/v1.2.0.bin
idf.py monitor
```

```bash
mosquitto_pub -h 192.168.N0.1 -t cmd/dev01/ota -m "v1.2.0.bin"
```

La mise à jour se déroule normalement. Après le redémarrage :

```text
I (547) boot: Loaded app from partition at offset 0x320000
I (577) app_init: App version:      1.2.0
I (2066) mqtt: client dev01 -> mqtt://broker-absent.ilot:1883
E (2086) esp-tls: couldn't get hostname for :broker-absent.ilot
```

La 1.2.0 tourne. Elle ne se connectera jamais, donc **elle ne se déclarera
jamais valide**.

Notez la ligne `demarrage sur ota_1, version 1.2.0, etat en_verification` :
elle est journalisée localement dès le démarrage, sans attendre le réseau.
Pourquoi ce choix de conception ? Que verriez-vous si cette information n'était
publiée que sur MQTT ?

## Le retour arrière

**Appuyez sur RESET.**

```text
I (547) boot: Loaded app from partition at offset 0x20000
I (577) app_init: App version:      1.1.0
I (2066) mqtt: client dev01 -> mqtt://broker.ilot:1883
```

La carte est revenue d'elle-même à la version précédente. Sans intervention,
sans câble, sans reflashage.

:::tip[Vérification]
Trois indices concordants : l'emplacement `0x20000`, le numéro `1.1.0`, et
surtout l'URI du broker revenue à la bonne valeur — seule la 1.1.0 contient
cette chaîne. Le device republie sa télémétrie dans la minute.
:::

## Les questions à traiter

**Pourquoi faut-il un redémarrage ?** Le device savait pourtant, au bout de 300
secondes, qu'il ne fonctionnait pas. Pourquoi ne revient-il pas tout seul ?
Que faudrait-il ajouter au firmware pour ça — et quel risque cet ajout
introduirait-il ?

**Que devient l'image défaillante ?** Appuyez de nouveau sur RESET. La carte
retourne-t-elle sur la 1.2.0 ? Expliquez.

**Combien de temps a duré la panne de service ?** Du premier redémarrage sur la
1.2.0 jusqu'à la reprise de la télémétrie en 1.1.0. Sur une flotte de 10 000
devices, qu'est-ce que ce chiffre représente ?

:::info[Objectif bonus]
Déployez une 1.3.0 qui démarre mais **plante** après trente secondes, par
exemple en déréférençant un pointeur nul. Le comportement est-il le même ? Le
chien de garde change-t-il quelque chose ? C'est le cas le plus favorable au
retour arrière — trouvez pourquoi.
:::

## Avant de passer à la suite

Remettez l'URI du broker à `mqtt://broker.ilot:1883` et passez en `1.3.0`.
Votre `sdkconfig` local contient encore la configuration défaillante, et votre
prochaine compilation reproduirait l'image cassée.
