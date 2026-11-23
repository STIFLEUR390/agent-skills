#!/usr/bin/env bash
# Déployer un skill vers tous les agents
set -euo pipefail

SKILL_NAME="${1:-}"
SOURCE_DIR="${2:-.}"

# --all : déploie tous les skills du répertoire source
if [ "$SKILL_NAME" = "--all" ]; then
  for d in "$SOURCE_DIR"/*/; do
    [ -f "$d/SKILL.md" ] && bash "$0" "$(basename "$d")" "$SOURCE_DIR" >/dev/null
  done
  echo "✅ Tous les skills de $SOURCE_DIR déployés"
  exit 0
fi

if [ -z "$SKILL_NAME" ]; then
  echo "Usage: deploy.sh <skill-name|--all> [source-dir]" >&2
  exit 1
fi

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
