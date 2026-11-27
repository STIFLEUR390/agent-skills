---
name: design-motion
description: >
  Conçoit, corrige et vérifie les animations d'interface : durées et courbes
  d'easing, chorégraphie de plusieurs éléments, transitions d'état,
  micro-interactions, entrées de page, listes, modales, respect de
  prefers-reduced-motion, et suppression du motion décoratif qui trahit une UI
  générée. Inclut les valeurs exactes (durées, cubic-bezier), les pièges de
  performance (transform/opacity uniquement), des recettes CSS prêtes à copier et
  la vérification statique dans un Chromium headless. Utiliser quand on ajoute une animation,
  quand un hover ou une entrée « fait cheap », quand une transition saccade, ou
  quand il faut animer un composant sans bibliothèque. Ne pas utiliser pour de la
  vidéo, du motion design 3D/WebGL, ou l'animation d'une maquette marketing.
license: MIT
compatibility: "Claude Code, Codex, OpenCode, Pi, omp"
allowed-tools: Read Write Edit Glob Grep Bash
user-invocable: true
---

# Design motion — du mouvement qui a une cause

Une animation d'interface n'est pas une décoration : c'est une explication. Elle
dit d'où vient un élément, où il va, ce qui a changé, ou ce qui est lié à quoi.
Si tu ne peux pas répondre à « pourquoi ça bouge ? » en une phrase, retire-le.

## Quand utiliser

- ajouter, corriger ou supprimer une animation d'interface ;
- un hover, un menu, une modale ou une entrée de page « fait cheap » ;
- une transition saccade, ou bloque l'utilisateur ;
- animer un composant sans ajouter de bibliothèque.

## Ne pas utiliser

- vidéo, montage, motion design 3D/WebGL ;
- animation de maquette marketing (faux produit, hero illustré) ;
- micro-interaction purement décorative dont personne n'a besoin.

## Les trois questions, avant d'écrire une ligne

1. **Cause** — qu'est-ce qui déclenche ce mouvement ? (chargement, action,
   changement d'état, relation entre deux éléments)
2. **Relation** — qu'est-ce que le spectateur doit comprendre ? (ça vient de là,
   ça remplace ça, ça appartient à ça, ça part pour de bon)
3. **Coût** — est-ce que l'utilisateur attend ce mouvement, ou est-ce qu'il le
   subit ? Un mouvement qui retarde une action est un bug.

Sans réponse aux trois : pas d'animation.

## Durées et courbes

Valeurs par défaut, à ajuster par la distance et la taille de l'élément — plus
c'est gros et loin, plus c'est long.

| Cas | Durée | Courbe |
|-----|-------|--------|
| Press, toggle, micro-feedback | 90–140ms | `--ease-out` |
| Hover, tooltip, chip, focus | 120–180ms | `--ease-out` |
| Dropdown, popover, carte | 180–260ms | `--ease-out` |
| Modale, drawer, section | 240–360ms | `--ease-out` (entrée) / `--ease-in` (sortie) |
| Changement de page | 300–450ms | `--ease-in-out` |
| Ambiance / boucle | 2,5–6s | `--ease-in-out` |

```css
:root {
  --ease-out:     cubic-bezier(0, 0, .2, 1);      /* entrée */
  --ease-in:      cubic-bezier(.4, 0, 1, 1);      /* sortie */
  --ease-in-out:  cubic-bezier(.4, 0, .2, 1);     /* visible du début à la fin */
  --ease-sharp:   cubic-bezier(.4, 0, .6, 1);     /* sortie réversible */
  --ease-spring:  linear(.34, 1.56, .64, 1);      /* rebond léger, à doser */
}
```

- **La sortie est plus rapide que l'entrée** (~60–70 % de sa durée) : partir vite
  signifie « c'est fini ».
- **Jamais `linear`** sur un déplacement : l'œil le lit comme mécanique.
- **Jamais `ease` / `ease-in-out` par défaut** : trop mous, jamais choisis.
- **Asymétrie** : accélération rapide, décélération longue (départ franc, arrivée
  posée). C'est ce qui distingue le mouvement naturel du mouvement généré.

Détail des courbes et de leur origine : `references/motion.md`.

## Chorégraphie

Le mouvement d'un seul élément est facile. Ce qui trahit une UI générée, c'est
tout qui bouge en même temps, à la même vitesse.

- **Une intention par écran.** Un moment mémorable bat cinq animations moyennes.
- **Décalage (stagger)** : 20–40ms entre éléments frères, 5 à 7 éléments maximum.
  Au-delà, tout bouge ensemble.
- **Chevauchement** : la suite démarre avant la fin de la précédente (30–50 %),
  sinon ça fait une file d'attente.
- **Animer la relation, pas seulement l'objet** : une ligne insérée pousse les
  suivantes ; un panneau qui s'ouvre décale le contenu au lieu de le recouvrir
  sans transition.
- **Tenir le résultat** : une fois l'action finie, le résultat reste affiché au
  moins 400ms, sinon le spectateur ne l'a pas vu.
- **Boucle propre** : la fin rejoint le début, ou le reset a une cause visible.
- **Rien ne bouge pendant la lecture** : pas de parallax sur du texte, pas de
  compteur qui tourne à côté d'un paragraphe.

## Performance

Une animation qui fait chuter le framerate est pire que pas d'animation.

- **`transform` et `opacity` uniquement** pour l'animation continue. Ce sont les
  deux propriétés composées par le GPU.
- Jamais `width`, `height`, `top`, `left`, `margin`, `box-shadow` en boucle : ils
  déclenchent layout ou paint à chaque frame.
- `filter` et `clip-path` sont coûteux : réservés aux moments courts.
- `will-change` : sur l'élément qui va bouger, retiré après. Pas sur `*`.
- `transition: all` est interdit : il anime aussi ce que tu n'as pas prévu.
- Pour un changement de layout, **FLIP** (mesurer → transformer → rejouer) plutôt
  qu'animer des propriétés de layout.
- **60fps ou rien** : si un profil montre des frames > 16ms, simplifier.

## Accessibilité (non négociable)

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: .01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: .01ms !important;
    scroll-behavior: auto !important;
  }
}
```

- Le reduced-motion ne supprime pas l'information : garder un fondu court, retirer
  le déplacement, le zoom et le parallax.
- Aucun contenu en mouvement automatique de plus de 5s sans pause (WCAG 2.2.2).
- Pas de flash > 3 fois par seconde.
- Le mouvement ne doit jamais être le seul porteur d'un sens (état, erreur,
  sélection).
- Une animation ne bloque jamais l'input : elle est interruptible.

## Signes de motion « généré »

- tout entre en `opacity 0 → 1` + `translateY(20px)` au scroll, à l'identique ;
- hover de 300ms+ sur un bouton, ou `scale(1.05)` ;
- `transition-all` ;
- boucle infinie de glow / pulse / gradient animé sans cause ;
- parallax sur du texte ;
- curseur personnalisé qui suit la souris ;
- compteurs qui s'incrémentent au scroll ;
- marquee de logos qui défile ;
- shimmer qui balaie un squelette entier ;
- confettis pour une action banale ;
- entrée de page en `scale(0.9)` sur 800ms.

## Recettes

```css
/* Entrée discrète et causée */
.enter { animation: enter .22s var(--ease-out) both; }
@keyframes enter { from { opacity: 0; transform: translateY(8px); } }

/* Sortie plus rapide */
.exit { animation: exit .14s var(--ease-in) both; }
@keyframes exit { to { opacity: 0; transform: translateY(4px); } }

/* Hover : 2px maximum, jamais de saut */
.card { transition: transform .14s var(--ease-out), border-color .14s var(--ease-out); }
.card:hover { transform: translateY(-2px); }

/* Press réel */
.btn:active { transform: scale(.98); transition-duration: 90ms; }

/* Liste décalée, plafonnée */
.item { animation: enter .24s var(--ease-out) both; animation-delay: calc(min(var(--i), 6) * 30ms); }

/* Modale : overlay + panneau, pas tout en même temps */
.overlay { animation: fade .16s var(--ease-out) both; }
.panel   { animation: rise .24s var(--ease-out) both; }

/* Changement de page (progressif) */
@view-transition { navigation: auto; }
```

Pour un changement de layout (réordonnancement, ajout de ligne), préférer FLIP ou
les View Transitions aux animations de `height`.

## Validation

Une capture ne juge pas un mouvement, mais elle juge ce qui reste à l'arrêt :

Utilise le script de capture du skill `anti-slop` (Chromium headless, installé
une fois par `scripts/install-browser.sh`). Une capture ne filme pas, mais elle
juge l'état final et le repli sans mouvement — et le poster doit raconter
l'histoire seul.

```bash
node <chemin>/anti-slop/scripts/shot.mjs http://localhost:3000 --out .motion/after
node <chemin>/anti-slop/scripts/shot.mjs http://localhost:3000 --out .motion/still --reduced
```

Checklist :

- [ ] chaque animation a une cause écrite en une phrase
- [ ] entrée ~200ms, sortie ~140ms, pas de `transition-all`
- [ ] seules `transform` / `opacity` animent en continu
- [ ] reduced-motion testé, information préservée
- [ ] le résultat reste visible après l'action
- [ ] rien ne bouge pendant la lecture d'un texte
- [ ] aucune boucle infinie sans cause

Le mouvement lui-même se juge à l'œil, en ralentissant (DevTools ×0.25) ou en
comparant première et dernière frame. Si tu ne peux pas expliquer le mouvement à
voix haute, il est décoratif.

## Sources

- Material Design, *Duration & easing* : https://m1.material.io/motion/duration-easing.html
- Carbon Design System, *Motion* (productive vs expressive, entrance/exit) : https://www.carbondesignsystem.com/building-blocks/foundations/motion
- Valeurs détaillées et table de durées : `references/motion.md`
