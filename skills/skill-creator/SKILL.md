---
name: skill-creator
description: >
  Créer un nouveau skill agent multi-plateforme. Utiliser quand l'utilisateur
  veut créer un skill, ajouter un skill au repository, transformer des
  instructions répétitives en skill, ou documenter un workflow réutilisable.
  Couvre la rédaction du SKILL.md, le choix de la structure, la rédaction
  de la description, le déploiement multi-agents, et la publication.
  Ne PAS utiliser pour modifier un skill existant (éditer directement le SKILL.md).
argument-hint: "[nom-du-skill]"
allowed-tools: Read Write Glob Grep Bash WebSearch WebFetch
license: MIT
compatibility: "Claude Code, Codex, OpenCode, Pi, omp — tout agent supportant le standard Agent Skills"
user-invocable: true
---

# Skill Creator — Créer de nouveaux skills agents

Tu es un expert en Agent Skills. Ton rôle est de guider l'utilisateur
pour créer un nouveau skill robuste, compatible multi-agents, et conforme
au standard [Agent Skills](https://agentskills.io).

## Quand utiliser ce skill

- L'utilisateur veut **créer un nouveau skill**
- L'utilisateur veut **ajouter un skill** au repository agent-skills
- L'utilisateur a des **instructions répétitives** qu'il veut transformer en skill
- L'utilisateur veut **documenter un workflow** réutilisable
- L'utilisateur veut **publier un skill** sur skills.sh

## Quand NE PAS utiliser ce skill

- Modifier le contenu d'un skill existant (éditer directement le SKILL.md)
- Installer un skill tiers (utiliser `npx skills add`)
- Configurer un agent (ce n'est pas un skill)

## Vue d'ensemble du processus

| Phase | Objectif | Livrable |
|-------|----------|----------|
| 1. Idée | Définir le scope et le nom | Nom + description validés |
| 2. Structure | Choisir l'arborescence | Dossier créé |
| 3. SKILL.md | Rédiger le point d'entrée | SKILL.md complet |
| 4. Support | Ajouter workflows/templates/refs | Fichiers support |
| 5. Validation | Vérifier la conformité | Checklist passée |
| 6. Déploiement | Installer et tester | Skill opérationnel |

## Phase 1 — Idée et scope

### Questions à poser

1. **Quel problème ce skill résout-il ?** (en une phrase)
2. **Quand l'agent doit-il l'activer ?** (déclencheurs)
3. **Quand ne doit-il PAS l'activer ?** (exclusions)
4. **Quelles étapes suit-il ?** (workflow)
5. **A-t-il besoin de scripts, templates, ou références ?**

### Règle du scope

Un skill = un job. Si vous avez deux skills, faites deux skills.
Pas de "skill fourre-tout".

## Phase 2 — Structure

### Arborescence standard

```
<skill-name>/
├── SKILL.md              # Requis : point d'entrée
├── workflows/            # Optionnel : phases du processus
├── templates/            # Optionnel : structures pré-remplies
├── references/           # Optionnel : knowledge base
├── scripts/              # Optionnel : scripts exécutables
└── assets/               # Optionnel : images, schemas, configs
```

### Règle KISS

Commencez simple. N'ajoutez des dossiers que quand vous en avez besoin.

| Niveau | Contenu | Quand |
|--------|---------|-------|
| Minimal | SKILL.md seul | Workflow court, pas de référence |
| Standard | SKILL.md + workflows/ ou templates/ | Processus en étapes |
| Complet | Tout | Skill complexe avec expertise métier |

## Phase 3 — SKILL.md

### Frontmatter obligatoire

```yaml
---
name: mon-skill
description: >
  Ce que le skill fait ET quand l'utiliser. Inclure les mots-clé
  que l'utilisateur prononcerait. Ajouter "Ne PAS utiliser pour..."
  si le scope peut être confondu.
license: MIT
compatibility: "Claude Code, Codex, OpenCode, Pi, omp"
allowed-tools: Read Write Glob Grep Bash
user-invocable: true
---
```

### Règles de nommage

| Règle | Valide | Invalide |
|-------|--------|----------|
| Minuscules uniquement | `my-skill` | `My-Skill` |
| Tirets simples | `my-skill` | `my--skill` |
| Pas de début/fin par tiret | `my-skill` | `-my-skill-` |
| Max 64 caractères | `a` × 64 | `a` × 65 |
| Correspond au dossier | `my-skill/` | `my-skill/` avec `name: other` |

### Règles de description

La description est la **routing rule** — c'est elle qui décide si l'agent active le skill.

**Format recommandé** :
```
[Action] [Objet] [Quand]. [Exclusions].
```

**Exemple bon** :
```
Crée un nouveau skill agent multi-plateforme. Utiliser quand l'utilisateur
veut créer un skill, transformer des instructions en skill, ou documenter
un workflow réutilisable. Ne PAS utiliser pour modifier un skill existant.
```

**Exemple mauvais** :
```
Aide avec les skills.
```

**Checklist description** :
- [ ] Nomme l'action (créer, review, déployer, analyser...)
- [ ] Nomme l'objet (skill, projet, PRD, migration...)
- [ ] Dit quand l'utiliser (trigger words)
- [ ] Dit quand NE PAS l'utiliser (exclusions)
- [ ] Reste sous 1024 caractères

### Structure du body

```markdown
# Nom du Skill

[Phrase d'introduction sur le rôle]

## Quand utiliser ce skill
[Liste des déclencheurs]

## Quand NE PAS utiliser ce skill
[Liste des exclusions]

## Vue d'ensemble
[Tableau ou description du processus]

## Étape 1 — ...
[Instructions détaillées]

## Étape 2 — ...
[...]

## Validation — comment savoir qu'on a fini
[Critères de succès]

## Erreurs courantes à éviter
[Pièges connus]

## Règles générales
[Principes directeurs]
```

### Progressive disclosure

| Niveau | Taille | Contenu |
|--------|--------|---------|
| Metadata | ~100 tokens | name + description (toujours en contexte) |
| Instructions | < 5000 tokens | Body SKILL.md (chargé à l'activation) |
| Resources | Au besoin | Fichiers support (chargés si référencés)Gardez SKILL.md sous 500 lignes. Déplacez le détail dans `references/`.

## Phase 4 — Fichiers support

### Workflows (`workflows/`)

Un fichier par phase du processus. Nommage : `01-nom.md`, `02-nom.md`.

```markdown
# Phase N — Titre

## Objectif
[Ce qu'on veut obtenir]

## Instructions
[Étapes détaillées]

## Livrable
[Ce qui est produit]
```

### Templates (`templates/`)

Structures pré-remplies, utilisables indépendamment du skill.

```markdown
# Titre du template

## Section 1
| Champ | Valeur |
|-------|--------|
| | |

## Section 2
...
```

### References (`references/`)

Knowledge base, guides, documentation technique.

```markdown
# Sujet

## Concept 1
[Explication détaillée]

## Concept 2
[Explication détaillée]

## Checklist
- [ ] ...
```

### Scripts (`scripts/`)

Scripts exécutables. Toujours inclure un message d'erreur explicite.

```bash
#!/usr/bin/env bash
# Description du script
set -euo pipefail

# Vérification des dépendances
command -v outil >/dev/null 2>&1 || {
  echo "❌ outil non trouvé. Installez-le avec : ..." >&2
  exit 1
}

# Logique
echo "✅ Opération réussie"
```

## Phase 5 — Validation

### Checklist de conformité

**Frontmatter** :
- [ ] `name` est présent, minuscules, tirets, < 64 chars
- [ ] `name` correspond au nom du dossier
- [ ] `description` est présent, < 1024 chars
- [ ] `description` nomme l'action, l'objet, et les déclencheurs
- [ ] `license` est présent (recommandé)

**Body** :
- [ ] "Quand utiliser" est présent
- [ ] "Quand NE PAS utiliser" est présent
- [ ] Les étapes sont numérotées et claires
- [ ] "Validation" définit les critères de succès
- [ ] "Erreurs courantes" liste les pièges
- [ ] < 500 lignes

**Fichiers support** :
- [ ] Les chemins dans SKILL.md sont relatifs et valides
- [ ] Les scripts ont `set -euo pipefail` et des messages d'erreur
- [ ] Les templates sont utilisables indépendamment

**Multi-agents** :
- [ ] Testé sur au moins un agent
- [ ] Pas de syntaxe spécifique à un agent dans le body
- [ ] Compatible avec le standard Agent Skills

### Validation automatique

```bash
# Vérifier le frontmatter
head -20 SKILL.md

# Compter les lignes
wc -l SKILL.md

# Vérifier les références
grep -oP '\[.*?\]\((.*?)\)' SKILL.md | while read -r ref; do
  file=$(echo "$ref" | grep -oP '\((.*?)\)' | tr -d '()')
  [ -f "$file" ] && echo "✅ $file" || echo "❌ $file manquant"
done
```

## Phase 6 — Déploiement

### Déploiement local

```bash
# Copier vers tous les agents
for dir in ~/.claude/skills ~/.agents/skills ~/.config/opencode/skills ~/.pi/agent/skills ~/.omp/agent/skills; do
  mkdir -p "$dir/<skill-name>"
  cp -r <skill-name>/ "$dir/<skill-name>/"
done
```

### Publication sur le repo agent-skills

```bash
# 1. Copier dans le repo
cp -r <skill-name>/ ~/repos/agent-skills/skills/<skill-name>/

# 2. Ajouter la doc
mkdir -p ~/repos/agent-skills/docs/<skill-name>
cp GUIDE.md ~/repos/agent-skills/docs/<skill-name>/

# 3. Mettre à jour le README (tableau des skills)

# 4. Push
cd ~/repos/agent-skills
git add -A
git commit -m "feat: add <skill-name>"
git push
```

### Publication sur skills.sh

Le CLI `npx skills add` détecte automatiquement les skills publiques.
Pas de commande de publication spéciale — le repo GitHub suffit.

## Templates de SKILL.md

### Skill minimal (workflow court)

```markdown
---
name: mon-skill
description: >
  [Action] [Objet]. Utiliser quand [déclencheurs].
---

# Mon Skill

## Étapes
1. [Étape 1]
2. [Étape 2]
3. [Étape 3]

## Résultat attendu
[Description du livrable]
```

### Skill standard (processus en phases)

```markdown
---
name: mon-skill
description: >
  [Action] [Objet]. Utiliser quand [déclencheurs].
  Ne PAS utiliser pour [exclusions].
license: MIT
compatibility: "Claude Code, Codex, OpenCode, Pi, omp"
user-invocable: true
---

# Mon Skill

## Quand utiliser
- [Déclencheur 1]
- [Déclencheur 2]

## Quand NE PAS utiliser
- [Exclusion 1]
- [Exclusion 2]

## Processus

| Phase | Objectif | Livrable |
|-------|----------|----------|
| 1. ... | ... | ... |
| 2. ... | ... | ... |

## Phase 1 — ...
[Instructions]

## Validation
- [ ] Critère 1
- [ ] Critère 2

## Erreurs courantes
1. [Piège 1]
2. [Piège 2]
```

### Skill avec expertise métier (complet)

```markdown
---
name: mon-skill
description: >
  [Action] [Objet] avec [expertise spécifique].
  Utiliser quand [déclencheurs].
  Ne PAS utiliser pour [exclusions].
license: MIT
compatibility: "Claude Code, Codex, OpenCode, Pi, omp"
allowed-tools: Read Write Glob Grep Bash
user-invocable: true
---

# Mon Skill

## Rôle
Tu es [expertise]. Ton rôle est de [mission].

## Quand utiliser / Quand NE PAS utiliser
[Tableau]

## Processus
[5 phases]

## Templates
[Références aux templates]

## Références
[Références aux docs]

## Validation
[Critères]

## Erreurs courantes
[Pièges]

## Règles générales
[Principes]
```

## Bonnes pratiques

1. **Un skill = un job** : ne mélangez pas les responsabilités
2. **La description est la clé** : c'est elle qui déclenche l'activation
3. **Progressive disclosure** : gardez SKILL.md court, mettez le détail dans references/
4. **Testez sur plusieurs agents** : la compatibilité n'est pas garantie
5. **Versionnez** : un skill est du code, traitez-le comme tel
6. **Documentez les exclusions** : dire quand ne PAS utiliser est aussi important
7. **YAGNI** : commencez simple, ajoutez de la complexité quand le besoin est réel
