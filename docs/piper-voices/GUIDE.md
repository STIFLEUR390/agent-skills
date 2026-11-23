# Piper voices — guide

Guide de référence pour `skills/piper-voices/SKILL.md` : installation du moteur
et des modèles, organisation du répertoire, vérification d'intégrité, dépannage.

## Ce qu'installe quoi

| Composant | Origine | Taille |
|-----------|---------|--------|
| moteur `piper` + espeak-ng embarqué | `uv tool install piper-tts` | ~200 Mo (onnxruntime, numpy) |
| une voix `medium` | Hugging Face `rhasspy/piper-voices` | 60–80 Mo (`.onnx` + `.onnx.json`) |
| une voix `low` | idem | 25–35 Mo |
| `voices.json` (index) | idem, racine du dépôt | ~1 Mo, caché dans `~/.cache/piper-voices` |

`uv tool install` compile/résout les wheels au premier passage : comptez
quelques minutes, puis quelques secondes pour une réinstallation.

## Pourquoi `~/.local/share/piper-voices`

Piper résout `-m NOM` en `Path(data_dir)/NOM.onnx`, et `--data-dir` vaut le
répertoire courant par défaut. Deux conséquences :

- sans `export PIPER_VOICES_DIR` **et** sans `--data-dir`, il faut être dans le
  répertoire des voix à chaque appel ;
- les fichiers doivent rester **à plat** dans ce répertoire (pas de
  sous-dossier par langue) pour que `-m fr_FR-siwis-medium` fonctionne.

C'est un chemin XDG standard : il survit aux mises à jour de `uv`, aux
changements de venv, et il est sauvegardable.

## Vérification d'intégrité

Le script interroge `voices.json`, qui contient pour chaque fichier
`size_bytes` et `md5_digest` :

```bash
curl -fsSL https://huggingface.co/rhasspy/piper-voices/resolve/main/voices.json \
  | python3 -c 'import json,sys; v=json.load(sys.stdin)["fr_FR-siwis-medium"]["files"]; print(json.dumps(v, indent=1))'
```

Deux niveaux de contrôle :

1. **md5** : identique → fichier officiel ; différent → révision antérieure
   (les voix sont réentraînées, ex. base `lessac` remplacée par `rdh`).
2. **chargement réel** : un fichier complet mais d'une autre révision reste
   valide ; un fichier tronqué échoue dans onnxruntime
   (`InvalidProtobuf`, `GetFileSize`). Le script lance donc `piper` sur chaque
   voix (`smoke_one`) — c'est le seul test qui prouve qu'un modèle peut servir.

Un `.onnx` sans `.onnx.json` ou l'inverse est inutilisable : `install NOM` les
télécharge toujours par paire.

## Verrouiller une version

Les voix sont réentraînées sans changer de nom (même comportement que les
checkpoints amont). Pour figer une révision, prendre le tag git du dépôt dans
l'URL :

```bash
curl -fsSL -o fr_FR-siwis-medium.onnx \
  "https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/fr/fr_FR/siwis/medium/fr_FR-siwis-medium.onnx"
```

Vérifier alors le md5 contre `voices.json` à la même révision, pas contre
`main`. En production, archiver les deux fichiers avec l'audio produit : sans
eux, le rendu n'est pas reproductible.

## Multi-locuteurs

`fr_FR-upmc-medium` expose 2 locuteurs, `fr_FR-mls-medium` 125,
`en_GB-vctk-medium` 111. `speaker_id_map` dans le `.onnx.json` associe un nom à
un id :

```bash
python3 -c 'import json;print(json.load(open("fr_FR-upmc-medium.onnx.json"))["speaker_id_map"])'
piper -m fr_FR-upmc-medium --data-dir "$PIPER_VOICES_DIR" -s 1 -f x.wav -- "Bonjour"
```

Le nombre de locuteurs ne change ni le débit ni la qualité, seulement le timbre.

## Licences des voix

Le moteur est GPL-3.0-or-later. Les modèles ne sont pas couverts par cette
licence : chaque `MODEL_CARD` nomme la licence du corpus d'entraînement et, le
cas échéant, la voix de base utilisée en fine-tune. Beaucoup de voix anglaises
descendent de `lessac` (usage recherche, non commercial) ; les nouvelles voix
partent de bases permissives (`nl_BE-rdh-medium` CC0,
`en_US-hifi_tts_92-medium` CC BY 4.0). Le script conserve le `MODEL_CARD` sous
`MODEL_CARD-NOM` : le garder avec les fichiers en cas de redistribution.

## Dépannage réseau

| Symptôme | Cause | Correctif |
|----------|-------|-----------|
| `curl: (22) 404` | nom mal orthographié (`fr-fr-siwis` au lieu de `fr_FR-siwis-medium`) | `list` puis copier le nom exact |
| téléchargement à 0,3 Mo/s | Hugging Face bridé sans compte | `HF_TOKEN` + `curl -H "Authorization: Bearer $HF_TOKEN"` |
| coupure au milieu | réseau instable | relancer `install`, le `.part` est réécrit |
| md5 refusé après plusieurs essais | index mis à jour pendant le téléchargement | relancer (l'index est refetché) |

## Références

- Voix et licences : https://huggingface.co/rhasspy/piper-voices
- Échantillons audio : https://rhasspy.github.io/piper-samples/
- Moteur : https://github.com/OHF-Voice/piper1-gpl
