---
id: corrige-chantier-4
title: Corrigé — Chantier 4 (OTA)
sidebar_position: 4
---

# Corrigé — Chantier 4

## Mécanisme

**Avec un seul emplacement**, une coupure à 60 % de l'écriture laisse en
mémoire un mélange de l'ancienne et de la nouvelle image. Le chargeur
d'amorçage refuse de démarrer, ou démarre quelque chose d'incohérent. Le device
est irrécupérable sans accès physique. C'est ce scénario, et lui seul, qui
justifie de sacrifier 3 Mo de flash.

**La validation en fin de séquence.** Si `esp_ota_mark_app_valid_cancel_rollback()`
était appelée à la première ligne de `app_main()`, le mécanisme ne garantirait
plus qu'une chose : que l'image démarre. Or une image qui démarre mais ne rend
plus son service est exactement le cas qu'on cherche à rattraper. Le retour
arrière deviendrait décoratif.

C'est l'erreur la plus répandue dans les exemples en ligne, et elle mérite
d'être montrée explicitement.

**Bonus anti-rollback.** `CONFIG_BOOTLOADER_APP_ANTI_ROLLBACK` empêche
d'installer une version antérieure, ce qui bloque la réintroduction délibérée
d'une version vulnérable par un attaquant qui aurait récupéré un ancien binaire
signé. Le risque : il s'appuie sur des eFuses, donc il est **irréversible**. Une
erreur de numérotation en production peut condamner une flotte entière à ne
plus jamais accepter de mise à jour.

## Mise à jour nominale

**Pourquoi un nom de fichier plutôt qu'une URL.** L'opérateur n'a pas à
connaître l'adresse de la passerelle du site concerné. Le device, lui, la
connaît forcément. La même commande fonctionne donc sur les cinq îlots — et
sur les mille sites d'un déploiement réel. C'est le même principe que
`broker.ilot` au chantier 1 : ne jamais faire porter à l'émetteur ce qui dépend
du site.

**Débit mesuré sur cette plateforme** : environ 600 kbit/s, soit 14 à 15
secondes pour une image de 1,08 Mo. Valeur obtenue avec un Pi 3B en point
d'accès, puissance bridée à 10 dBm, nginx local.

Pour quatre devices simultanés, si la bande passante est le facteur limitant :
environ une minute. Les étudiants qui répondent « 15 secondes, c'est parallèle »
n'ont pas vu que la radio est un médium partagé — bonne occasion de le dire.

**Pour 10 000 devices** : 10 000 × 1,08 Mo = 10,8 To à servir. Le téléchargement
simultané est impensable, non pas à cause de la durée mais de la saturation du
réseau et du serveur. Les réponses attendues : déploiement par vagues,
distribution hiérarchique avec des caches locaux, fenêtres horaires, et surtout
**mise à jour différentielle** — ne transmettre que ce qui change.

## Interruptions

Les trois essais doivent tous se terminer par un échec propre, sans
redémarrage et sans interruption de la télémétrie.

**Pourquoi `stop` ne coupe pas au moment demandé.** `systemctl stop nginx`
envoie un arrêt gracieux : nginx laisse les connexions en cours se terminer.
Sur cette plateforme, la coupure demandée à 6 secondes se produisait en réalité
à 12. `kill -s KILL` tue le processus immédiatement et donne une coupure
déterministe.

C'est une excellente question d'examen parce qu'elle n'a rien à voir avec l'IoT :
elle teste la compréhension de ce que fait réellement une commande
d'administration courante.

**Ce qui refuse une image tronquée.** `esp_https_ota_is_complete_data_received()`
compare les octets reçus à la taille annoncée dans l'en-tête HTTP. Mais ce n'est
pas la seule protection : le chargeur d'amorçage **vérifie l'empreinte SHA-256
de l'image** avant de basculer dessus. Les deux vérifications `esp_image:
segment …` qui apparaissent juste avant le redémarrage lors d'une mise à jour
réussie sont précisément cette validation.

Un binôme qui ne cite que la première vérification a répondu à moitié.

**Les deux signatures d'échec**, distinction à exiger :

| Message | Couche | Diagnostic |
|---|---|---|
| `ESP_ERR_HTTP_CONNECT` au `begin` | aucune connexion établie | service arrêté, routage, pare-feu |
| `telechargement incomplet` après progression | connexion rompue en cours | lien radio, arrêt du serveur, saturation |

## Retour arrière

**Pourquoi un redémarrage est nécessaire.** Le basculement d'emplacement est
une décision du chargeur d'amorçage, qui ne s'exécute qu'au démarrage. Une
application ne peut pas se remplacer elle-même en cours d'exécution.

Pour automatiser, il faudrait appeler `esp_restart()` quand l'échéance de
validation expire. Le risque : si la cause est transitoire — une passerelle en
cours de redémarrage, par exemple — le device entre en **boucle de
redémarrage** et devient définitivement inaccessible, ce qui est pire que le
mal. Un binôme qui identifie ce risque a compris le fond du problème.

**Au second RESET**, la carte reste sur la 1.1.0. Le chargeur d'amorçage a
marqué la 1.2.0 comme abandonnée lors du premier retour arrière ; elle ne sera
plus jamais démarrée.

**Durée de panne de service** : environ 60 à 90 secondes sur cette plateforme —
démarrage de la 1.2.0, constat d'échec, RESET manuel, redémarrage en 1.1.0.
Sur 10 000 devices mis à jour par vagues, c'est négligeable **si le retour
arrière fonctionne**. Sans lui, c'est une intervention physique sur 10 000
sites.

**Pourquoi journaliser l'état OTA localement.** Si cette information n'était
publiée que sur MQTT, elle serait indisponible exactement dans le cas où on en
a besoin : quand l'image défaillante ne se connecte pas. Faire dépendre du
réseau une information de diagnostic, c'est la perdre quand elle compte.

**Bonus — l'image qui plante.** C'est le cas le plus favorable : le plantage
provoque un redémarrage automatique via le chien de garde, donc le retour
arrière s'opère **sans intervention humaine**. Paradoxe utile à souligner : une
panne franche est plus facile à traiter qu'une dégradation silencieuse.

## Critère de validation

**Compteur remis à zéro plutôt que cumulé** : sinon un device qui fonctionne
une seconde toutes les dix minutes finirait par cumuler 30 secondes et
confirmerait une image inutilisable. On exige une période nominale continue.

**L'échéance** évite que le device reste indéfiniment en attente de validation.
Sans elle, une image qui ne se connecte jamais resterait en sursis sans que rien
ne tranche — et le retour arrière n'interviendrait qu'au prochain redémarrage
fortuit.

**Les trois critères** :

| Critère | Laisse passer à tort | Refuse à tort |
|---|---|---|
| L'image a démarré | toute régression fonctionnelle | rien |
| Connecté 30 s d'affilée | une régression métier sans effet réseau | une image saine sur réseau lent |
| 10 mesures acceptées | presque rien | en cas de panne backend |

Le troisième est retenu en production malgré sa complexité parce qu'il valide
la **chaîne complète**, pas la seule connectivité. Il exige en revanche que le
backend soit fiable, sinon une panne côté serveur ferait reculer toute la
flotte — risque à mentionner.

**Note sur l'entrepôt frigorifique.** On attend un raisonnement, pas un
chiffre. Éléments de réponse : réseau saturé en journée donc durée d'observation
généreuse et échéance longue, de l'ordre de 10 à 15 minutes ; alerte sanitaire
à 2 heures donc marge confortable ; devices sur secteur donc le coût du
maintien de connexion n'est pas un facteur. Un binôme qui propose 30 secondes
d'observation sans discuter la saturation diurne n'a pas lu l'énoncé.

**Bonus — règle d'arrêt du déploiement progressif.** Informations à collecter
entre deux paliers : taux de devices passés en `online` après mise à jour,
nombre de retours arrière constatés, évolution du taux d'erreurs. Règle type :
arrêter si plus de 2 % des devices du palier n'ont pas confirmé leur image dans
les 10 minutes.

## Barème indicatif

| Critère | Points |
|---|---|
| Mise à jour nominale, journal annoté | 3 |
| Débit mesuré et extrapolation à l'échelle | 3 |
| Trois interruptions, aucun redémarrage | 3 |
| Distinction des deux signatures d'échec | 2 |
| Retour arrière démontré, trois indices cités | 4 |
| Pourquoi le redémarrage est nécessaire | 2 |
| Note sur le critère de validation | 3 |
| Objectifs bonus | +4 |

## Ce qu'il faut surveiller en séance

**`idf.py flash monitor` par réflexe.** C'est le piège numéro un : il
réinitialise `otadata` et annule la manipulation en cours sans message
d'erreur. Écrivez-le au tableau.

**nginx laissé à terre** après un essai d'interruption. Le symptôme suivant est
un `ESP_ERR_HTTP_CONNECT` que les étudiants attribuent au device. Le
`reset-failed` est nécessaire après un `kill`.

**`PROJECT_VER` non modifié.** La mise à jour fonctionne, mais rien ne change
visiblement et la manipulation perd tout son sens. La vérification par `dd` sur
le binaire déposé est le contrôle rapide.

**Le moniteur qui décroche au redémarrage** fait croire à un plantage.
Prévenez avant, pas pendant.
