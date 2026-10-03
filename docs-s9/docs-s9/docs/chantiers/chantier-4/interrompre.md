---
id: interrompre
title: 3. Casser le téléchargement
sidebar_position: 4
---

# Quand le réseau lâche en route

**40 minutes.** Premier scénario de panne : l'image n'arrive jamais
complètement.

## Ce qu'on veut démontrer

Un téléchargement interrompu ne doit **rien** changer. Pas de redémarrage, pas
d'interruption de service, pas d'image à moitié écrite qui démarre. Le device
continue comme si de rien n'était.

Vous allez le vérifier trois fois, en coupant à des moments différents.

## Couper au bon moment

Le téléchargement dure une quinzaine de secondes. Pour couper à un instant
précis, une seule ligne sur la passerelle :

```bash
mosquitto_pub -h 192.168.N0.1 -t cmd/dev01/ota -m "v1.1.0.bin"; sleep 4; sudo systemctl kill -s KILL nginx; echo "--- coupe ---"
```

Puis, pour remettre le service :

```bash
sudo systemctl reset-failed nginx && sudo systemctl start nginx
```

Le `reset-failed` est nécessaire : un `kill -s KILL` laisse l'unité en état
d'échec aux yeux de systemd.

:::note[Pourquoi `kill` et pas `stop` ?]
Essayez d'abord avec `sudo systemctl stop nginx` et mesurez à quel pourcentage
la coupure se produit réellement. Comparez avec `kill -s KILL`. L'écart
s'explique par le comportement de nginx à l'arrêt — trouvez lequel.
:::

## Les trois essais

| Essai | Délai | Coupure attendue vers |
|---|---|---|
| 1 | `sleep 3` | 20 % |
| 2 | `sleep 7` | 50 % |
| 3 | `sleep 13` | 95 % |

Le troisième est le plus intéressant. **L'image est presque complète** — c'est
le cas où un mécanisme mal conçu accepterait un binaire tronqué et rendrait le
device inutilisable.

Pour chaque essai, notez : le pourcentage atteint, le message d'erreur exact,
et surtout — **le device a-t-il redémarré ?** La télémétrie s'est-elle
interrompue ?

## Lire les signatures d'échec

Deux messages différents selon le moment de la panne :

| Message | Moment | Signification |
|---|---|---|
| `esp_https_ota_begin : ESP_ERR_HTTP_CONNECT` | avant tout téléchargement | le serveur est injoignable |
| `telechargement incomplet : ESP_FAIL` | après une progression partielle | la connexion s'est établie puis rompue |

Cette distinction compte en exploitation : « je n'ai jamais atteint le
serveur » et « le serveur m'a lâché en route » appellent des diagnostics
opposés. Le premier pointe vers le service ou le routage, le second vers la
stabilité du lien.

Provoquez les deux délibérément — arrêtez nginx **avant** de publier la
commande pour obtenir le premier.

:::tip[Vérification]
Trois interruptions sur trois : message d'erreur, aucun redémarrage, télémétrie
continue. Et votre tableau distingue les deux signatures d'échec.
:::

## La question qui compte

Dans `ilot_ota.c`, trouvez l'appel qui refuse une image incomplète. Que
vérifie-t-il exactement ?

Puis répondez : **une image tronquée mais syntaxiquement valide passerait-elle ?**
Qu'est-ce qui l'empêche, au-delà de cette seule vérification ? Regardez ce que
le chargeur d'amorçage affiche juste avant le redémarrage lors d'une mise à
jour réussie.

:::info[Objectif bonus]
Plutôt que de couper le serveur, coupez le **lien radio** : éteignez le point
d'accès de la passerelle en pleine mise à jour, ou éloignez brutalement la
carte. Le comportement est-il identique ? Et combien de temps le device
met-il à abandonner ?
:::
