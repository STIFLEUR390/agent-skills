#!/usr/bin/env python3
"""piper-tts — normalise le texte (fr/en) puis synthétise l'audio avec Piper.

Normalise ce qu'espeak-ng (embarqué dans Piper) prononce mal : nombres, dates,
unités, abréviations, anglicismes, mots absents des dictionnaires espeak, et
homographes anglais. Les corrections phonétiques mesurées sont injectées via
les blocs `[[ IPA ]]` de Piper, qui ne dépendent d'aucun dictionnaire système.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shlex
import shutil
import subprocess
import sys
import wave
from pathlib import Path

HERE = Path(__file__).resolve().parent
ASSETS = HERE.parent / "assets"
INJECTION = r"(\[\[.*?\]\])"

DEFAULT_VOICES = {"fr": "fr_FR-siwis-medium", "en": "en_GB-alan-medium"}

FR_MONTHS = ("janvier février mars avril mai juin juillet août septembre octobre "
             "novembre décembre").split()
EN_MONTHS = ("January February March April May June July August September October "
             "November December").split()

FR_FRACTIONS = {"1/2": "un demi", "1/4": "un quart", "3/4": "trois quarts",
                "1/3": "un tiers", "2/3": "deux tiers"}

CHECK_CODE = r"""
import json, sys
from piper import PiperVoice
model, text = sys.argv[1], sys.argv[2]
with open(model + ".json", encoding="utf-8") as f:
    allowed = set(json.load(f)["phoneme_id_map"])
voice = PiperVoice.load(model)
for sentence in voice.phonemize(text):
    missing = sorted({p for p in sentence if p not in allowed and p.strip()})
    print(" ".join(sentence))
    if missing:
        print("⚠️  absents du modèle :", " ".join(missing), file=sys.stderr)
"""


# ---------------------------------------------------------------- normalisation
def _fr_date(day: str, month: str, year: str | None = None) -> str | None:
    m = int(month)
    if not 1 <= m <= 12:
        return None
    d = int(day)
    jour = "1er" if d == 1 else str(d)
    return f"le {jour} {FR_MONTHS[m - 1]}" + (f" {year}" if year else "")


def _en_ordinal(n: int) -> str:
    if 11 <= n % 100 <= 13:
        return f"{n}th"
    return f"{n}{ {1: 'st', 2: 'nd', 3: 'rd'}.get(n % 10, 'th') }"


def _en_date(day: str, month: str, year: str | None = None) -> str | None:
    m = int(month)
    if not 1 <= m <= 12:
        return None
    return f"{_en_ordinal(int(day))} {EN_MONTHS[m - 1]}" + (f" {year}" if year else "")


def fr_rules(t: str) -> str:
    t = t.replace("\u00a0", " ").replace("\u202f", " ")
    t = t.replace("’", "'").replace("«", "").replace("»", "")
    t = t.replace("“", "").replace("”", "")
    for k, v in FR_FRACTIONS.items():
        t = re.sub(r"(?<![\d/])" + re.escape(k) + r"(?![\d/])", v, t)
    t = re.sub(r"\b(\d{4})-(\d{1,2})-(\d{1,2})\b",
               lambda m: _fr_date(m[3], m[2], m[1]) or m[0], t)
    t = re.sub(r"\b(\d{1,2})/(\d{1,2})/(\d{4})\b",
               lambda m: _fr_date(m[1], m[2], m[3]) or m[0], t)
    t = re.sub(r"\b(\d{2})/(\d{2})\b", lambda m: _fr_date(m[1], m[2]) or m[0], t)
    t = re.sub(r"\b1re\b", "première", t)
    t = re.sub(r"\b1er\b", "premier", t)
    t = re.sub(r"\b2nde\b", "seconde", t)
    t = re.sub(r"\b2nd\b", "second", t)
    t = re.sub(r"\b(\d+)\s*e\b", r"\1ème", t)          # 2e -> 2ème -> "deuzième"
    t = re.sub(r"(?<=\d)\.(?=\d)", ",", t)             # 3.14 -> 3,14
    t = re.sub(r"(\d+)\s*€", r"\1 euros", t)
    t = t.replace("€", "euros")
    t = re.sub(r"(\d+)\s*%", r"\1 pour cent", t)
    t = t.replace("%", "pour cent")
    t = t.replace("&", " et ")
    t = re.sub(r"\b[nN]\s*°\s*", "numéro ", t)
    t = re.sub(r"\b[nN]o\.?\s*(?=\d)", "numéro ", t)
    return t


def en_rules(t: str) -> str:
    t = t.replace("\u00a0", " ").replace("\u202f", " ")
    t = t.replace("’", "'")
    for src in ("«", "»", "“", "”"):
        t = t.replace(src, '"')
    t = re.sub(r"\b(\d{4})-(\d{1,2})-(\d{1,2})\b",
               lambda m: _en_date(m[3], m[2], m[1]) or m[0], t)
    t = re.sub(r"\b(\d{1,2})/(\d{1,2})/(\d{4})\b",
               lambda m: _en_date(m[1], m[2], m[3]) or m[0], t)
    t = re.sub(r"\b[Nn]o\.?(?=\s*\d)", "Number", t)
    t = re.sub(r"£\s*(\d)", r"\1 pounds", t)
    t = re.sub(r"\$\s*(\d)", r"\1 dollars", t)
    t = re.sub(r"(\d+)\s*€", r"\1 euros", t)
    t = re.sub(r"(\d+)\s*%", r"\1 percent", t)
    t = t.replace("£", "pounds").replace("$", "dollars").replace("€", "euros")
    t = t.replace("%", " percent").replace("&", " and ")
    return t


RULES = {"fr": fr_rules, "en": en_rules}


def lexicon_paths(lang: str) -> list[Path]:
    paths = [ASSETS / f"lexicon-{lang}.json"]
    extra = os.environ.get("PIPER_LEXICONS", "")
    paths += [Path(p).expanduser() for p in extra.split(":") if p.strip()]
    return paths


def load_lexicon(lang: str) -> dict[str, str]:
    words: dict[str, str] = {}
    for path in lexicon_paths(lang):
        if path.is_file():
            with open(path, encoding="utf-8") as f:
                words.update(json.load(f).get("words", {}))
    return words


def apply_lexicon(text: str, words: dict[str, str]) -> str:
    if not words:
        return text
    keys = sorted(words, key=len, reverse=True)   # "MM." avant "M."

    def fix(part: str) -> str:
        for key in keys:
            pattern = re.escape(key)
            if re.match(r"\w", key[0]):
                pattern = r"(?<!\w)" + pattern
            if re.match(r"\w", key[-1]):
                pattern = pattern + r"(?!\w)"
            part = re.sub(pattern, lambda _m, _v=words[key]: _v, part,
                          flags=re.IGNORECASE)
        return part

    parts = re.split(INJECTION, text)   # on ne touche jamais à l'intérieur de [[ ]]
    return "".join(p if i % 2 else fix(p) for i, p in enumerate(parts))


def normalize(text: str, lang: str) -> str:
    text = " ".join(text.split())
    parts = re.split(INJECTION, text)
    for i in range(0, len(parts), 2):
        parts[i] = RULES[lang](parts[i])
    out = apply_lexicon("".join(parts), load_lexicon(lang))
    return re.sub(r"\s{2,}", " ", out).strip()


# ------------------------------------------------------------------- exécution
def voices_dir() -> Path:
    return Path(os.environ.get("PIPER_VOICES_DIR")
                or Path.home() / ".local/share/piper-voices").expanduser()


def piper_bin() -> str:
    binary = os.environ.get("PIPER_BIN") or shutil.which("piper")
    if not binary:
        sys.exit("piper introuvable : uv tool install piper-tts, ou exporte PIPER_BIN")
    return binary


def venv_python(piper: str) -> str | None:
    """Le python qui a piper-tts installé (lue depuis le shebang de `piper`)."""
    if os.environ.get("PIPER_PYTHON"):
        return os.environ["PIPER_PYTHON"]
    try:
        with open(piper, "rb") as f:
            first = f.readline(512)
    except OSError:
        return None
    if not first.startswith(b"#!"):
        return None
    parts = first[2:].decode("utf-8", "replace").split()
    if parts and Path(parts[0]).name == "env" and len(parts) > 1:
        return shutil.which(parts[1])
    return parts[0] if parts and os.access(parts[0], os.X_OK) else None


def resolve_voice(voice: str, data_dir: Path) -> Path:
    path = Path(voice).expanduser()
    if path.suffix == ".onnx":
        if not path.is_file():
            sys.exit(f"modèle introuvable : {path}")
        return path
    model = data_dir / f"{voice}.onnx"
    if model.is_file() and model.with_suffix(".onnx.json").is_file():
        return model
    installed = sorted(p.name[:-5] for p in data_dir.glob("*.onnx")) if data_dir.is_dir() else []
    sys.exit(f"voix '{voice}' absente de {data_dir}\n"
             f"installées : {', '.join(installed) or 'aucune'}\n"
             f"→ skill piper-voices : scripts/piper-voices.sh install {voice}")


def wav_info(path: Path) -> str:
    try:
        with wave.open(str(path), "rb") as w:
            seconds = w.getnframes() / w.getframerate()
        return f"{path} ({seconds:.1f}s)"
    except (wave.Error, OSError):
        return str(path)


def phonemes(model: Path, text: str) -> int:
    python = venv_python(piper_bin())
    if not python:
        sys.exit("python de piper-tts introuvable : exporte PIPER_PYTHON")
    return subprocess.run([python, "-c", CHECK_CODE, str(model), text]).returncode


def self_test() -> int:
    cases = [
        ("fr", "M. Dupont", "Monsieur Dupont"),
        ("fr", "MM. Dupont", "Messieurs Dupont"),
        ("fr", "2e étage", "2ème étage"),
        ("fr", "1re place", "première place"),
        ("fr", "le 1er mai", "le premier mai"),
        ("fr", "n° 5", "numéro 5"),
        ("fr", "5 €", "5 euros"),
        ("fr", "50 %", "50 pour cent"),
        ("fr", "3.14", "3,14"),
        ("fr", "3/4", "trois quarts"),
        ("fr", "01/02/2025", "le premier février 2025"),
        ("fr", "2025-02-01", "le premier février 2025"),
        ("fr", "R&D", "R et D"),
        ("fr", "le week-end", "le [[wikˈɛnd]]"),
        ("fr", "un WC", "un [[vesˈe]]"),
        ("fr", "mon e-mail", "mon courriel"),
        ("fr", "[[ kɥijˈɛʁ ]] intact", "[[ kɥijˈɛʁ ]] intact"),
        ("en", "Ms. Smith", "[[mˈɪz]] Smith"),
        ("en", "No. 5", "Number 5"),
        ("en", "£5", "5 pounds"),
        ("en", "50%", "50 percent"),
        ("en", "2025-02-01", "1st February 2025"),
        ("en", "R&D", "R and D"),
    ]
    failures = 0
    for lang, src, expected in cases:
        got = normalize(src, lang)
        if got != expected:
            failures += 1
            print(f"❌ [{lang}] {src!r} → {got!r} (attendu {expected!r})")
    print(f"{'❌' if failures else '✅'} self-test : {len(cases) - failures}/{len(cases)}")
    return 1 if failures else 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Synthèse vocale Piper avec normalisation fr/en.")
    parser.add_argument("text", nargs="*", help="texte (défaut : stdin)")
    parser.add_argument("-l", "--lang", choices=sorted(RULES),
                        default=os.environ.get("PIPER_LANG", "fr"))
    parser.add_argument("-v", "--voice", default=None,
                        help="nom de voix ou chemin .onnx (défaut : par langue)")
    parser.add_argument("-o", "--out", default=None, help="fichier WAV de sortie")
    parser.add_argument("--check", action="store_true",
                        help="affiche texte normalisé + phonèmes (pas de synthèse)")
    parser.add_argument("--print-text", action="store_true",
                        help="affiche le texte normalisé avant la synthèse")
    parser.add_argument("--length-scale", type=float, default=None,
                        help="durée des phonèmes (>1 = plus lent)")
    parser.add_argument("--sentence-silence", type=float, default=None)
    parser.add_argument("--volume", type=float, default=None)
    parser.add_argument("--extra", default="", help="options piper brutes")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args(argv)

    if args.self_test:
        return self_test()

    raw = " ".join(args.text) if args.text else sys.stdin.read()
    if not raw.strip():
        parser.error("aucun texte fourni")
    text = normalize(raw, args.lang)

    voice = args.voice or DEFAULT_VOICES[args.lang]
    model = resolve_voice(voice, voices_dir())

    if args.print_text or args.check:
        print(text)
    if args.check:
        return phonemes(model, text)

    binary = piper_bin()
    out = args.out   # sans -f, piper joue l'audio directement
    cmd = [binary, "-m", str(model), "--data-dir", str(voices_dir())]
    if out:
        cmd += ["-f", out]
    if args.length_scale is not None:
        cmd += ["--length-scale", str(args.length_scale)]
    if args.sentence_silence is not None:
        cmd += ["--sentence-silence", str(args.sentence_silence)]
    if args.volume is not None:
        cmd += ["--volume", str(args.volume)]
    cmd += shlex.split(args.extra)
    cmd += ["--", text]

    rc = subprocess.run(cmd).returncode
    if rc == 0 and out and args.out:
        print(f"✅ {wav_info(Path(out))}")
    return rc


if __name__ == "__main__":
    sys.exit(main())
