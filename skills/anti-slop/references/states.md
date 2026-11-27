# États et formulaires

Un écran n'est pas fini quand le cas nominal est beau, mais quand les cas
dégradés le sont aussi. Chaque état manquant est un signe de slop visible dès
la première utilisation réelle.

## Les six états à couvrir

| État | Ce que l'utilisateur doit comprendre | Ce qu'on affiche |
|------|--------------------------------------|------------------|
| **Vide** | pourquoi c'est vide, quoi faire | une phrase concrète + l'action primaire + un aperçu du résultat |
| **Chargement** | que ça arrive, et quoi | un squelette à la géométrie du contenu réel |
| **Erreur** | ce qui a échoué, quoi faire | cause + action de reprise, au bon endroit |
| **Succès** | que c'est fait, et la suite | confirmation locale, pas un toast qui disparaît |
| **Désactivé** | pourquoi, et comment l'activer | raison visible ou tooltip, pas seulement un gris |
| **Focus** | où est le clavier | anneau visible, ≥ 3:1 contre le fond |

### Vide

- Jamais un écran blanc, jamais « No data ».
- Trois éléments : ce qui manque, pourquoi, l'action. « Aucune facture — vos factures apparaîtront ici dès le premier paiement. Créer un devis ».
- Pour une recherche sans résultat : reprendre le terme, proposer d'élargir, ne pas laisser l'utilisateur devant un tableau vide.
- Le premier état d'un compte neuf est *le* moment d'onboarding : il mérite un vrai design, pas un placeholder.

### Chargement

- **Squelette** à la forme du contenu (mêmes lignes, mêmes hauteurs) ; un spinner seul est un échec.
- Sous 200ms, ne rien afficher : le flash est pire que l'attente.
- Après ~1s, ajouter un texte (« Chargement des factures… ») ; après ~10s, expliquer et proposer de réessayer.
- Garder la structure visible (en-têtes, barre latérale) : seule la zone qui charge change.
- Pas de shimmer qui balaie tout l'écran en boucle.

### Erreur

- **Au plus près de la cause.** Erreur de champ → sous le champ. Échec de section → dans la section. Échec de page → dans le contenu, pas en toast.
- Le message dit **quoi corriger**, pas « Une erreur est survenue ».
- Toujours une action : réessayer, revenir, contacter, corriger le champ.
- Ne jamais vider le formulaire après une erreur.
- Ne pas mélanger erreur et avertissement : couleurs, icônes et formulations distinctes.

### Succès

- Confirmation **là où l'action a eu lieu** : le bouton devient « Enregistré », la ligne se met à jour, la modale se ferme avec un retour.
- Un toast est un complément, jamais la seule preuve.
- Pas de confettis, pas de « 🎉 » pour un enregistrement de préférences.

## Formulaires

- **Un champ = un label visible.** Le placeholder n'est pas un label (il disparaît à la saisie).
- Obligatoire : marquer l'exception (`Facultatif`) plutôt que l'universalité (`*` partout).
- **Valider au blur**, pas à chaque frappe ; corriger en direct une fois l'erreur affichée.
- Annoncer les contraintes avant : format attendu, longueur, unités.
- `autocomplete`, `inputmode`, `type` corrects (`email`, `tel`, `url`, `numeric`) : c'est du design, pas de la technique.
- Regrouper par intention, une colonne, ordre de lecture naturel.
- Le bouton primaire nomme le résultat : « Créer le compte », pas « Valider ».
- **Ne jamais désactiver le bouton de soumission pour cause de formulaire invalide** : on ne sait pas pourquoi c'est grisé. Laisser cliquable et afficher les erreurs.
- Double soumission : état `pending` sur le bouton (texte + spinner discret), pas de doublon.
- Accessibilité : `aria-invalid`, `aria-describedby` vers le message, message dans le DOM au moment de l'erreur, focus déplacé sur le premier champ en erreur.

## Micro-détails qui trahissent

- Compteur de caractères qui ne sert à rien.
- « Champ requis » découvert à la soumission.
- Message d'erreur en anglais dans une UI française.
- Input sans état `:focus-visible` distinct du `:focus` souris.
- Tableau paginé qui repart en haut sans scroll ni annonce.
- Bouton qui reste en `loading` après une erreur.
- Modale qui ne rend pas le focus à son déclencheur à la fermeture.
- Date au format `2026-11-27` dans une interface destinée à des humains.
