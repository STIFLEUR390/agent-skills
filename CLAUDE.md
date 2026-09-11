# Project Instructions — skill-manager

## Build & Test

Pas de build : c'est un dépôt de fichiers Markdown et scripts bash.

```bash
# Valider tous les skills
for skill in skills/*/; do
  bash skills/skill-creator/scripts/validate.sh "$skill"
done

# Déployer un skill
bash skills/skill-creator/scripts/deploy.sh <skill-name>

# Vérifier la structure
find skills -name "SKILL.md" | sort
```

## Conventions

- **SKILL.md** : frontmatter YAML (`name`, `description` requis) + body Markdown
- **name** : minuscules, tirets, max 64 chars, = nom du dossier
- **description** : action + objet + déclencheurs + exclusions, < 1024 chars
- **Body** : < 500 lignes, sections "Quand utiliser" / "Validation" / "Erreurs"
- **Scripts** : `set -euo pipefail`, messages d'erreur explicites
- **Templates** : utilisables indépendamment du skill
- **References** : knowledge base, chargées à la demande

## Structure d'un skill

```
skills/<name>/
├── SKILL.md              # Requis
├── workflows/            # Phases du processus
├── templates/            # Structures pré-remplies
├── references/           # Knowledge base
└── scripts/              # Scripts exécutables
```

## Déploiement local

```bash
# Tous les agents
for dir in ~/.claude/skills ~/.agents/skills ~/.config/opencode/skills ~/.pi/agent/skills ~/.omp/agent/skills; do
  mkdir -p "$dir"
  cp -r skills/<name> "$dir/<name>"
done
```

## Règles

- Un skill = un job (pas de fourre-tout)
- La description est la routing rule (pas un titre)
- Progressive disclosure : SKILL.md court, détail dans references/
- Tester sur plusieurs agents avant de valider
- Pas de credentials dans les skills
