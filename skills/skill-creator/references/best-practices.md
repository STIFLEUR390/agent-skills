# Bonnes pratiques Agent Skills

## 1. La description est la routing rule

La description n'est pas un titre. C'est la règle de routage qui décide
si l'agent active le skill. Traitez-la comme du code de discrimination.

### Format recommandé

```
[Action] [Objet] [Contexte]. Utiliser quand [déclencheurs].
Ne PAS utiliser pour [exclusions].
```

### Exemples

| Skill | Description bonne | Description mauvaise |
|-------|-------------------|----------------------|
| project-definer | "Définition complète d'un projet : découverte, PRD, architecture. Utiliser quand l'utilisateur veut lancer un nouveau projet." | "Aide avec les projets" |
| skill-creator | "Créer un nouveau skill agent. Utiliser quand l'utilisateur veut créer un skill ou transformer des instructions en skill." | "Création de skills" |
| code-reviewer | "Revue de code pour correctness, sécurité, performance. Utiliser quand l'utilisateur demande une review de PR ou de diff." | "Review du code" |

### Checklist

- [ ] Nomme l'action (créer, review, déployer, analyser, migrer...)
- [ ] Nomme l'objet (skill, projet, PRD, migration, component...)
- [ ] Dit quand l'utiliser (trigger words concrets)
- [ ] Dit quand NE PAS l'utiliser (exclusions claires)
- [ ] Reste sous 1024 caractères

## 2. Progressive disclosure

Les agents chargent les skills progressivement. Respectez cette hiérarchie :

| Niveau | Quoi | Taille | Quand chargé |
|--------|------|--------|--------------|
| Metadata | name + description | ~100 tokens | Toujours en contexte |
| Instructions | Body SKILL.md | < 5000 tokens | À l'activation du skill |
| Resources | Fichiers support | Au besoin | Si le skill les référence |

### Règles

- **SKILL.md < 500 lignes** : au-delà, déplacez dans `references/`
- **Un seul niveau de profondeur** pour les références : `references/sujet.md`, pas `references/dossier/sujet.md`
- **Les scripts ne s'exécutent pas automatiquement** : le skill doit dire quand les lancer

## 3. Structure du body

### Sections recommandées

| Section | Obligatoire | Purpose |
|---------|-------------|---------|
| Quand utiliser | Oui | Déclencheurs |
| Quand NE PAS utiliser | Recommandé | Exclusions |
| Processus / Étapes | Oui | Workflow |
| Validation | Recommandé | Critères de succès |
| Erreurs courantes | Recommandé | Pièges connus |
| Règles générales | Optionnel | Principes |

### Format des étapes

```markdown
## Étape 1 — Nom de l'étape

### Objectif
[Ce qu'on veut obtenir]

### Instructions
1. [Action concrète]
2. [Action concrète]

### Livrable
[Ce qui est produit]
```

## 4. Nommage

### `name`

| Règle | Exemple valide | Exemple invalide |
|-------|----------------|------------------|
| Minuscules | `my-skill` | `My-Skill` |
| Tirets simples | `my-skill` | `my--skill` |
| Pas de bord | `my-skill` | `-my-skill-` |
| Max 64 chars | `a` × 64 | `a` × 65 |
| = nom du dossier | `my-skill/` | `other-name/` |

### Dossiers

| Dossier | Contenu | Nommage |
|---------|---------|---------|
| `workflows/` | Phases du processus | `01-nom.md`, `02-nom.md` |
| `templates/` | Structures pré-remplies | `nom.md` |
| `references/` | Knowledge base | `sujet.md` |
| `scripts/` | Scripts exécutables | `nom.sh`, `nom.py` |

## 5. Multi-agents

### Ce qui marche partout

- Markdown simple
- Frontmatter YAML basique (name, description)
- Chemins relatifs
- Code dans des blocs fenced

### Ce qui ne marche PAS partout

- `allowed-tools` (support variable)
- `context: fork` (Claude Code uniquement)
- `disable-model-invocation` (Claude Code uniquement)
- `argument-hint` (Claude Code uniquement)

### Règle

Écrivez pour le plus petit dénominateur commun. Les fonctionnalités
avancées sont des bonus, pas des dépendances.

## 6. Sécurité

Les skills sont du code exécutable par l'agent. Risques :

| Risque | Mitigation |
|--------|------------|
| Script malveillant | Lire les scripts avant installation |
| Injection de prompt | Pas de données utilisateur dans les templates |
| Fuite de secrets | Ne jamais inclure de credentials |
| Escalade de privilèges | `allowed-tools` restrictif |

### Règles

1. **Lire avant d'installer** : inspecter SKILL.md et scripts
2. **Vérifier l'origine** : dépôt connu et auditable
3. **Pas de credentials** : utiliser des variables d'environnement
4. **Scripts verbeux** : messages d'erreur explicites

## 7. Publication

### Pour publier sur skills.sh

1. Mettre le skill dans un repo GitHub public
2. Structure : `skills/<name>/SKILL.md`
3. Ajouter un README
4. C'est tout — `npx skills add` le détecte automatiquement

### Pour publier dans agent-skills

1. Copier dans `skills/<name>/`
2. Ajouter la doc dans `docs/<name>/GUIDE.md`
3. Mettre à jour le README
4. Push

## 8. Common mistakes

| Erreur | Conséquence | Solution |
|--------|-------------|----------|
| Description trop vague | Skill jamais activé | Ajouter des trigger words |
| SKILL.md trop long | Context bloat | Déplacer dans references/ |
| Pas d'exclusions | Faux positifs | Ajouter "Ne PAS utiliser pour" |
| Pas de validation | Output incohérent | Ajouter critères de succès |
| Scripts sans erreur | Debug difficile | `set -euo pipefail` + messages |
| Nommage invalide | Skill non découvert | Minuscules, tirets, = dossier |
