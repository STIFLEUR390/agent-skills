---
name: anti-slop
description: >
  Révise et répare une interface qui a l'air générée par une IA : gradients
  violets, halos, emojis en guise d'icônes, cartes identiques empilées,
  espacements irréguliers, textes creux, états manquants. Applique un audit des
  signes de slop, fixe une direction tirée du produit, corrige par passes
  ordonnées (espacement, couleur, icônes, copie, typo, layout, détails, états,
  motion) et vérifie le rendu aux largeurs 390/768/1024/1440 dans un Chromium headless.
  Utiliser quand une page « fait IA », « fait template », « vibecodé », quand on
  demande un polish, une revue UI, une correction responsive, ou quand un écran
  est propre mais sans caractère. Ne pas utiliser pour du backend, du SEO, ou du
  design sans code.
license: MIT
compatibility: "Claude Code, Codex, OpenCode, Pi, omp"
allowed-tools: Read Write Edit Glob Grep Bash
user-invocable: true
---

# Anti-slop — réparer une interface qui sent l'IA

Tu es un designer qui fait une passe de correction sur un écran existant. Les
fonctionnalités, le contenu et l'ordre des sections restent. Ce que tu changes :
chaque taille, couleur, mot et espace devient un choix.

**Le principe unique : un site généré l'est parce que personne n'a rien choisi.**
Chaque défaut laissé debout est un choix non fait. Le même pattern avec une
décision derrière (palette hors défaut, traitement custom, cohérence avec le
reste) redevient du craft.

## Quand utiliser

- « ça fait IA », « ça fait template », « vibecodé » sur une interface ;
- polish, revue UI, correction responsive avant livraison ;
- un écran est propre mais sans caractère, ou riche mais illisible.

## Ne pas utiliser

- refonte de marque sans code, branding, logo ;
- audit d'accessibilité pur (skill dédié) ;
- backend, SEO, contenu sans interface.

## Règle dure avant d'écrire

1. **Regarde le rendu.** Un jugement sur le code seul rate 80 % des problèmes
   visuels. Capture avant de toucher quoi que ce soit.
2. **Ne change pas le contenu.** Pas de chiffre, de logo, de témoignage ou de
   prix inventé. Si une donnée manque, laisse un placeholder explicite et
   signale-le dans le rapport.
3. **Ne casse pas la fonction.** Ne supprime ni champ, ni action, ni lien. Si un
   élément doit disparaître, demande.

## Étape 0 — Capturer

Une fois par machine, installer le navigateur (283 Mo, sans Google Chrome) :

```bash
bash scripts/install-browser.sh
```

Puis, avant de toucher quoi que ce soit :

```bash
node scripts/shot.mjs http://localhost:3000 --out .slop/before
```

Quatre largeurs (390, 768, 1024, 1440), page entière, dans un vrai Chromium.
Options utiles : `--dark`, `--reduced`, `--fold`, `--widths 390,1440`.
Regarde les quatre images. Note ce qui casse, pas ce qui te déplaît.

## Étape 1 — Auditer

**L'ordre suit ce qui fait partir les utilisateurs, pas ce qui se voit le
mieux.** Sur 5 millions d'avis d'applications, la stabilité et les bugs pèsent
~40 % des plaintes, la friction d'usage ~25 %, le prix et les interruptions ~20 %,
et l'esthétique ne vient qu'après. Un gradient violet ne fait quitter personne ;
un bouton déplacé, une erreur affichée comme « aucun résultat » et une modale au
milieu d'une tâche, si.

Audite donc dans cet ordre :

1. **Friction** — chemins, navigation, contrôles, cibles tactiles, ce qui coûte
   des étapes ou surprend.
2. **Véracité** — ce que l'écran affirme sans que ce soit vrai.
3. **Plancher web** — contrôles réels, focus, zoom, alt, URL et bouton retour.
4. **Esthétique** — les signes visuels.

Passe `references/signs.md` et liste **chaque** signe trouvé, une ligne par
signe, avec l'endroit. Pas de correction à cette étape.

Puis classe honnêtement :

- **Slop lourd** : signes dans plusieurs familles (couleur, typo, icônes, copie)
  ou friction réelle sur une tâche courante → processus complet ci-dessous.
- **Slop léger** : écran globalement conçu, quelques signes → mode polish : ne
  corrige que ce que l'audit a trouvé, garde la palette, la typo et le layout.
- **Pas de slop** : dis-le, propose deux ou trois raffinements avec des valeurs
  exactes, et arrête. Ne change pas un bon écran pour le plaisir de changer.

## Étape 2 — Direction (5 lignes, avant tout code)

Tirées du produit, jamais de la tendance. Les mots `clean`, `modern`, `sleek`,
`minimal`, `premium` sont interdits : ils décrivent tous les templates.

- **Produit** : ce qu'il fait, pour qui, en une phrase.
- **Caractère** : deux ou trois mots concrets (`calme, précis, un peu chaud`).
- **Monde** : le lieu ou la matière naturelle du produit (papier et encre,
  instruments et veille de nuit, cartes et lumière de fenêtre).
- **Moments** : un ou deux endroits où l'écran devient riche.
- **Signature** : un détail que seul ce produit aurait, utilisé partout.

Montre l'audit et les cinq lignes, puis **attends l'accord** avant d'éditer :
changer de direction après coup revient à tout refaire. Sauf si l'utilisateur a
déjà dit « fais-le ».

## Étape 3 — Corriger par passes

Une passe finie sur tout l'écran avant la suivante. L'ordre n'est pas
négociable : l'espacement d'abord, parce que tout le reste se lit différemment
une fois le rythme juste.

| # | Passe | Ce qui se décide |
|---|-------|------------------|
| 1 | Espacement | grille 4px, hauteurs et gaps identiques, densité par contexte |
| 2 | Couleur | une rampe neutre teintée, 3 rôles de texte, un accent rare |
| 3 | Icônes | une seule famille, une taille, une épaisseur, boîte alignée |
| 4 | Copie | titres qui disent le produit, verbes+objets, zéro hype |
| 5 | Typo | une échelle, une longueur de ligne, des poids utiles |
| 6 | Layout | une idée par section, bords égaux, hiérarchie lisible |
| 7 | Détails | bordures, rayons, ombres, alignements, densité |
| 8 | États | vide, chargement, erreur, succès, focus, désactivé |
| 9 | Motion | seulement ce qui a une cause (voir skill `design-motion`) |

Valeurs exactes, échelles et formules : `references/values.md`.
États et formulaires : `references/states.md`.

**Interdits absolus** (un seul suffit à trahir) :

- gradient de teinte sur une surface, texte en gradient, halo coloré, ombre colorée ;
- emoji comme icône ou dans un label ;
- `✨ New`, `Beta 🚀`, pill d'annonce au-dessus du h1 ;
- grille de 3–4 cartes identiques icône + sous-titre + deux lignes ;
- kicker majuscule espacé au-dessus de chaque section ;
- séquence hero → logos → features → 3 étapes → témoignages → 3 prix → FAQ → CTA ;
- bordure `rounded-full` sur des chips partout, `shadow-xl` sur tout ;
- hover qui soulève de 8px, entrée de page en `scale(0.9)` sur 800ms ;
- `transition-all`.

## Validation (étape 4)

```bash
node scripts/shot.mjs http://localhost:3000 --out .slop/after
```

Compare aux captures d'avant, largeur par largeur. Ce qui reste de la liste de
l'audit se corrige. Trois rendus maximum : corrige tout ce qu'une image montre
avant de recapturer.

### Non-régression

Un écran plus beau qui casse une fonction est un échec. Après toute modification
de layout :

```bash
node scripts/shot.mjs http://localhost:3000 --out .slop/check --widths 390,768,1024,1440 --audit
```

Le rapport d'audit vérifie : débordement horizontal, sections trop vides,
contraste, cibles < 24 px, images sans `alt`, champs sans label, scroll imbriqué,
ancres cassées. Corrige tout `✗` avant de livrer.

À la main, en plus :

- chaque `href="#…"` trouve encore son ancre, chaque route interne répond ;
- chaque contrôle garde son libellé, son action et son état (rien de supprimé) ;
- teste **les autres langues** : c'est là que les hauteurs fixes et les libellés
  longs cassent ;
- les données affichées restent réelles (pas de chiffre inventé pour faire joli).

Checklist de sortie :

- [ ] aucun signe de `references/signs.md` restant, ou justifié
- [ ] 390 / 768 / 1024 / 1440 sans débordement horizontal ni texte coupé
- [ ] navigation : bouton retour et URL cohérents, aucun contrôle mort
- [ ] états vide, chargement, erreur et succès présents et distincts
- [ ] boutons = `<button>`, liens = `<a href>`, zoom autorisé, images avec `alt`
- [ ] contraste texte ≥ 4,5:1, éléments d'UI ≥ 3:1, cibles ≥ 24×24 px
- [ ] focus visible au clavier, `prefers-reduced-motion` respecté
- [ ] les 5 lignes de direction sont visibles dans le résultat
- [ ] aucun contenu, chiffre ou visuel inventé

## Étape 5 — Rapport

Trois blocs, courts : la direction retenue, ce qui a changé passe par passe, ce
qui reste ouvert (données manquantes, décisions à valider). Donne le compte de
signes avant / après : c'est la seule mesure honnête du progrès. Dis clairement
que le résultat est un écran en code à remettre à qui possède le vrai site.

## Sources

- Tundra AI Labs, *Anti-AI UI Guide* — https://tundraailabs.com/ui-guide
- `references/values.md` (typo, couleur, responsive, vérification)
- `references/signs.md` (les signes et leurs corrections)
