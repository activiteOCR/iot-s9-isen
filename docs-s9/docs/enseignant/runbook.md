---
id: runbook
title: Runbook — chantier 0
sidebar_position: 1
---

# Runbook enseignant — chantier 0

Cette section n'est pas destinée aux étudiants. Retirez-la du déploiement
public, ou protégez-la par mot de passe côté Vercel.

## Préparation des passerelles

L'installation complète est décrite dans le dépôt `ilot-s9`, script
`pi/setup-ilot.sh`. Points d'attention :

**Le Pi doit avoir Internet au lancement du script.** La dernière étape
bascule `eth0` en statique et supprime cet accès. Utiliser
`--garder-reseau` pour préparer une image sans couper la connexion.

**Changer les secrets avant clonage** : clés Wi-Fi `iot-s9-ilot-N`, token
InfluxDB, mot de passe Grafana. Ils sont publiés dans le dépôt étudiant.

**Après clonage**, sur chaque Pi :

```bash
sudo hostnamectl set-hostname ilotN
sudo ./setup-ilot.sh N
```

**Le test des cinq îlots simultanés ne se simule pas.** Cinq points d'accès en
2,4 GHz dans une même salle, tous les devices allumés. À faire en conditions
réelles avant la première séance.

## Ce que l'énoncé ne dit pas

**hostapd plutôt que NetworkManager.** Le mode point d'accès de NetworkManager
échoue sur les puces Broadcom des Raspberry Pi : la radio balise, aucun client
ne s'associe, et `dmesg` affiche
`brcmf_vif_set_mgmt_ie: vndr ie set error : -52`. Constaté sur Pi 3B /
Raspberry Pi OS Trixie. Si un îlot présente ce symptôme, vérifier que
`/etc/NetworkManager/conf.d/99-ilot-unmanaged.conf` est en place.

**mosquitto refuse les doublons.** Le `mosquitto.conf` de Debian déclare déjà
`persistence`, `persistence_location` et `log_dest`. Les redéclarer dans
`conf.d/` empêche le démarrage avec un message que `systemctl` ne montre pas.
Diagnostic : `mosquitto -c /etc/mosquitto/mosquitto.conf -v`.

**Le PMF doit rester désactivé.** Le module Inventek ISM43362 des cartes ST ne
le supporte pas. Ne pas « renforcer » `ieee80211w`.

## Réponses aux objectifs bonus

**Le double message de bridge.** `st/bridge/ilotN` apparaît sous deux formes
sur le broker central : la version nue, publiée localement par le broker de
périphérie via `notification_topic`, et la version préfixée `ilotN/st/...`
remontée par le bridge qui applique le préfixe à tout ce qui sort. Réponse
attendue : ils doivent identifier que le préfixe est ajouté **à la sortie**,
pas à l'émission. Pour la fédération, filtrer sur `+/st/bridge/+`.

**Les conséquences de l'absence de route par défaut.** Positive : surface
d'attaque réduite, aucune exposition depuis l'extérieur, comportement
déterministe. Négative : pas de mise à jour système, pas de synchronisation
d'horloge — donc dérive des horodatages, à exploiter au module 5. Pour les
mises à jour firmware : les binaires ne peuvent pas être téléchargés depuis
Internet, ils doivent être poussés sur la passerelle, ce qui introduit
justement la notion de dépôt d'artefacts local.

**Les messages pendant la coupure.** Avec `cleansession false` et QoS 0, les
messages publiés pendant la coupure sont perdus : le QoS 0 ne fait l'objet
d'aucune file d'attente. Les trois messages ne réapparaissent pas. C'est le
résultat attendu, et il ouvre directement la discussion sur le choix du QoS
au module 2.

## Chronométrage observé

| Étape | Prévu | Constaté |
|---|---|---|
| Liaison | 15 min | à compléter |
| Supervision | 15 min | à compléter |
| Cartographie | 20 min | à compléter |
| Validation | 10 min | à compléter |

Tenir cette colonne à jour après chaque promo : c'est la seule donnée fiable
pour ajuster le découpage des 24 heures.

## Grille d'évaluation

| Critère | Points |
|---|---|
| Schéma : interfaces et adresses correctes | 4 |
| Schéma : services et ports | 3 |
| Schéma : sens de circulation et transformation du bridge | 3 |
| Vérificateur au vert, horodaté | 4 |
| Réponse sur le double message | 3 |
| Objectifs bonus | +3 |

Le schéma est noté sur son utilité opérationnelle : un collègue n'ayant jamais
vu l'îlot doit pouvoir intervenir avec. Ni l'esthétique ni l'exhaustivité ne
sont valorisées.
