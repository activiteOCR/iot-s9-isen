---
id: demarrage
title: 2. Lire le démarrage
sidebar_position: 4
---

# Ce que raconte un journal de démarrage

**25 minutes.** Un firmware embarqué dit beaucoup de choses en deux cents
lignes. Savoir y repérer les cinq qui comptent est une compétence de métier.

## Les lignes à identifier

Relancez `idf.py monitor` et appuyez sur RESET pour voir la séquence complète.
Retrouvez dans le journal, et notez-les :

**La table de partitions.** Combien d'emplacements applicatifs ? De quelle
taille ? Pourquoi deux, à votre avis ? Vous aurez la réponse au chantier sur
les mises à jour, mais formulez une hypothèse maintenant.

**L'emplacement de démarrage** — `Loaded app from partition at offset 0x…`.
Retenez cette valeur, elle va changer.

**La version applicative** — `App version:`. Elle vient du fichier
`CMakeLists.txt` du projet et se retrouve dans les métadonnées de l'image.

**La qualité du lien radio** — `rssi: -57`. Un ordre de grandeur à mémoriser
dès maintenant : vous le comparerez quand les quatre devices seront allumés, et
vous le reverrez au module sur la supervision.

**Le mode de sécurité** — `security: WPA2-PSK, phy: bgn, pmf:0`. Trois
informations utiles : le chiffrement, la norme radio effectivement négociée, et
l'état des trames de gestion protégées.

:::info[Objectif bonus]
Votre carte fait du Wi-Fi 6. Le journal indique pourtant `phy: bgn`, soit du
802.11n. Pourquoi ? Et que faudrait-il changer pour exploiter le Wi-Fi 6 ?
Évaluez ce que ça coûterait pour ce que ça rapporterait sur une flotte de
capteurs.
:::

## Diagnostiquer un échec d'association

C'est l'exercice central de cette étape. **Provoquez des pannes et lisez ce
qu'elles produisent.**

Dans `menuconfig`, modifiez la clé WPA2 — remplacez un caractère — puis
recompilez et flashez. Observez :

```text
W (xxx) wifi: deconnecte, raison 15 (tentative 1)
```

Recommencez avec un SSID inexistant. Puis avec la bonne configuration, mais en
éloignant la carte de la passerelle jusqu'à la perte du lien.

Complétez ce tableau avec ce que vous observez :

| Code | Ce que vous avez fait | Interprétation |
|---|---|---|
| 2 | | |
| 15 | | |
| 201 | | |
| 8 | | |

Les codes 2 et 8 apparaissent spontanément en fonctionnement normal. Ne les
confondez pas : l'un est subi, l'autre est volontaire. La distinction est
essentielle quand vous analyserez un incident réel.

:::tip[Vérification]
Votre tableau est rempli avec quatre codes observés — pas recopiés d'une
documentation. Et votre carte est revenue à la bonne configuration.
:::

:::note[Le mot de passe est dans le binaire]
Vous venez de compiler des identifiants Wi-Fi en dur dans un firmware. Quiconque
récupère une de vos cartes peut les extraire en quelques minutes. C'est
exactement le problème que le chantier sur le provisioning va résoudre.
:::
