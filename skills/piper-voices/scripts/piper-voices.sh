#!/usr/bin/env bash
# piper-voices — inventaire, téléchargement et vérification des voix Piper.
#
#   piper-voices.sh list [filtre]     voix disponibles (regex sur le nom)
#   piper-voices.sh installed         voix présentes dans PIPER_VOICES_DIR
#   piper-voices.sh install NOM...    télécharge et vérifie (md5 officiel)
#   piper-voices.sh bootstrap         installe les voix par défaut fr + en
#   piper-voices.sh check [NOM...]    vérifie taille + md5 des voix installées
#   piper-voices.sh dir               affiche le répertoire des voix
set -euo pipefail

VOICES_DIR="${PIPER_VOICES_DIR:-$HOME/.local/share/piper-voices}"
BASE="https://huggingface.co/rhasspy/piper-voices/resolve/main"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/piper-voices"
INDEX="$CACHE_DIR/voices.json"
PYTHON="${PIPER_PYTHON:-$(command -v python3 || true)}"
DEFAULT_VOICES=(fr_FR-siwis-medium en_GB-alan-medium)

die() { echo "❌ $*" >&2; exit 1; }

usage() {
  sed -n '2,9p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

fetch_index() {
  mkdir -p "$CACHE_DIR"
  if [[ -f $INDEX ]] && [[ -z ${1:-} ]]; then
    return 0
  fi
  echo "→ index des voix (voices.json)…" >&2
  curl -fsSL --retry 3 -o "$INDEX.tmp" "$BASE/voices.json" \
    || die "index indisponible : $BASE/voices.json"
  mv "$INDEX.tmp" "$INDEX"
}

# Lignes "url|octets|md5|destination" pour chaque fichier d'une voix.
plan_voice() {
  "$PYTHON" - "$INDEX" "$1" "$BASE" "$VOICES_DIR" <<'PY'
import json, sys
index, wanted, base, dest = sys.argv[1:5]
with open(index, encoding="utf-8") as f:
    voices = json.load(f)
alias = {a: k for k, v in voices.items() for a in v.get("aliases", [])}
name = wanted if wanted in voices else alias.get(wanted, wanted)
voice = voices.get(name)
if voice is None:
    sys.exit(f"voix inconnue : {wanted}")
for path, meta in voice["files"].items():
    if not path.endswith((".onnx", ".onnx.json", "MODEL_CARD")):
        continue
    target = dest + "/MODEL_CARD-" + name if path.endswith("MODEL_CARD") \
        else dest + "/" + name + (".onnx" if path.endswith(".onnx") else ".onnx.json")
    print(f"{base}/{path}|{meta['size_bytes']}|{meta['md5_digest']}|{target}")
PY
}

cmd_dir() { echo "$VOICES_DIR"; }

cmd_list() {
  fetch_index
  "$PYTHON" - "$INDEX" "${1:-.}" "$0" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    voices = json.load(f)
import re
pattern = re.compile(sys.argv[2], re.I)
rows = []
for name, v in sorted(voices.items()):
    if not pattern.search(name):
        continue
    size = sum(m["size_bytes"] for p, m in v["files"].items() if p.endswith(".onnx"))
    lang = v["language"]["name_english"]
    rows.append((name, v["quality"], f"{size / 1e6:.0f} Mo", f"{v['num_speakers']} voix", lang))
for row in rows:
    print("  ".join(f"{c:<26}" if i == 0 else f"{c:<9}" for i, c in enumerate(row)))
print(f"\n{len(rows)} voix — installer avec : {sys.argv[3].split('/')[-1]} install <nom>")
PY
}

cmd_installed() {
  [[ -d $VOICES_DIR ]] || { echo "répertoire absent : $VOICES_DIR"; return 0; }
  local model
  for model in "$VOICES_DIR"/*.onnx; do
    [[ -e $model ]] || continue
    printf '%-32s %s Mo\n' "$(basename "$model" .onnx)" \
      "$(( $(stat -c %s "$model") / 1000000 ))"
  done
}

cmd_install() {
  [[ $# -gt 0 ]] || die "donne au moins un nom de voix (voir : list)"
  fetch_index
  mkdir -p "$VOICES_DIR"
  local name plan url size md5 target tmp ok=0
  for name in "$@"; do
    echo "→ $name"
    plan=$(plan_voice "$name") || { echo "  ⚠️  ignorée"; continue; }
    while IFS='|' read -r url size md5 target; do
      mkdir -p "$(dirname "$target")"
      tmp="$target.part"
      if [[ $size -ge 1000000 ]]; then
        echo "  $(basename "$target") ($(( size / 1000000 )) Mo)"
      else
        echo "  $(basename "$target") ($(( size / 1000 )) Ko)"
      fi
      curl -fsSL --retry 3 --progress-bar -o "$tmp" "$url" || { rm -f "$tmp"; die "téléchargement échoué : $url"; }
      local got_size got_md5
      got_size=$(stat -c %s "$tmp")
      got_md5=$(md5sum "$tmp" | cut -d' ' -f1)
      if [[ $got_size -ne $size || $got_md5 != "$md5" ]]; then
        rm -f "$tmp"
        die "fichier corrompu : $target ($got_size octets / md5 $got_md5, attendu $size / $md5)"
      fi
      mv "$tmp" "$target"
    done <<< "$plan"
    ok=$((ok + 1))
  done
  echo "✅ $ok voix installée(s) dans $VOICES_DIR"
  smoke_test || true
}

smoke_test() {
  local bin="${PIPER_BIN:-$(command -v piper || true)}"
  local model="$VOICES_DIR/${1:-fr_FR-siwis-medium}.onnx"
  [[ -n $bin && -f $model ]] || return 0
  local wav="${TMPDIR:-/tmp}/piper-smoke.wav"
  if "$bin" -m "$model" -f "$wav" -- "Bonjour." >/dev/null 2>&1 && [[ -s $wav ]]; then
    echo "✅ test de synthèse OK ($(basename "$model" .onnx))"
    rm -f "$wav"
  else
    echo "⚠️  le test de synthèse a échoué : vérifier le binaire piper" >&2
  fi
}

smoke_one() {
  local bin="${PIPER_BIN:-$(command -v piper || true)}" model="$VOICES_DIR/$1.onnx" wav
  [[ -n $bin && -f $model ]] || return 0
  wav="${TMPDIR:-/tmp}/piper-check-$$.wav"
  if "$bin" -m "$model" -f "$wav" -- "Bonjour." >/dev/null 2>&1 && [[ -s $wav ]]; then
    rm -f "$wav"; return 0
  fi
  rm -f "$wav"
  return 1
}

# Un fichier présent mais d'un md5 différent n'est pas cassé : c'est une
# révision antérieure (les voix sont réentraînées). Seul un modèle qui ne se
# charge plus est une erreur.
cmd_check() {
  fetch_index
  local names=("$@")
  if [[ ${#names[@]} -eq 0 ]]; then
    mapfile -t names < <(cd "$VOICES_DIR" 2>/dev/null && ls *.onnx 2>/dev/null | sed 's/\.onnx$//')
  fi
  [[ ${#names[@]} -gt 0 ]] || die "aucune voix installée dans $VOICES_DIR"
  local name plan url size md5 target bad=0 warned=0
  for name in "${names[@]}"; do
    plan=$(plan_voice "$name") || { echo "❌ $name inconnue de l'index"; bad=$((bad + 1)); continue; }
    while IFS='|' read -r url size md5 target; do
      [[ ${target##*/} == MODEL_CARD* ]] && continue
      if [[ ! -f $target ]]; then
        echo "❌ $(basename "$target") manquant"; bad=$((bad + 1))
      elif [[ $(md5sum "$target" | cut -d' ' -f1) != "$md5" ]]; then
        echo "⚠️  $(basename "$target") : révision antérieure"
        warned=$((warned + 1))
      else
        echo "✅ $(basename "$target")"
      fi
    done <<< "$plan"
    if ! smoke_one "$name"; then
      echo "❌ $name ne se charge pas (modèle tronqué) → install $name"
      bad=$((bad + 1))
    fi
  done
  [[ $bad -eq 0 ]] || die "$bad voix à réparer"
  [[ $warned -eq 0 ]] || echo "ℹ️  $warned fichier(s) dans une révision antérieure (install <voix> pour mettre à jour)"
}

cmd_bootstrap() {
  cmd_install "${DEFAULT_VOICES[@]}"
  echo
  echo "Variables pour ~/.bashrc :"
  echo "  export PIPER_VOICES_DIR=\"$VOICES_DIR\""
  echo "  export PIPER_VOICE=\"fr_FR-siwis-medium\""
}

main() {
  [[ $# -gt 0 ]] || { usage; exit 1; }
  local cmd=$1; shift
  case "$cmd" in
    list) cmd_list "$@" ;;
    installed) cmd_installed ;;
    install) cmd_install "$@" ;;
    bootstrap) cmd_bootstrap ;;
    check) cmd_check "$@" ;;
    dir) cmd_dir ;;
    -h|--help|help) usage ;;
    *) usage; die "commande inconnue : $cmd" ;;
  esac
}

main "$@"
