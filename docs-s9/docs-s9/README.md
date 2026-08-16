# Support de TP — IoT Systems Deployment & Operations (S9)

Site de documentation Docusaurus. Le chantier 0 est rédigé et sert de gabarit
pour les cinq suivants.

## Lancer en local

```bash
npm install
npm start
```

Le site s'ouvre sur http://localhost:3000 avec rechargement à chaud.

## Structure

```
docs/
├── intro.md                     page d'accueil, conventions, plan d'adressage
├── chantiers/
│   └── chantier-0/
│       ├── objectifs.md         objectifs, livrables, déroulé
│       ├── avant-la-seance.md   prérequis à faire chez soi
│       ├── liaison.md           étape 1
│       ├── supervision.md       étape 2
│       ├── passerelle.md        étape 3
│       ├── validation.md        étape 4
│       └── pieges.md            dépannage
└── enseignant/
    └── runbook.md               corrigés, pièges, grille d'évaluation
```

## Le gabarit d'un chantier

Chaque chantier suit la même trame, et c'est ce qui le rend réplicable :

1. **Objectifs et livrables** — durée, compétences visées, ce qui est rendu
2. **Étapes numérotées** — une page par étape, 10 à 20 minutes chacune
3. **Une vérification par étape** — encart `:::tip[Vérification]`, une commande
   qui répond vert ou rouge
4. **Objectifs bonus** — encart `:::info[Objectif bonus]`, pour ceux qui
   terminent en avance
5. **Pièges connus** — page de dépannage alimentée après chaque séance

Les encarts `:::danger` sont réservés aux actions irréversibles ou aux erreurs
qui coûtent une séance.

## Déploiement Vercel

Vercel détecte Docusaurus automatiquement. Le fichier `vercel.json` force la
variable `PUBLIC_BUILD=1`, qui **exclut `docs/enseignant/` du build**.

```json
{
  "buildCommand": "PUBLIC_BUILD=1 npm run build"
}
```

Les corrigés ne sont donc pas compilés, pas envoyés, pas servis. C'est plus
robuste qu'un mot de passe partagé avec vingt étudiants — et gratuit, alors que
la protection par mot de passe de Vercel exige l'add-on Advanced Deployment
Protection à 150 $/mois sur un plan Pro.

Le site porte par ailleurs `noIndex: true` : il n'apparaîtra pas dans les
moteurs de recherche.

Pour consulter la section enseignant, travaillez en local — `npm start` ou
`npm run build` sans la variable la compilent normalement.

Vérifier avant de publier :

```bash
PUBLIC_BUILD=1 npm run build
ls build/enseignant        # doit répondre : aucun fichier
```

Une fois le dépôt en ligne, décommentez `editUrl` dans la configuration : un
lien « Modifier cette page » apparaît sur chaque page, utile quand un binôme
repère une erreur en séance.

## Miroir local sur les passerelles

La salle n'a pas d'accès Internet garanti. Chaque passerelle sert sa propre
copie du support, via le nginx déjà en place.

```bash
npm run build
scp -r build/ isen-iot@10.10.N.1:/tmp/docs
```

Puis sur la passerelle :

```bash
sudo mv /tmp/docs /srv/firmware/docs
```

Le support devient accessible sur `http://192.168.N0.1:8080/docs` pour tout
appareil connecté au réseau de l'îlot.

À refaire à chaque modification du support avant une séance. Le mieux est de
l'intégrer à la préparation des cartes SD, juste avant le clonage.
