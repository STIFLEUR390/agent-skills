# Piper TTS — guide

Guide de référence pour `skills/piper-tts/SKILL.md`. Le SKILL.md suffit à un
agent ; ce document garde l'installation, les détails d'implémentation, les
mesures et l'extension du pipeline.

## Installation

```bash
uv tool install --python 3.13 piper-tts        # binaire ~/.local/bin/piper
# ou, dans un venv : pip install 'piper-tts[http]'
piper --help
```

Le paquet embarque espeak-ng en bibliothèque (`libespeak-ng` compilée) : rien à
installer côté système pour la phonémisation. `ffplay` (paquet `ffmpeg`) est
utile pour écouter un WAV.

Les voix ne sont pas dans le paquet : `skills/piper-voices/scripts/piper-voices.sh bootstrap`.

## Ce que fait le script

`scripts/piper-tts.py` n'a aucune dépendance hors Piper (bibliothèque standard
seulement) et n'appelle pas espeak-ng directement. Le pipeline :

1. **découpage** : le texte est séparé sur les blocs `[[ ... ]]`, qui ne sont
   jamais modifiés ;
2. **règles** (`fr_rules` / `en_rules`) : chiffres romains, dates, ordinaux,
   décimale, devises, pourcentages, unités, abréviations numériques ;
3. **lexique** (`assets/lexicon-<lang>.json`) : remplacement mot à mot, clés les
   plus longues d'abord, insensible à la casse, frontières de mots ;
4. **appel Piper** : `piper -m VOIX --data-dir DIR [options] -- TEXTE`.

`--check` lance Piper dans un sous-processus (le python du venv, déduit du
shebang de `piper`) et affiche `phonemize(texte)` phrase par phrase, plus les
symboles absents du `phoneme_id_map` du modèle.

Mesures sur un CPU de bureau (piper-tts 1.8.0, `fr_FR-siwis-medium`) :

| Opération | Temps |
|-----------|-------|
| chargement du modèle (une fois par appel) | ≈ 0,8 s |
| synthèse | ≈ 0,1 × durée de l'audio (3 s d'audio ≈ 0,3 s) |
| `--check` (chargement + phonémisation) | ≈ 0,8 s |

Piper recharge le modèle à chaque appel : pour un livre entier, produire un
seul WAV par gros bloc plutôt que multiplier les appels, ou passer au serveur
HTTP (`python3 -m piper.http_server -m VOIX`, endpoint `/synthesize`).

## Variables d'environnement

| Variable | Défaut | Rôle |
|----------|--------|------|
| `PIPER_BIN` | `command -v piper` | binaire Piper |
| `PIPER_VOICES_DIR` | `~/.local/share/piper-voices` | répertoire des voix |
| `PIPER_VOICE` | voix de la langue | voix forcée pour tous les appels |
| `PIPER_LANG` | `fr` | langue par défaut |
| `PIPER_PYTHON` | venv déduit du shebang | python qui a `piper` installé |
| `PIPER_LEXICONS` | — | lexiques supplémentaires, séparés par `:` |

## Étendre les règles

Une règle = une substitution dans `fr_rules` / `en_rules`, testée par
`--self-test`. Exemple : lire `18-25 ans` comme une plage.

```python
t = re.sub(r"\b(\d{1,3})-(\d{1,3})\b", r"de \1 à \2", t)
```

Puis ajouter le cas au `self_test()` du script, et relancer
`scripts/piper-tts.py --self-test`. Les règles sont appliquées avant le
lexique : une règle ne doit pas produire de `[[`.

## Étendre le lexique

Une entrée = `"clé": "remplacement"`. Deux familles :

- **réécriture** : `"mail": "courriel"`, `"Mo": "mégaoctets"` — espeak relit le
  texte, la prononciation suit les règles normales de la langue ;
- **injection IPA** : `"WC": "[[vesˈe]]"`, `"GitHub": "[[ɡitˈœb]]"` — la
  prononciation est figée, indépendante de la voix.

Préférer l'injection quand espeak ne sait pas lire la graphie (sigles, mots
anglais, noms propres), la réécriture quand le mot français existe.

Un lexique personnel peut vivre hors du skill :

```bash
cat > ~/mots.json <<'JSON'
{"words": {"Kubernetes": "[[kubɛʁnɛtɛs]]", "Verstappen": "Verstapène"}}
JSON
PIPER_LEXICONS=~/mots.json scripts/piper-tts.py -l fr -o a.wav "texte"
```

## Qualité par langue

- **Français** : Piper est bon sur la prosodie et les liaisons, faible sur les
  mots anglais (phonèmes anglais dans une voix française) et sur les graphies
  `ill`/`gn`/`qu+i`. Le lexique couvre les anglicismes courants et le
  vocabulaire technique.
- **Anglais** : bon, sauf les homographes (verbe/nom), que seule une injection
  locale corrige. `en_GB-*` phonétise en RP ; pour `en_US`, les symboles
  diffèrent — vérifier au `--check`.
- `low` (16 kHz) : plus rapide, plus métallique, échoue plus souvent sur les
  consonnes finales. Pour un livrable, `medium` minimum.

## Régler le débit

| `--length-scale` | Effet |
|------------------|-------|
| 0.85 | rapide, style annonce |
| 1.0 | débit du modèle, souvent un peu pressé en français |
| 1.1 | narration confortable (recommandé) |
| 1.3+ | lourd, à éviter sauf besoin |

`--sentence-silence 0.3` aère les phrases ; `--volume 1.3` compense un
enregistrement faible. `--extra "--noise-w-scale 0.9"` régularise le rythme des
phonèmes (moins de variation entre phrases).

## Dépannage

| Symptôme | Diagnostic |
|----------|------------|
| `ModuleNotFoundError: No module named 'piper'` | `--check` lancé avec le python système : `PIPER_PYTHON=\~/.local/share/uv/tools/piper-tts/bin/python` |
| WAV de 0 s | modèle tronqué → skill **piper-voices** (`check`) |
| phonèmes anglais | mot absent du lexique, ajouter une entrée `[[ ]]` |
| `[[` lu à voix haute | bloc non fermé, ou `--` mangé par un shell |
| tout est chuchoté/saturé | `--volume` trop haut, ou `--no-normalize` hérité |
| voix absente | `PIPER_VOICES_DIR` non exporté |

## MCP `piper-tts`

Le skill est aussi exposable en MCP local ([piper-mcp](https://github.com/STIFLEUR390/piper-mcp)) :
le serveur appelle ce script pour normaliser, donc les règles et le lexique restent
la seule source de vérité. Côté agent, la détection est simple : si la liste
d'outils contient `tts_generate` / `tts_phonemes` / `tts_voices`, les prendre ;
sinon, lancer le script.

```json
{ "mcpServers": { "piper-tts": {
  "command": "uv",
  "args": ["run", "--directory", "/chemin/vers/piper-mcp", "piper-mcp"],
  "env": { "PIPER_VOICES_DIR": "/home/moi/.local/share/piper-voices",
           "PIPER_OUTPUT_DIR": "/home/moi/piper-out" } } } }
```

Les chemins doivent être **absolus** (un `.../piper-voices` recopié tel quel donne
« aucune voix »). `normalized: false` dans la réponse = le serveur n'a pas trouvé
le skill : repasser par le script, sinon rien n'est corrigé.

## Références

- Piper (dépôt amont, CLI, API) : https://github.com/OHF-Voice/piper1-gpl
- Serveur MCP local : https://github.com/STIFLEUR390/piper-mcp
- Voix et `MODEL_CARD` : https://huggingface.co/rhasspy/piper-voices
- Alphabet espeak-ng : https://github.com/espeak-ng/espeak-ng/blob/master/docs/phonemes.md
- Échantillons pour choisir une voix : https://rhasspy.github.io/piper-samples/
