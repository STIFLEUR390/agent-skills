# Signes de slop et corrections

Une ligne = un signe repérable + sa correction. Si un signe est un choix
assumé et cohérent avec le reste, il n'est pas un problème : c'est le test.

L'ordre suit ce qui fait partir les utilisateurs : friction, véracité, plancher
web, puis apparence.

## Friction

Ce qui coûte des gestes, surprend, ou bloque. Passe cette liste avant de regarder
les couleurs.

- **Contrôle fréquent déplacé ou enterré** dans les réglages → le remettre là où la tâche se fait.
- **Geste familier détourné** (swipe, clic droit, Échap) → respecter la convention de la plateforme.
- **Tâche courante à plusieurs écrans** alors qu'elle tenait sur un → réduire le chemin.
- **Fonction IA qui intercepte le cœur de la tâche** (bouton sparkle à la place de la recherche, panneau non fermable) → la déplacer hors du chemin principal, toujours fermable.
- **Pub, promo, demande de note ou popup pendant une tâche** → supprimer ou déplacer après la tâche.
- **Icône d'upsell ou destructive collée à une cible fréquente** → séparer.
- **Action principale hors de portée du pouce** sur mobile → la descendre.
- **Contrôle qui a l'air actif mais ne fait rien**, répond tard, ou déclenche le mauvais élément → corriger ou retirer.
- **Cible coupée, recouverte ou inatteignable** à certaines largeurs → tester 320, 390, 768.
- **États lu/non lu, actif/selectionné indistinguables**, surtout en sombre → doubler le contraste ou ajouter une forme.
- **Écran mangé par le padding ou le chrome** → réduire la décoration, garder le contenu.

## Véracité

L'écran affirme quelque chose de faux. C'est le signe le plus coûteux en confiance.

- **Échec de chargement affiché comme vide** (« Aucune commande » alors que la requête a échoué) → état d'erreur distinct avec reprise.
- **Total calculé sur une seule page** de résultats → pagination ou total serveur.
- **Liste « récente » qui ne l'est pas**, données « live » mises en cache → dater, ou rafraîchir.
- **Bouton qui mène ailleurs que ce que dit son libellé** → aligner le libellé et la destination.
- **Chiffre inventé ou placeholder** dans une tuile de stats → donnée réelle, ou masquer la tuile.
- **Preuve sociale et promesses de vitesse non fournies** (« +10 000 équipes », « 10× plus rapide ») → un chiffre vérifié, sinon retirer.
- **Promesse de confidentialité contredite par le code** (tracker, SDK pub) → corriger la promesse ou le code.
- **Logo approximatif ou faux** → vrai logo autorisé, sinon retirer.

## Plancher web

Ces points cassent le web pour de vraies personnes, quel que soit le look. Ils ne
se discutent pas.

- **Contrôles réels** : action = `<button>`, navigation = `<a href>`. Un `div` cliquable est invisible au clavier et pour un lecteur d'écran → le remplacer.
- **Focus visible** sur chaque élément interactif, dans la palette, immédiat. `outline: none` sans remplacement exclut les utilisateurs clavier.
- **Zoom autorisé** : pas de `maximum-scale=1` ni `user-scalable=no` ; inputs à 16px minimum sur iOS.
- **Alternatives textuelles** : toute image de contenu a un `alt` (y compris `<Image>`, `<NuxtImg>`, `<v-img>`) ; la décoration a `alt=""`.
- **URL et bouton retour** : les filtres, onglets, recherche et pagination qui comptent vont dans l'URL ; le retour ramène à la vue précédente.
- **Formulaire** : `label` associé, `autocomplete`, type de clavier correct, erreur annoncée (`aria-invalid`, `aria-describedby`).

## Layout et structure

- **Grille de 3–4 cartes identiques** (icône, sous-titre, deux lignes) → un tableau, une liste, de la prose, ou une composition asymétrique assumée.
- **Séquence template** hero → logos → features → 3 étapes → témoignages → 3 prix → FAQ → bandeau CTA → footer → renomme et réordonne selon le produit, supprime les sections inutiles.
- **Section qui ne change rien si on la supprime** → la supprimer.
- **Pill d'annonce au-dessus du h1** (« ✨ Now in public beta ») → la retirer ou l'intégrer comme information réelle, ailleurs.
- **Kicker majuscule espacé au-dessus de chaque section** → un vrai titre, de la prose, ou rien.
- **Répétition kicker + gros titre + 2 lignes** section après section → varier la forme : une section en prose, une en tableau, une avec une image pleine largeur.
- **Chaque idée devient une section** → garder les idées qui portent une décision, mettre le reste en phrase.
- **Hero qui promet autre chose que le corps** → aligner le titre sur ce que les sections montrent vraiment.
- **Bords gauches et droits inégaux** entre sections → une seule colonne de contenu, mêmes marges.
- **Hauteur de section qui laisse un autre titre dépasser** dans le premier écran → une idée par écran, la suivante commence après.
- **Contenu collé en haut avec un grand vide en bas** → répartir ou réduire la hauteur du conteneur.
- **Tout centré** (titres, paragraphes, cartes, boutons) → aligner à gauche ce qui se lit, centrer seulement ce qui se contemple.
- **Section à hauteur d'écran forcée** (`height: calc(2 * 100svh)`) → `min-height` + padding : une hauteur fixe crée des bandes vides quand le contenu est court et coupe quand il est long (traduction, données réelles). Mesurer avec `--audit` : une section sous 55 % de remplissage est suspecte.
- **Scroll imbriqué sans indice** dans une page déjà longue (liste de résultats, code, tableau) → plafonner la zone (`max-height`) et rendre le défilement évident, ou laisser la page défiler.

## Couleur

- **Gradient violet → bleu** en fond, en bouton ou en texte → une teinte plate, ou une rampe neutre teintée vers le monde du produit.
- **Halo / glow coloré** derrière un élément → le supprimer ; la profondeur vient des paliers de surface.
- **Texte en gradient** → couleur unie contrastée.
- **Plus de 3 rôles de texte** (primaire, secondaire, muted) → en garder 3.
- **Accent utilisé partout** (liens, bordures, icônes, badges, titres) → l'accent ne marque que l'action principale, la sélection, ou le chiffre qui compte.
- **Surface de dashboard teintée** (fond orange, bleu, vert) → neutre ; la couleur vit dans l'accent, les charts et les moments.
- **Vert/rouge décoratifs** → le sémantique ne sert qu'au sens.
- **Bordure plus foncée que 10 % du texte** → hairline à 6–10 %.
- **Ombre colorée ou `shadow-2xl`** → ombre neutre, courte ; sur fond sombre, paliers de surface.

## Typographie

- **Inter par défaut partout** → une police choisie pour le produit, ou Inter assumé avec une vraie échelle et des poids utiles.
- **Titres énormes sans hiérarchie** (h1 72px, h2 64px) → une échelle qui descend franchement.
- **Corps < 16px** sur mobile → 16px minimum (évite aussi le zoom iOS sur les inputs).
- **Longueur de ligne > 80 caractères** → 60–72ch.
- **Interlignage 1.1 sur du paragraphe** → 1.5–1.7 ; les titres courts peuvent descendre à 1.1–1.2.
- **Tout en majuscules avec letter-spacing** → réserver aux micro-labels, jamais aux titres.
- **Chiffres qui bougent** dans une colonne ou un compteur → `font-variant-numeric: tabular-nums`.
- **Italique décoratif dans un titre** (« The *better* way ») → un mot qui porte du sens, pas un ornement.

## Icônes et imagerie

- **Emoji comme icône** → une famille unique (celle du projet, sinon lucide), taille et épaisseur uniques.
- **Icône dans une tuile arrondie colorée** au-dessus de chaque titre → supprimer l'icône ou l'aligner avec le texte.
- **Icônes de tailles et d'épaisseurs mélangées** → 16 ou 18px, stroke 1.5, boîte de largeur fixe.
- **Icônes multicolores décoratives** → couleur du rôle de texte.
- **Illustration vectorielle générique** (personnages sans visage, blobs) → une photo réelle, un vrai screenshot produit, ou rien.
- **Screenshot produit inventé** (dashboard flou, chiffres ronds) → du contenu plausible et daté, ou une capture réelle.
- **Logo client inventé ou marquee de logos flous** → de vrais logos autorisés, sinon retirer la section.
- **Avatar générique répété** (même silhouette, mêmes couleurs) → varier ou retirer.

## Copie

- **Vocabulaire IA** : supercharge, seamless, unlock, elevate, empower, révolutionnaire, game-changing, « propulsé par l'IA » → le verbe concret de l'action.
- **Slogan isolé** (« Built differently. ») entre deux sections → le supprimer ou l'expliquer.
- **Question rhétorique en hero** (« Et si votre outil comprenait enfin… ? ») → répondre au lieu de demander.
- **Faux insight** (« The future of X is already here ») → un fait vérifiable.
- **Titre en fragments de 3–6 mots** sur toute la page → des phrases quand il y a quelque chose à dire.
- **Paires de CTA génériques** (« Get Started » + « Learn More ») → nommer l'action réelle : « Réserver une chambre », « Voir le tarif 2027 ».
- **Badges PRO / New / Beta** sans fonction → supprimer.
- **« Loved by 10 000+ teams »** non vérifiable → un chiffre réel confirmé, sinon retirer.
- **Données de démo** (`[X]`, `123 456`, `Lorem ipsum`) → des valeurs plausibles et cohérentes.
- **Exclamations, points d'exclamation multiples, salutations** (« Welcome back, Sam! 👋 ») → nommer le contexte (« Octobre 2026 »).
- **Titres, labels et boutons terminés par un point** → pas de point ; les phrases gardent le leur.

## États et interaction

- **Aucun état vide** (tableau vide = écran blanc) → phrase, action, et à quoi ça ressemblera.
- **Spinner seul sur une page entière** → squelette à la géométrie du contenu.
- **Erreur en toast global** pour un champ → message sous le champ, qui dit quoi corriger.
- **Bouton désactivé sans explication** → dire pourquoi, ou activer et valider.
- **Focus supprimé** (`outline: none`) → anneau visible, contraste ≥ 3:1.
- **Hover sans état pressé** → `:active` réel, pas seulement un `scale`.
- **Champ obligatoire découvert à la soumission** → marquer avant, ou valider au blur.
- **Cible cliquable < 24×24 px** → agrandir la zone, pas seulement l'icône.

## Motion

Voir le skill `design-motion`. Signes rapides :

- tout entre en `fade + translateY(20px)` au scroll, à l'identique ;
- `transition-all` ;
- hover de 300ms+ sur un bouton ;
- parallax sur du texte ;
- animation en boucle infinie sans cause ;
- `prefers-reduced-motion` ignoré.

## Responsive

- **Débordement horizontal** à 390px (une seule section suffit) → corriger la cause : largeur fixe, `100vw`, grille rigide, image sans `max-width`.
- **Trois colonnes écrasées** en une à 390px sans repenser la hiérarchie → redesign de la section, pas un `grid-cols-1`.
- **Texte coupé ou tronqué** dans un bouton ou une carte → laisser le texte dicter la taille, tester les libellés les plus longs.
- **Menu mobile = menu desktop caché** → navigation mobile pensée (cibles, ordre, fermeture).
- **Hauteur `100vh` sur mobile** → `100dvh` + `env(safe-area-inset-*)`.
- **Tableau qui scroll horizontalement sans affordance** → colonnes prioritaires, ou vue carte.

## Sources

- Tundra AI Labs, *Anti-AI UI Guide* : https://tundraailabs.com/ui-guide
- erK Yaman, *unslop-anything* (MIT) — ordre friction → véracité → plancher web,
  et l'étude de 5 008 684 avis d'applications : https://github.com/erkamyaman/unslop-anything
