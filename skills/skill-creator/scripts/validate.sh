#!/usr/bin/env bash
# Valider un skill Agent Skills
set -euo pipefail

SKILL_DIR="${1:?Usage: validate.sh <skill-dir>}"
SKILL_FILE="$SKILL_DIR/SKILL.md"

echo "🔍 Validation de '$SKILL_DIR'..."
echo ""

ERRORS=0
WARNINGS=0

# Vérifier que SKILL.md existe
if [ ! -f "$SKILL_FILE" ]; then
  echo "❌ SKILL.md non trouvé"
  exit 1
fi

# Vérifier le frontmatter
if ! head -1 "$SKILL_FILE" | grep -q "^---"; then
  echo "❌ Frontmatter manquant (doit commencer par ---)"
  ERRORS=$((ERRORS + 1))
fi

# Vérifier name
NAME=$(grep -m1 "^name:" "$SKILL_FILE" | sed 's/^name: *//' || true)
if [ -z "$NAME" ]; then
  echo "❌ Champ 'name' manquant"
  ERRORS=$((ERRORS + 1))
else
  # Valider le format
  if echo "$NAME" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; then
    echo "✅ name: $NAME"
  else
    echo "❌ name invalide: '$NAME' (minuscules, tirets, max 64 chars)"
    ERRORS=$((ERRORS + 1))
  fi

  # Vérifier que ça correspond au dossier
  DIR_NAME=$(basename "$SKILL_DIR")
  if [ "$NAME" = "$DIR_NAME" ]; then
    echo "✅ name correspond au dossier"
  else
    echo "⚠️  name ('$NAME') ≠ nom du dossier ('$DIR_NAME')"
    WARNINGS=$((WARNINGS + 1))
  fi
fi

# Vérifier description
DESC=$(sed -n '/^description:/,/^---/p' "$SKILL_FILE" | grep -v "^description:" | grep -v "^---" | head -5 || true)
if [ -z "$DESC" ]; then
  echo "❌ Champ 'description' manquant"
  ERRORS=$((ERRORS + 1))
else
  DESC_LEN=${#DESC}
  if [ "$DESC_LEN" -le 1024 ]; then
    echo "✅ description: $DESC_LEN caractères"
  else
    echo "❌ description trop longue: $DESC_LEN caractères (max 1024)"
    ERRORS=$((ERRORS + 1))
  fi
fi

# Vérifier la taille
LINES=$(wc -l < "$SKILL_FILE")
if [ "$LINES" -le 500 ]; then
  echo "✅ $LINES lignes (< 500)"
else
  echo "⚠️  $LINES lignes (> 500, envisagez de déplacer du contenu dans references/)"
  WARNINGS=$((WARNINGS + 1))
fi

# Vérifier les sections recommandées
for section in "Quand utiliser" "Validation"; do
  if grep -qi "## .*${section}" "$SKILL_FILE"; then
    echo "✅ Section '$section' présente"
  else
    echo "⚠️  Section '$section' manquante (recommandé)"
    WARNINGS=$((WARNINGS + 1))
  fi
done

for section in "Ne PAS utiliser" "NE PAS utiliser"; do
  if grep -q "## .*${section}" "$SKILL_FILE"; then
    echo "✅ Section exclusions présente"
    break
  fi
done

# Vérifier les fichiers référencés
echo ""
echo "📁 Vérification des références..."
for ref in $(grep -oP '\[.*?\]\(([^)]+)\)' "$SKILL_FILE" | grep -oP '\(([^)]+)\)' | tr -d '()' | grep -v 'http' || true); do
  if [ -f "$SKILL_DIR/$ref" ]; then
    echo "  ✅ $ref"
  else
    echo "  ⚠️  $ref non trouvé"
    WARNINGS=$((WARNINGS + 1))
  fi
done

# Vérifier les scripts
if [ -d "$SKILL_DIR/scripts" ]; then
  echo ""
  echo "📜 Scripts..."
  for script in "$SKILL_DIR/scripts/"*; do
    if [ -f "$script" ]; then
      if [ -x "$script" ]; then
        echo "  ✅ $(basename "$script") (exécutable)"
      else
        echo "  ⚠️  $(basename "$script") (pas exécutable)"
        WARNINGS=$((WARNINGS + 1))
      fi
    fi
  done
fi

# Résumé
echo ""
echo "═══════════════════════════════════"
if [ "$ERRORS" -eq 0 ]; then
  echo "✅ Skill valide ($WARNINGS avertissements)"
  exit 0
else
  echo "❌ $ERRORS erreur(s), $WARNINGS avertissement(s)"
  exit 1
fi
