---
id: pieges
title: Pièges connus
sidebar_position: 7
---

# Pièges connus

Problèmes déjà rencontrés sur cette plateforme, avec leur résolution.
Consultez cette page avant d'appeler : la moitié des blocages y figure.

Utilisez la recherche du site avec le message d'erreur exact.

## Le ping vers la passerelle échoue

**Vérifiez d'abord le lien physique.** Les diodes du connecteur RJ45 de la
passerelle doivent être allumées. Sans lumière, le problème est le câble, le
port, ou un connecteur mal enfoncé — pas la configuration.

**Vérifiez ensuite votre adresse.** Une erreur classique est de configurer la
mauvaise carte réseau, en particulier avec un adaptateur USB-Ethernet.

```powershell
Get-NetIPAddress -AddressFamily IPv4 | Format-Table InterfaceAlias, IPAddress
```

Vous devez voir `10.10.N.2` sur l'interface effectivement câblée.

**Attention aux interfaces virtuelles.** Docker Desktop, WSL et Hyper-V créent
des cartes `vEthernet` qui apparaissent dans les listes. Ne les configurez pas.

## Le ping passe mais aucun message n'arrive

C'est le pare-feu Windows, dans la quasi-totalité des cas. Le ping n'a pas
besoin d'une règle entrante, le port 1883 si.

```powershell
Get-NetConnectionProfile -InterfaceAlias "Ethernet"
```

`NetworkCategory` doit valoir `Private`. Si vous lisez `Public`, la règle de
pare-feu ne s'applique pas :

```powershell
Set-NetConnectionProfile -InterfaceAlias "Ethernet" -NetworkCategory Private
```

Le nom « Réseau non identifié » peut subsister, c'est normal sur un lien sans
passerelle. Seule la catégorie compte.

## Aucun message n'arrive sur le broker

Testez les étages un par un, en partant du plus proche.

**Le broker local du laptop répond-il ?**

```bash
docker exec -it ilot-mosquitto mosquitto_sub -t '#' -v
docker exec -it ilot-mosquitto mosquitto_pub -t test -m bonjour
```

Si votre propre message n'apparaît pas, le problème est dans le conteneur, pas
dans le réseau.

**La passerelle voit-elle votre broker ?** Depuis la passerelle :

```bash
mosquitto_sub -h 10.10.3.2 -t '$SYS/broker/version' -C 1
```

Une erreur de connexion ici renvoie au pare-feu, section précédente.

**Le bridge est-il monté ?**

```bash
journalctl -u mosquitto -n 30 --no-pager | grep -i bridge
```

## Un conteneur redémarre en boucle

Presque toujours un fichier de configuration mal monté, souvent parce que
l'arborescence a été aplatie lors de la copie.

```bash
docker compose logs <service>
ls -R          # verifier mosquitto/, telegraf/, grafana/provisioning/datasources/
```

Le dossier `grafana/provisioning/datasources/` doit être intact jusqu'au
dernier niveau, sinon la source de données ne sera pas déclarée.

## Docker refuse de monter les fichiers sur Windows

Placez le dossier dans votre profil utilisateur, chemin court, sans accent ni
espace. Le partage de fichiers de Docker Desktop échoue silencieusement sur
les lecteurs réseau et les chemins exotiques.

## Grafana affiche « No data »

Le message transite-t-il bien sur le broker ? Si oui, le problème est en aval,
dans Telegraf.

```bash
docker compose logs telegraf | tail -30
```

Vérifiez aussi le format de votre charge utile : Telegraf attend un objet JSON
plat sur les topics `tel/`. Un message texte brut comme `21.4` sera ignoré
sans erreur visible. C'est un piège classique, et un bon rappel qu'un
collecteur silencieux n'est pas un collecteur qui fonctionne.

## Un device voit le Wi-Fi mais ne s'associe jamais

Symptôme : le SSID apparaît, la connexion expire, et rien dans les journaux.

```bash
sudo journalctl -f -u hostapd -u dnsmasq
```

Retentez la connexion en gardant ce journal ouvert. Une association réussie
produit `authenticated`, puis `associated`, puis le handshake, puis un
`DHCPACK`. L'endroit où la séquence s'arrête désigne la couche fautive.

Sur Android, **oubliez le réseau** avant chaque nouvel essai : le téléphone
conserve un état d'échec qui fait rater les tentatives suivantes même après
correction du problème.

## La passerelle ne répond plus du tout

Débranchez et rebranchez son alimentation, attendez deux minutes complètes.

Si elle reste muette, vérifiez son alimentation : un Raspberry Pi
sous-alimenté ne s'arrête pas franchement, il devient instable par
intermittence. Une fois reconnecté :

```bash
vcgencmd get_throttled
```

`0x0` signifie que tout va bien. Toute autre valeur signale une sous-tension,
actuelle ou passée — signalez-le à l'enseignant, le bloc secteur est en cause.
