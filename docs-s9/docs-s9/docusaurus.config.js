// @ts-check
const { themes: prismThemes } = require('prism-react-renderer');

// Build public (Vercel) : la section enseignant n'est pas compilee.
// Elle reste accessible en local avec  npm start  ou  npm run build.
const PUBLIC_BUILD = process.env.PUBLIC_BUILD === '1';

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'IoT Systems Deployment & Operations',
  tagline: 'Déployer et maintenir un système IoT réel, à l\u2019échelle',
  favicon: 'img/favicon.ico',

  // Adapter au domaine Vercel une fois le projet créé.
  url: 'https://iot-s9.vercel.app',
  baseUrl: '/',

  onBrokenLinks: 'warn',
  onBrokenMarkdownLinks: 'warn',

  // Support de cours : aucune raison d'apparaitre dans les moteurs de
  // recherche. Emet une balise noindex sur toutes les pages.
  noIndex: true,

  i18n: {
    defaultLocale: 'fr',
    locales: ['fr'],
  },

  markdown: {
    mermaid: true,
  },
  themes: ['@docusaurus/theme-mermaid'],

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          sidebarPath: require.resolve('./sidebars.js'),
          routeBasePath: '/',
          // Les corriges ne sont pas compiles dans le build public : ce qui
          // n'existe pas sur le serveur ne peut pas fuiter.
          exclude: PUBLIC_BUILD ? ['enseignant/**'] : [],
          // Décommenter une fois le dépôt en ligne : ajoute un lien
          // « Modifier cette page » sur chaque page, utile quand un binôme
          // repère une erreur en séance.
          // editUrl: 'https://github.com/<compte>/<depot>/tree/main/docs-s9/',
        },
        blog: false,
        theme: {
          customCss: require.resolve('./src/css/custom.css'),
        },
      }),
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      colorMode: {
        defaultMode: 'light',
        respectPrefersColorScheme: true,
      },
      navbar: {
        title: 'IoT S9',
        items: [
          {
            type: 'docSidebar',
            sidebarId: 'tpSidebar',
            position: 'left',
            label: 'Travaux pratiques',
          },
          ...(PUBLIC_BUILD
            ? []
            : [
                {
                  type: 'docSidebar',
                  sidebarId: 'enseignantSidebar',
                  position: 'left',
                  label: 'Enseignant',
                },
              ]),
        ],
      },
      footer: {
        style: 'light',
        copyright:
          'IoT Systems Deployment & Operations — S9. Miroir local disponible sur la passerelle de votre îlot : http://192.168.N0.1:8080/docs',
      },
      prism: {
        theme: prismThemes.github,
        darkTheme: prismThemes.dracula,
        additionalLanguages: ['bash', 'powershell', 'ini', 'toml', 'json'],
      },
      tableOfContents: {
        minHeadingLevel: 2,
        maxHeadingLevel: 3,
      },
    }),
};

module.exports = config;
