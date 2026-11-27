# Motion — valeurs et règles détaillées

## Courbes, avec leur origine

| Token | CSS | Usage | Source |
|-------|-----|-------|--------|
| `--ease-out` | `cubic-bezier(0, 0, .2, 1)` | entrée, apparition | Material *deceleration* |
| `--ease-in` | `cubic-bezier(.4, 0, 1, 1)` | sortie définitive | Material *acceleration* |
| `--ease-in-out` | `cubic-bezier(.4, 0, .2, 1)` | élément visible du début à la fin | Material *standard* |
| `--ease-sharp` | `cubic-bezier(.4, 0, .6, 1)` | sortie réversible (panneau latéral) | Material *sharp* |
| `--ease-productive` | `cubic-bezier(.2, 0, .38, .9)` | micro-interaction d'app | Carbon *productive standard* |
| `--ease-expressive` | `cubic-bezier(.4, .14, .3, 1)` | moment marquant | Carbon *expressive standard* |
| `--ease-exit` | `cubic-bezier(.2, 0, 1, .9)` | fermeture de modale/toast | Carbon *productive exit* |
| `--ease-spring` | `linear(.34, 1.56, .64, 1)` | rebond léger (drag, toggle) | approximation spring |

Règles :

- une entrée utilise une courbe qui **décélère** ; une sortie, une qui **accélère** ;
- si l'élément reste à proximité (panneau, drawer), il décélère en sortant : il
  « se pose juste hors champ », il ne part pas ;
- les courbes se déclarent en variables, jamais en dur dans un composant.

## Durées

La durée suit la **distance et la taille**, pas l'envie.

| Amplitude | Exemple | Durée |
|-----------|---------|-------|
| 0–4px, opacité seule | hover, focus, press | 90–140ms |
| 8–16px | tooltip, chip, badge | 120–180ms |
| 16–40px | dropdown, popover, carte, ligne | 180–260ms |
| 40–120px | modale, drawer, section | 240–360ms |
| écran entier | changement de page | 300–450ms |

Repères complémentaires :

- au-delà de **400ms**, l'utilisateur perçoit une attente : réserver aux moments
  rares et justifiés ;
- en dessous de **80ms**, le mouvement est invisible : autant le supprimer ;
- **sortie = 60–70 % de l'entrée** ;
- une boucle d'ambiance dure 2,5–6s et ne doit jamais attirer l'œil plus que le
  contenu.

## Chorégraphie, en chiffres

- **Stagger** : 20–40ms. En dessous, un seul bloc ; au-dessus, une file d'attente.
- **Nombre d'éléments décalés** : 5 à 7. Au-delà, grouper.
- **Chevauchement** : la seconde animation commence à 30–50 % de la première.
- **Hold** : 400ms minimum après l'arrivée du résultat.
- **Boucle** : la dernière frame doit pouvoir être suivie de la première sans
  saut visible ; sinon, reset avec une cause (curseur qui repart, page qui
  recharge).
- **Une seule chose à la fois à l'écran** : si deux animations se disputent
  l'attention, l'une des deux est décorative.

## Entrées et sorties

| Élément | Entrée | Sortie |
|---------|--------|--------|
| Tooltip | fade + 4px, 120ms | fade, 90ms |
| Dropdown / popover | fade + 8px + scale .98, 180ms | fade + 4px, 120ms |
| Modale | overlay fade 150ms, panneau fade + 12px 240ms | 150ms, sans déplacement |
| Drawer | 280ms `--ease-out`, contenu en décalage 40ms | 200ms `--ease-in` |
| Toast | fade + 8px, 200ms | 140ms, ou sortie par glissement |
| Ligne de tableau insérée | hauteur + fade, 220ms, les suivantes poussées | 140ms |
| Changement de vue | cross-fade 220ms, ou View Transition | — |

## Interruption

- Une animation d'entrée doit pouvoir être annulée par une sortie immédiate
  (l'utilisateur ferme avant la fin) : utiliser `animation-fill-mode: both` et
  remplacer l'animation, pas l'empiler.
- Un drag suit le doigt ou le pointeur **sans easing** pendant le geste ; l'easing
  ne s'applique qu'au relâchement (snap).
- Un hover répété ne doit pas relancer une animation depuis zéro à chaque
  passage : la transition CSS s'en charge, pas une `animation` à chaque `mouseenter`.

## Scroll et page

- **Scroll-driven animations** (`animation-timeline: view()`), avec repli statique
  pour les navigateurs sans support. Réservées à la révélation de contenu, jamais
  au parallax de texte.
- **Aucune animation au scroll sur le contenu déjà lu** au-dessus de la ligne de
  flottaison.
- Le contenu ne doit pas être invisible avant son animation (pas de `opacity: 0`
  par défaut sans garantie que l'animation part) : c'est le bug classique du
  texte qui ne s'affiche jamais si JS ou IntersectionObserver échoue.
- Une entrée de page dure 300–450ms maximum ; au-delà, l'utilisateur attend.

## Réduire le mouvement

Deux niveaux, à combiner :

```css
@media (prefers-reduced-motion: reduce) {
  .decorative { display: none; }              /* pur ornement */
  .functional { transition-duration: .01ms; } /* feedback conservé autrement */
}
```

- Remplacer le déplacement par un fondu court garde le feedback sans provoquer de
  vertige.
- Supprimer : parallax, zoom, rotation, secousses, scroll animé.
- Conserver : changement de couleur, apparition, position finale.
- Tester avec la capture `--reduced` : l'écran doit rester complet et lisible.

## Checklist par composant

- **Bouton** : hover 120ms, press 90ms sur `transform`, focus visible immédiat, pas d'animation au chargement.
- **Champ** : focus sur la bordure, erreur sans secousse, pas d'animation de la valeur.
- **Modale** : focus piégé, overlay cliquable, sortie plus rapide que l'entrée, focus rendu au déclencheur.
- **Liste** : stagger plafonné, réordonnancement FLIP, pas de re-animation à chaque rendu.
- **Chargement** : squelette statique ou pulsation lente (1,5s+), jamais de shimmer sur tout l'écran.
- **Notification** : entrée discrète, sortie rapide, jamais de mouvement qui bloque un clic.

## Sources

- Material Design, *Duration & easing* — courbes standard/deceleration/acceleration/sharp : https://m1.material.io/motion/duration-easing.html
- Carbon Design System, *Motion* — productive vs expressive, entrance/exit, durée selon la distance : https://www.carbondesignsystem.com/building-blocks/foundations/motion
- WCAG 2.2 — 2.2.2 (pause/stop/hide), 2.3.1 (flashs) : https://www.w3.org/TR/WCAG22/
