# anti-slop — guide d'installation et d'usage

Skill d'audit et de réparation d'une interface qui « fait IA » : friction d'abord,
véracité, plancher web, puis apparence. Il corrige par passes ordonnées et vérifie
le rendu dans un vrai Chromium, à quatre largeurs.

## Prérequis

| Outil | Version | Pourquoi |
|-------|---------|----------|
| Node.js | 22+ | `shot.mjs` utilise `WebSocket` et `fetch` natifs |
| chrome-headless-shell | 158.0.8127.88 (épinglée) | captures PNG de référence, ~283 Mo |

Aucun Playwright, aucun Chrome système, aucune clé d'API.

## Installation

### 1. Le skill

```bash
# depuis le dépôt (recommandé)
npx skills add STIFLEUR390/agent-skills --skill anti-slop
npx skills add STIFLEUR390/agent-skills --skill design-motion

# ou en local, pour développer
bash skills/skill-creator/scripts/deploy.sh anti-slop
bash skills/skill-creator/scripts/deploy.sh design-motion
```

### 2. Le navigateur (une fois par machine)

```bash
bash skills/anti-slop/scripts/install-browser.sh
```

Sortie attendue :

```
→ Installation de chrome-headless-shell@158.0.8127.88 dans ~/.local/share/chrome-headless-shell
✅ Google Chrome for Testing 158.0.8127.88
```

Le script :

1. télécharge Chrome for Testing via `@puppeteer/browsers` (283 Mo, une fois) ;
2. installe dans `~/.local/share/chrome-headless-shell` ;
3. crée `~/.local/bin/chrome-headless-shell`, un wrapper qui pointe le vrai binaire ;
4. est **idempotent** : relancé, il ne retélécharge rien.

Variables : `CHS_HOME` (répertoire d'installation), `BIN_DIR` (destination du
wrapper). Pour une autre version : `bash install-browser.sh 158.0.8127.88`.

**Sans script**, à la main :

```bash
npx -y @puppeteer/browsers install chrome-headless-shell@158.0.8127.88 \
  --path ~/.local/share/chrome-headless-shell
CHS=$(find ~/.local/share/chrome-headless-shell -name chrome-headless-shell -type f | head -1)
export PATH="$(dirname "$CHS"):$PATH"
```

Vérification :

```bash
chrome-headless-shell --version   # Google Chrome for Testing 158.0.8127.88
```

## Usage

Dans l'agent :

```text
Corrige cette page, elle fait IA
Passe anti-slop sur /dashboard
Ajoute une animation sur ce menu, elle fait cheap
```

Le skill :

1. capture l'écran à 390 / 768 / 1024 / 1440 ;
2. audite friction → véracité → plancher web → esthétique ;
3. propose une direction en 5 lignes et **attend l'accord** ;
4. corrige par 9 passes (espacement, couleur, icônes, copie, typo, layout, détails, états, motion) ;
5. recapture et rend un rapport avec le compte de signes avant/après.

## Commandes du script

```bash
node scripts/shot.mjs <url|fichier> [options]

--out <dir>          répertoire de sortie (défaut .slop/shot)
--widths 390,768     largeurs (défaut 390,768,1024,1440)
--height 900         hauteur du viewport
--fold               premier écran seulement (pas la page entière)
--scroll 1200        capture à cette position de scroll (implique --fold)
--wait 3000          attend le rendu client avant de capturer
--dark               émule prefers-color-scheme: dark
--reduced            émule prefers-reduced-motion: reduce
--cookie theme=dark  pose un cookie avant le chargement (thème, session)
--eval "<js>"        exécute du JS après chargement (ouvrir un menu, figer une animation)
--audit              rapport mécanique : débordement, contraste, cibles, ancres…
--json               audit en JSON
--bin <chemin>       binaire Chromium explicite
```

Variables : `BROWSER_BIN`, `CDP_URL` (serveur Chromium existant),
`CDP_PORT` (port d'écoute, défaut 9223).

### Audit mécanique

```bash
node scripts/shot.mjs http://localhost:3000 --out .slop/check   --widths 390,768,1024,1440 --audit --wait 3000
```

Il vérifie : débordement horizontal, sections sous 55 % de remplissage,
contraste < 4,5:1, cibles < 24 px, images sans `alt`, champs sans label, scroll
imbriqué, ancres `#id` cassées. C'est le filet anti-régression : à lancer avant
et après une passe de design.

### Thème et SPA

`--dark` ne suffit pas si le site stocke son thème dans un cookie ou un attribut.
Utiliser `--cookie theme=dark` (cookie) ou
`--eval "document.documentElement.dataset.theme='dark'"` (attribut). Sur une SPA,
`--wait 3000` laisse le temps aux données d'arriver avant la capture.

## Dépannage

| Symptôme | Cause | Correction |
|----------|-------|------------|
| `Aucun Chromium headless trouvé` | navigateur non installé ou hors PATH | `bash scripts/install-browser.sh` |
| `connexion CDP impossible` | Chromium lancé à la main sans `--remote-allow-origins=*` | relancer avec le flag, ou laisser le script lancer le binaire |
| page vide en `file://` | accès fichiers désactivé | le script ajoute `--allow-file-access-from-files` ; en cas de serveur externe, l'ajouter |
| `Échec: net::ERR_CONNECTION_REFUSED` | serveur de dev non démarré | lancer l'app avant la capture |
| captures différentes d'un collègue | version de navigateur ou OS différent | épingler la même version |

## Portée

- **Web** : landing pages, dashboards, apps, composants, formulaires.
- **Pas couvert** : iOS/Android natif, WebKit/Safari, audit d'accessibilité
  complet (RGAA/WCAG de bout en bout), refonte de marque.

## Compagnon

`design-motion` traite uniquement le mouvement : durées, courbes, chorégraphie,
`prefers-reduced-motion`, et les signes de motion généré. Il réutilise
`scripts/shot.mjs` du skill `anti-slop`.

## Sources

- Tundra AI Labs, *Anti-AI UI Guide* : https://tundraailabs.com/ui-guide
- erK Yaman, *unslop-anything* — étude de 5 008 684 avis, ordre friction →
  véracité → plancher web : https://github.com/erkamyaman/unslop-anything
- Material Design, *Duration & easing* : https://m1.material.io/motion/duration-easing.html
- Carbon Design System, *Motion* : https://www.carbondesignsystem.com/building-blocks/foundations/motion
- WCAG 2.2 : https://www.w3.org/TR/WCAG22/
