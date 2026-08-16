---
id: passerelle
title: 3. Cartographier la passerelle
sidebar_position: 5
---

# Enquêter sur une machine inconnue

**20 minutes.** C'est le cœur du chantier, et le seul endroit où l'on vous
demande de chercher plutôt que d'exécuter.

Vous avez reçu une machine configurée par quelqu'un d'autre, sans
documentation. Votre travail : produire le schéma qui manque.

:::danger[En lecture seule]
Aucune commande de cette page ne modifie quoi que ce soit. Vous observez.
Résistez à l'envie de corriger ce qui vous semble mal réglé : au module 5, une
passerelle sabotée vous sera confiée et il faudra la réparer. D'ici là,
gardez-la intacte.
:::

## Se connecter

```bash
ssh isen-iot@10.10.3.1
```

## Les questions auxquelles répondre

Ne recopiez pas les sorties dans votre rendu. Cherchez les réponses, et
n'écrivez que ce qui va dans le schéma.

### Quelles interfaces réseau, quelles adresses ?

```bash
ip -brief addr
ip route
```

Combien d'interfaces actives ? Quelle adresse porte chacune ? Y a-t-il une
route par défaut, et si non, qu'est-ce que ça implique pour cette machine ?

### Quels services tournent ?

```bash
systemctl list-units --type=service --state=running | grep -vE 'systemd|dbus|user@'
```

Quatre services vous concernent directement. Identifiez-les et déduisez le rôle
de chacun de son nom.

### Quels ports écoutent, et pour qui ?

```bash
sudo ss -tlnp
```

Colonne par colonne : quel port, quelle adresse d'écoute, quel processus. Une
adresse d'écoute en `0.0.0.0` n'a pas la même portée qu'une écoute sur une
adresse précise — la différence compte pour votre schéma.

### Comment le Wi-Fi est-il configuré ?

```bash
iw dev wlan0 info
sudo cat /etc/hostapd/hostapd.conf
```

Quel canal ? Quel chiffrement ? Quelle puissance d'émission, et pourquoi
si basse à votre avis, sachant qu'il y a cinq îlots dans la salle ?

### Qui distribue les adresses aux devices ?

```bash
cat /etc/dnsmasq.d/ilot.conf
cat /var/lib/misc/dnsmasq.leases
```

Quelle plage ? Quelle durée de bail ? Le second fichier est vide pour
l'instant : il se remplira au chantier suivant, quand vous allumerez les
ESP32.

### Comment les messages remontent-ils jusqu'à vous ?

```bash
sudo cat /etc/mosquitto/conf.d/ilot.conf
```

C'est le fichier le plus important de la machine. Repérez le bloc `connection`
et répondez précisément :

- vers quelle adresse pointe-t-il, et pourquoi celle-là ?
- quels topics montent, lesquels descendent ?
- qu'arrive-t-il au topic `tel/dev01/temperature` quand il traverse le bridge ?

### Que s'est-il passé récemment ?

```bash
journalctl -u hostapd -n 50 --no-pager
journalctl -u mosquitto -n 30 --no-pager
```

Ces journaux sont votre principal outil de diagnostic pour tout le reste du
cours. Prenez le temps de reconnaître la forme d'une association Wi-Fi réussie
maintenant, pendant que tout va bien — vous saurez ainsi reconnaître un échec
quand il se présentera.

## Livrable

Un schéma d'une page faisant apparaître :

- les trois éléments : devices, passerelle, laptop
- chaque interface réseau avec son adresse et son masque
- chaque service avec son port d'écoute
- le sens de circulation des messages, et la transformation opérée par le
  bridge

Mermaid, Draw.io ou papier — peu importe. Ce qui compte est qu'un collègue
n'ayant jamais vu l'îlot puisse s'en servir pour intervenir.

:::info[Objectif bonus]
La passerelle n'a aucune route par défaut. Elle ne peut donc joindre ni
Internet, ni le réseau de l'école. Listez trois conséquences concrètes de ce
choix pour l'exploitation : une positive, une négative, une qui vous
compliquera la vie au chantier sur les mises à jour firmware.
:::
