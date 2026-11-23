---
name: piper-voices
description: >
  Installer, inventorier et réparer les voix ONNX de Piper TTS en local :
  téléchargement depuis le dépôt officiel avec vérification md5, choix des
  voix françaises et anglaises, répertoire partagé, test de synthèse, et
  réparation d'un modèle tronqué. Utiliser quand Piper n'est pas encore
  installé, quand une voix manque ou renvoie une erreur de chargement, quand il
  faut lister les voix disponibles, ou changer de voix française ou anglaise.
  Ne PAS utiliser pour fabriquer ou entraîner un modèle, pour du TTS cloud, ou
  pour de la reconnaissance vocale.
license: MIT
compatibility: "Claude Code, Codex, OpenCode, Pi, omp"
allowed-tools: Read Write Glob Grep Bash
user-invocable: true
---

# Piper voices — installer et gérer les modèles ONNX

Une voix Piper est **deux fichiers** de même nom : `NOM.onnx` (le modèle) et
`NOM.onnx.json` (phonèmes, locuteurs, réglages espeak). Les deux sont
indissociables. Ce skill les télécharge depuis le dépôt officiel Hugging Face,
vérifie leur intégrité et les range dans un répertoire commun, pour que `piper`
et le skill **piper-tts** les trouvent partout.

## Quand utiliser ce skill

- Piper n'est pas installé, ou une voix manque (`voix 'x' absente de …`)
- Un modèle ne se charge pas : `InvalidProtobuf`, WAV de 0 seconde, fichier
  téléchargé à moitié
- Il faut la liste des voix disponibles en français ou en anglais
- Il faut changer la voix par défaut, ou savoir combien de locuteurs a une voix
- Il faut installer Piper sur une nouvelle machine

## Quand NE PAS utiliser ce skill

- Entraîner, fine-tuner ou exporter un modèle maison (`python3 -m piper.train`)
- Générer l'audio à partir de texte : c'est le skill **piper-tts**
- TTS cloud (ElevenLabs, OpenAI, Azure), reconnaissance vocale, clonage de voix

## Installation

```bash
# le moteur (binaire `piper`)
uv tool install --python 3.13 piper-tts     # ou : pip install piper-tts
# les voix, dans ~/.local/share/piper-voices
scripts/piper-voices.sh bootstrap
```

`bootstrap` installe `fr_FR-siwis-medium` (français) et `en_GB-alan-medium`
(anglais britannique), puis affiche les variables à mettre dans `~/.bashrc` :

```bash
export PIPER_VOICES_DIR="$HOME/.local/share/piper-voices"
export PIPER_VOICE="fr_FR-siwis-medium"   # voix par défaut
```

Sans ces variables, `piper` ne cherche les voix que dans le répertoire courant :
c'est la cause n°1 des « modèle introuvable ».

## Commandes du script

| Commande | Effet |
|----------|-------|
| `list [regex]` | voix disponibles, avec qualité, taille, nombre de locuteurs |
| `installed` | voix présentes dans le répertoire, avec leur taille |
| `install NOM...` | télécharge, vérifie md5, installe le `MODEL_CARD` |
| `bootstrap` | installe les deux voix par défaut |
| `check [NOM...]` | md5 + chargement réel par Piper (toutes les voix par défaut) |
| `dir` | affiche le répertoire des voix |

```bash
scripts/piper-voices.sh list '^fr_FR'      # toutes les voix françaises
scripts/piper-voices.sh install fr_FR-tom-medium en_GB-cori-high
scripts/piper-voices.sh check              # contrôle tout ce qui est installé
```

Les variables lues : `PIPER_VOICES_DIR`, `PIPER_BIN`, `PIPER_PYTHON`,
`XDG_CACHE_HOME` (index `voices.json` mis en cache dans `~/.cache/piper-voices`).

Si le MCP `piper-tts` est disponible dans ton hôte, son outil `tts_voices()` donne
le même inventaire (répertoire, voix par défaut, tailles) sans lancer le script.
Il ne télécharge rien : `install` reste ici.

## Quel fichier est « cassé » ?

Les modèles pèsent 25 à 80 Mo. Un `.onnx` de 55 Mo alors que l'index en annonce
63 est **tronqué** : Piper échoue au chargement (`InvalidProtobuf`). Le script
garde le téléchargement dans un `.part`, compare la taille **et** le md5 à
l'index officiel, puis déplace le fichier. Un fichier refusé est supprimé : rien
de silencieusement corrompu ne reste dans le répertoire.

Un md5 différent d'un fichier complet n'est pas une corruption : les voix sont
réentraînées de temps en temps, ta copie est simplement une révision
antérieure. `check` l'affiche en `⚠️` et propose `install NOM` pour mettre à
jour. Seul un modèle qui ne se charge plus est une erreur.

## Quelles voix pour quoi

| Langue | Voix | Qualité | Notes |
|--------|------|---------|-------|
| fr | `fr_FR-siwis-medium` | medium | défaut, voix féminine neutre |
| fr | `fr_FR-tom-medium` | medium | voix masculine |
| fr | `fr_FR-gilles-low` | low | rapide, dépannage |
| fr | `fr_FR-upmc-medium` | medium | 2 locuteurs (`-s 0/1`) |
| fr | `fr_FR-mls-medium` | medium | 125 locuteurs (`-s N`) |
| fr | `fr_FR-siwis-low`, `fr_FR-mls_1840-low` | low | brouillon, tests rapides |
| en | `en_GB-alan-medium` | medium | défaut, anglais britannique (RP) |
| en | `en_GB-cori-high` | high | plus lent, mieux articulé |
| en | `en_US-lessac-medium` | medium | anglais américain |
| en | `en_GB-vctk-medium` | medium | 111 locuteurs |

`low` = 16 kHz, plus léger et plus rapide mais plus métallique ; `medium` =
22 kHz, le bon compromis ; `high` = 22 kHz, plus de paramètres, plus lent.
Changer de voix ne demande aucun autre réglage : `-v fr_FR-tom-medium`.

### Multi-locuteurs

```bash
piper -m fr_FR-upmc-medium --data-dir "$PIPER_VOICES_DIR" -s 1 -f x.wav -- "Bonjour"
# via le skill piper-tts :
scripts/piper-tts.py -v fr_FR-upmc-medium --extra "-s 1" -o x.wav "Bonjour"
```

Les noms de locuteurs sont dans `NOM.onnx.json` (`speaker_id_map`).

## Ajouter une voix ailleurs

`--data-dir` accepte plusieurs chemins, et le nom de la voix doit être le
**nom de fichier sans `.onnx`** :

```bash
piper -m ma-voix.onnx -f x.wav -- "test"                 # chemin direct
piper -m ma-voix --data-dir ~/autre/dossier -f x.wav -- "test"
```

Une voix trouvée sur internet doit être accompagnée de son `.onnx.json` : sans
lui, Piper invente la table des phonèmes et le résultat est inaudible.

## Licences

Le moteur est GPL-3.0-or-later ; les **voix** ne sont pas couvertes par cette
licence. Chaque voix a un `MODEL_CARD` (téléchargé par le script sous
`MODEL_CARD-NOM`) qui nomme la licence du jeu de données d'entraînement, et
souvent la voix de base dont elle est un fine-tune. Beaucoup de voix anglaises
dérivent de `lessac`, réservé à la recherche, non commercial. Avant un usage
commercial ou une redistribution, lire le `MODEL_CARD` — et non la licence du
moteur.

## Validation

- `scripts/piper-voices.sh check` : tous les fichiers en `✅`
- `scripts/piper-voices.sh installed` liste au moins une voix `fr` et une `en`
- `scripts/piper-tts.py -l fr -o /tmp/t.wav "Bonjour, test."` produit un WAV > 20 Ko
- `echo "$PIPER_VOICES_DIR"` non vide dans un terminal neuf (bashrc chargé)
- après un `install`, le script affiche `✅ test de synthèse OK`

## Erreurs courantes

| Symptôme | Cause | Correctif |
|----------|-------|-----------|
| `InvalidProtobuf` / WAV vide | `.onnx` tronqué | `check`, puis `install NOM` |
| `.onnx.json` manquant | copie incomplète | `install NOM` (télécharge les deux) |
| `voix 'x' absente de …` | mauvais nom, ou mauvais répertoire | `installed`, `dir` |
| `piper: command not found` | PATH | `uv tool install piper-tts`, `export PIPER_BIN=...` |
| `uv tool install` très lent | compilation des wheels | normal la première fois (≈3 min) |
| voix qui parle une autre langue | nom de voix pris pour un chemin | utiliser `-m NOM` + `--data-dir` |
