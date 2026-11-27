# Valeurs exactes

Toutes les valeurs sont des points de départ cohérents, pas une loi. Une échelle
assumée et appliquée partout bat une valeur « parfaite » utilisée une fois.

## Espacement

Grille de **4px**. Toute marge, padding, gap et hauteur fixe est un multiple de 4.

```
4  8  12  16  24  32  48  64  96  128
```

- même chose, même taille : toutes les lignes d'une liste partagent hauteur et gap ; toutes les cartes d'une rangée partagent le padding ;
- l'espace à l'intérieur d'un groupe < l'espace entre groupes (ex. 24 au-dessus d'un titre de section, 8 en dessous) ;
- densité : barre latérale et panneaux compacts 12–16, cartes 20–24, bords de page 24–32 (mobile 16–20) ;
- navigation = zone la plus dense : lignes 32–36, gap 2–4, icônes sur une colonne ;
- supprimer les valeurs ponctuelles (`mt-[13px]`, `py-[11px]`).

## Typographie

Base **16px**. Une seule échelle, ratio 1.2 (UI dense), 1.25 (défaut) ou 1.333
(marketing). Exemple à 1.25 : 12 / 14 / 16 / 20 / 25 / 31 / 39 / 49 / 61.

| Rôle | Taille | Interligne | Poids |
|------|--------|-----------|-------|
| Display | clamp(2.5rem, 6vw, 4.5rem) | 1.02–1.1 | 500–700 |
| H1 | clamp(2rem, 4vw, 3rem) | 1.1 | 600 |
| H2 | clamp(1.5rem, 2.5vw, 2rem) | 1.15 | 600 |
| H3 | 1.25rem | 1.25 | 600 |
| Corps | 1rem | 1.5–1.7 | 400 |
| Petit / label | 0.875rem | 1.4 | 400–500 |
| Micro (rare) | 0.75rem | 1.3 | 500 + `letter-spacing: 0.02em` |

- **Longueur de ligne** : 60–72ch pour la prose, jamais plus de 80.
- **Fluide, pas de sauts** : `clamp(min, preferred, max)` sur chaque niveau de titre. Formule : `clamp(1rem, 0.75rem + 1vw, 1.5rem)` couvre ~390→1440px sans media query.
- **Pas de police en dessous de 14px** pour du texte lu ; 12px réservé aux micro-labels.
- `text-wrap: balance` sur les titres, `pretty` sur les paragraphes (support large, dégradation propre).
- `font-variant-numeric: tabular-nums` sur tout chiffre en colonne, compteur ou tableau.
- **Un seul axe de contraste à la fois** : ne pas mélanger taille, graisse, couleur ET majuscules pour dire la même hiérarchie.

## Couleur

Travailler en **OKLCH** : la lumière est perceptuellement uniforme, donc deux
couleurs de même L se lisent comme de même poids, et une rampe se construit en
faisant varier L seul.

```
oklch(L% C H)
```

**Rampe neutre** (surfaces, bordures, texte) : une seule teinte H, C entre 0.005
et 0.02, L de 98 → 20. Le monde du produit donne H (papier ~90, instruments ~250,
terre ~60).

| Rôle | L (thème clair) | L (thème sombre) |
|------|-----------------|------------------|
| Fond | 98–99 | 14–17 |
| Surface surélevée | 100 | 20–23 |
| Bordure | texte à 8 % | texte à 10 % |
| Texte primaire | 20–25 | 95 |
| Texte secondaire | 40–45 | 75 |
| Texte muted | 55–60 | 60 |

- **Un accent, rare** : action principale, sélection, un chiffre. L 55–65, C 0.12–0.20 en clair.
- **Contraste** : texte ≥ 4,5:1 ; grand texte (≥ 24px, ou ≥ 18,7px gras) ≥ 3:1 ; composants d'UI, bordures de champ actif, icônes porteuses de sens ≥ 3:1.
- **Un seul accent ne suffit pas** : ne jamais coder une information par la couleur seule (erreur = couleur + texte + icône).
- **Thème sombre** : la profondeur vient des paliers de surface et des hairlines, pas des ombres. Le bouton primaire peut être un blanc cassé de la rampe, l'accent vivant ailleurs.
- **Dégradé autorisé** uniquement comme variation dans une même teinte (ligne active `#2b2b2b → #1f1f1f`). Jamais d'une teinte à une autre.

## Layout et responsive

- **Points de rupture par défaut** : 640 / 768 / 1024 / 1280. Ce sont des commodités, pas des cibles : on ajoute un breakpoint quand le contenu casse, pas quand le numéro est joli.
- **Container queries** dès qu'un composant peut vivre dans deux largeurs différentes (carte dans une grille pleine et dans une sidebar) : `container-type: inline-size` + `@container (min-width: 400px)`, unités `cqw` / `cqh`.
- **`:has()`** pour les cas dépendants du contenu (`.form:has(input:invalid)`, `.grid:has(img)`), avec repli acceptable.
- **Fluide plutôt que cassures** : `clamp()` sur la typo et les paddings de section.
- **Hauteurs** : `100dvh` (pas `100svh` pour du plein écran mobile), `min-height: 0` sur les enfants de flex qui débordent, `env(safe-area-inset-*)` sur les barres fixes.
- **Images** : `max-width: 100%`, `aspect-ratio` réservé, `loading="lazy"` hors premier écran, `srcset` quand la taille change.
- **Cibles tactiles** ≥ 24×24 px (WCAG 2.5.8), 44×44 recommandé pour les actions principales.
- **Inputs à 16px minimum** sur mobile (sinon zoom iOS).
- **Tableaux** : à 390px, soit colonnes prioritaires, soit vue carte. Pas de scroll horizontal sans indicateur.

## Détails

- **Rayons** : un rayon pour les contrôles (6), un pour les conteneurs (10–12), ou tout à 0. Ne pas mélanger très arrondi et angles vifs dans le même système.
- **Bordures** : 1px, couleur du texte à 6–10 %.
- **Ombres** : 3 niveaux maximum, neutres, courtes (`0 1px 2px`, `0 4px 12px`). Sur fond sombre : aucune ombre, seulement des paliers.
- **Z-index** : une échelle nommée (0 / 10 / 100 / 1000), pas de `z-index: 9999`.
- **États** : hover, active, focus-visible, disabled, chargement — pour chaque contrôle interactif, sans exception.

## Vérification (captures)

Un seul moteur : **chrome-headless-shell** (Chrome for Testing). Rendu Chrome
exact, CDP, pas de Playwright, pas de Chrome système : un moteur qui ne peint pas
`box-shadow`, `filter` et `clip-path` ne peut pas juger un écran.

### Installation (une fois par machine)

```bash
bash scripts/install-browser.sh
# → ~/.local/share/chrome-headless-shell (283 Mo)
# → ~/.local/bin/chrome-headless-shell (wrapper dans le PATH)
```

Sous le capot : `npx @puppeteer/browsers install chrome-headless-shell@158.0.8127.88`.
Épingler la version rend les captures reproductibles. Variables : `CHS_HOME`
(répertoire d'installation), `BIN_DIR` (destination du wrapper). Le script est
idempotent : relancé, il ne retélécharge rien.

### Commandes

```bash
# page entière, 390 / 768 / 1024 / 1440
node scripts/shot.mjs http://localhost:3000 --out .slop/after

# thème sombre et mouvement réduit
node scripts/shot.mjs http://localhost:3000 --out .slop/after --dark --reduced

# premier écran seulement, deux largeurs
node scripts/shot.mjs http://localhost:3000 --out .slop/fold --fold --widths 390,1440

# fichier local
node scripts/shot.mjs ./dist/index.html --out .slop/after

# serveur Chromium déjà lancé (Docker, remote…)
CDP_URL=ws://127.0.0.1:9222/devtools/browser node scripts/shot.mjs http://localhost:3000
```

Options : `--widths`, `--height`, `--fold`, `--dark`, `--reduced`, `--out`,
`--bin`, `--scroll <px>`, `--wait <ms>`, `--cookie nom=valeur`, `--eval <js>`,
`--audit`. Variables : `BROWSER_BIN` (binaire explicite), `CDP_URL` (serveur
existant), `CDP_PORT` (port d'écoute, défaut 9223).

**Thème** : `--dark` n'agit que sur `prefers-color-scheme`. Un site à bascule
manuelle (cookie, `data-theme`, classe `.dark`) se capture avec
`--cookie theme=dark` ou `--eval "document.documentElement.dataset.theme='dark'"`.

**Attendre le client** : sur une SPA qui charge ses données après le `load`,
`--wait 3000` évite de capturer un état vide.

### Audit mécanique

`--audit` mesure ce que l'œil rate, sans jugement esthétique :

| Contrôle | Seuil |
|----------|-------|
| débordement horizontal | 0 px |
| section de contenu trop vide | < 55 % rempli (hors hero/footer) |
| contraste texte | ≥ 4,5:1 (≥ 3:1 pour le grand texte) |
| cible interactive | ≥ 24×24 px (liens inline exclus) |
| image | `alt` présent |
| champ | label, `aria-label` ou `for` |
| scroll imbriqué | signalé avec sa hauteur |
| ancre `#id` | cible existante |

```bash
node scripts/shot.mjs http://localhost:3000 --out .slop/check   --widths 390,768,1024,1440 --audit --wait 3000
```

Sortie : une ligne par problème, préfixée `✗` (à corriger) ou `!` (à décider).
`--json` donne le détail pour un script. L'audit ne juge ni la direction
artistique ni le contenu : c'est un filet, pas un avis.

**Pièges connus**

- Un Chromium lancé à la main refuse le handshake CDP de Node : ajouter
  `--remote-allow-origins=*`. Le script le fait quand il lance le binaire.
- `file://` exige `--allow-file-access-from-files`, ajouté automatiquement.
- Les captures servent à comparer et repérer les erreurs de layout. Ce n'est pas
  un golden pixel-perfect : polices système, couleurs et antialiasing varient
  selon l'OS. Le rendu final se juge dans un vrai navigateur.
- Chromium n'est pas Safari : sur une cible iOS, un contrôle WebKit reste
  nécessaire.

## Sources

- Material Design, *Duration & easing* — courbes `standard` 0.4/0/0.2/1, `deceleration` 0/0/0.2/1, `acceleration` 0.4/0/1/1, `sharp` 0.4/0/0.6/1 : https://m1.material.io/motion/duration-easing.html
- Carbon Design System, *Motion* — productive vs expressive, entrance/exit, durée selon la distance : https://www.carbondesignsystem.com/building-blocks/foundations/motion
- OpenDoor, *Responsive Web Design in 2026* — container queries, `:has()`, `clamp()`, unités `cq` : https://opendoordigital.dev/blog/responsive-web-design-2026
- Figma, *Typography in design* — interligne 1.2–1.45 : https://www.figma.com/resource-library/typography-in-design/
- NN/g, *Errors in forms* — validation inline, message près du champ : https://www.nngroup.com/articles/errors-forms-design-guidelines/
- WCAG 2.2 (contraste 1.4.3 / 1.4.11, cible 2.5.8) : https://www.w3.org/TR/WCAG22/
