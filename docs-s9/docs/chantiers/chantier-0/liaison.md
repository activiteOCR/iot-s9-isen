---
id: liaison
title: 1. Établir la liaison
sidebar_position: 3
---

# Relier le laptop à la passerelle

**15 minutes.** Objectif : un lien IP direct entre votre laptop et la
passerelle, sans routeur ni serveur DHCP entre les deux.

## Pourquoi une adresse fixe

Il n'y a **aucun serveur DHCP sur ce lien**. La passerelle en héberge un, mais
uniquement pour le Wi-Fi des devices, pas pour le câble. Personne ne vous
attribuera d'adresse : vous devez la poser vous-même, des deux côtés d'un lien
qui ne mène nulle part ailleurs.

C'est le montage qu'on utilise pour accéder à un équipement industriel isolé,
et vous en retrouverez le principe chaque fois qu'il faut intervenir sur une
machine hors réseau.

## Câblage

Reliez directement le port Ethernet de votre laptop à celui de la passerelle.
Un câble droit ordinaire suffit — les Raspberry Pi gèrent l'auto-croisement.

Contrôlez les diodes du connecteur RJ45 de la passerelle : sans lumière, le
lien physique n'est pas établi et rien de ce qui suit ne fonctionnera.

## Configurer l'adresse

Rappel : `N` est le numéro de votre îlot. Vous prenez `10.10.N.2`, la
passerelle occupe déjà `10.10.N.1`.

<details>
<summary><strong>Windows</strong></summary>

Identifiez d'abord la bonne carte, en PowerShell :

```powershell
Get-NetAdapter
```

Repérez la ligne dont l'`InterfaceDescription` correspond à votre port
Ethernet, et notez son `Name` — souvent `Ethernet`.

Puis, en PowerShell **administrateur** :

```powershell
$if = "Ethernet"   # remplacer par le Name exact

New-NetIPAddress -InterfaceAlias $if -IPAddress 10.10.<N>.2 -PrefixLength 24
Set-NetConnectionProfile -InterfaceAlias $if -NetworkCategory Private
New-NetFirewallRule -DisplayName "MQTT ilot" -Direction Inbound `
    -Protocol TCP -LocalPort 1883 -Action Allow -Profile Private,Public
```

Trois commandes, trois rôles distincts : l'adresse, la catégorie de réseau, et
l'ouverture du port. **Aucune des trois n'est facultative.** Sans la deuxième,
Windows classe le lien comme public et bloque tout trafic entrant ; la
passerelle ne pourra jamais joindre votre broker.

Si `New-NetIPAddress` répond que l'objet existe déjà, purgez d'abord :

```powershell
Remove-NetIPAddress -InterfaceAlias $if -Confirm:$false
Remove-NetRoute -InterfaceAlias $if -Confirm:$false
```

</details>

<details>
<summary><strong>macOS</strong></summary>

Réglages → Réseau → sélectionnez l'interface Ethernet → Détails → TCP/IP.

Configurer IPv4 : **Manuellement**. Adresse `10.10.3.2`, masque
`255.255.255.0`, routeur **vide**.

</details>

<details>
<summary><strong>Linux</strong></summary>

```bash
sudo nmcli connection add type ethernet ifname eth0 con-name ilot \
    ipv4.method manual ipv4.addresses 10.10.3.2/24 ipv6.method disabled
sudo nmcli connection up ilot
```

Adaptez `eth0` au nom réel de votre interface, que donne `ip -brief link`.

</details>

:::danger[Ne renseignez pas de passerelle par défaut]
Le champ « passerelle » ou « routeur » doit rester **vide**. Ce lien ne mène
nulle part au-delà du Raspberry Pi. Si vous y déclarez une route par défaut,
votre système enverra tout son trafic Internet dans un câble qui ne va nulle
part, et vous perdrez l'accès au réseau de l'école.
:::

## Contrôler

```bash
ping 10.10.<N>.1
```

:::tip[Vérification]
Quatre réponses, sans perte, en moins d'une milliseconde.

Si le ping échoue : voir [Pièges connus](./pieges#le-ping-vers-la-passerelle-échoue).
:::

Notez au passage la latence obtenue. Vous la comparerez au module 3 avec celle
mesurée sur le lien Wi-Fi des devices — l'écart entre les deux explique
beaucoup de choix d'architecture.
