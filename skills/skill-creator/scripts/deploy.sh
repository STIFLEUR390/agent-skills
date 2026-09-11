#!/usr/bin/env bash
# Déployer un skill vers tous les agents
set -euo pipefail

SKILL_NAME="${1:?Usage: deploy.sh <skill-name> [source-dir]}"
SOURCE_DIR="${2:-.}"

# Vérifier que le skill existe
if [ ! -f "$SOURCE_DIR/$SKILL_NAME/SKILL.md" ]; then
  echo "❌ $SOURCE_DIR/$SKILL_NAME/SKILL.md non trouvé" >&2
  exit 1
fi

# Vérifier le frontmatter
if ! head -5 "$SOURCE_DIR/$SKILL_NAME/SKILL.md" | grep -q "^name:"; then
  echo "❌ Frontmatter invalide : champ 'name' manquant" >&2
  exit 1
fi

if ! head -10 "$SOURCE_DIR/$SKILL_NAME/SKILL.md" | grep -q "^description:"; then
  echo "❌ Frontmatter invalide : champ 'description' manquant" >&2
  exit 1
fi

echo "📦 Déploiement de '$SKILL_NAME'..."
echo ""

DEPLOYED=0

for dir in \
  "$HOME/.claude/skills" \
  "$HOME/.agents/skills" \
  "$HOME/.config/opencode/skills" \
  "$HOME/.pi/agent/skills" \
  "$HOME/.omp/agent/skills"; do

  if [ -d "$dir" ] || mkdir -p "$dir" 2>/dev/null; then
    rm -rf "$dir/$SKILL_NAME"
    cp -r "$SOURCE_DIR/$SKILL_NAME" "$dir/$SKILL_NAME"
    echo "  ✅ $dir/$SKILL_NAME"
    DEPLOYED=$((DEPLOYED + 1))
  fi
done

echo ""
echo "✅ Déployé dans $DEPLOYED emplacements"
echo ""
echo "Pour activer :"
echo "  - Claude Code : nouvelle session ou /reload-plugins"
echo "  - Pi : /reload ou nouvelle session"
echo "  - omp : /reload-plugins"
