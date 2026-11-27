#!/usr/bin/env bash
# Installe chrome-headless-shell une seule fois (Chrome for Testing, sans Google
# Chrome système), puis expose la commande `chrome-headless-shell` dans le PATH.
#
#   bash install-browser.sh                 # version épinglée par défaut
#   bash install-browser.sh 158.0.8127.88   # autre version
#
# Variables : CHS_HOME (défaut ~/.local/share/chrome-headless-shell),
#             BIN_DIR (défaut ~/.local/bin).
set -euo pipefail

VERSION="${1:-158.0.8127.88}"
DEST="${CHS_HOME:-$HOME/.local/share/chrome-headless-shell}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"

command -v npx >/dev/null 2>&1 || { echo "❌ npx est requis (Node 22+)." >&2; exit 1; }

# Déjà installé : ne pas retélécharger 283 Mo.
if [ -x "$BIN_DIR/chrome-headless-shell" ] && "$BIN_DIR/chrome-headless-shell" --version >/dev/null 2>&1; then
  echo "✅ Déjà installé : $("$BIN_DIR/chrome-headless-shell" --version)"
  exit 0
fi

echo "→ Installation de chrome-headless-shell@$VERSION dans $DEST"
npx -y @puppeteer/browsers install "chrome-headless-shell@$VERSION" --path "$DEST"

BIN="$(find "$DEST" -type f -name chrome-headless-shell -perm -u+x | head -1)"
[ -n "$BIN" ] || { echo "❌ Binaire introuvable après installation." >&2; exit 1; }

mkdir -p "$BIN_DIR"
printf '#!/bin/sh\nexec "%s" "$@"\n' "$BIN" > "$BIN_DIR/chrome-headless-shell"
chmod 0755 "$BIN_DIR/chrome-headless-shell"

echo "✅ $("$BIN_DIR/chrome-headless-shell" --version)"
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) echo "⚠️  Ajoute $BIN_DIR au PATH pour que les skills le trouvent." >&2 ;;
esac
