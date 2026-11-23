---
name: piper-tts
description: >
  Générer de l'audio à partir de texte en français ou en anglais avec Piper TTS
  local (installé, hors ligne, sans clé d'API), en corrigeant les mots qu'espeak
  prononce mal : nombres, dates, unités, sigles, abréviations, anglicismes et
  homographes anglais. Utiliser quand l'utilisateur veut une voix off, une
  narration, un doublage, une lecture audio d'un texte, un fichier WAV lisible
  par un humain, ou tester la prononciation d'un mot en français ou en anglais.
  Inclut un script prêt à l'emploi, deux lexiques de prononciation et les
  dictionnaires de pièges (homographes, sigles, mots techniques). Ne PAS
  utiliser pour de la reconnaissance vocale, du clonage de voix, de la musique,
  ou un TTS cloud (ElevenLabs, OpenAI, Azure).
license: MIT
compatibility: "Claude Code, Codex, OpenCode, Pi, omp"
allowed-tools: Read Write Glob Grep Bash
user-invocable: true
---

# Piper TTS — narration française et anglaise

Piper est un moteur de synthèse vocale neuronal qui tourne en local : rapide,
hors ligne, aucun coût par caractère. Il phonémise le texte avec **espeak-ng**,
qui se trompe sur beaucoup de choses écrites en chiffres, en sigles ou en
anglicismes — et qui **ne lit aucun dictionnaire** : il n'existe pas de fichier
de prononciation utilisateur pour Piper. La seule correction fiable est
l'injection de phonèmes IPA dans le texte, avec les blocs `[[ ... ]]` que Piper
reconnaît. Ce skill automatise cette correction.

## Prérequis

```bash
command -v piper                          # binaire visible
echo "$PIPER_VOICES_DIR"                  # ~/.local/share/piper-voices
ls "$PIPER_VOICES_DIR"/*.onnx | head      # modèles présents
```

Piper s'installe avec `uv tool install piper-tts` (ou `pip install piper-tts`),
les voix avec le skill **piper-voices**. Pour lire un audio produit, ffplay est
nécessaire (`ffplay fichier.wav`).

## Quand utiliser ce skill

- L'utilisateur demande une voix off, une narration, un podcast, un audiobook,
  une lecture à voix haute d'un texte, ou un WAV à écouter
- Il faut du français ou de l'anglais, hors ligne, en local
- Il faut vérifier comment un mot, un sigle ou une date est prononcé
- Il faut une prononciation stable et reproductible (pas un modèle aléatoire)

## Quand NE PAS utiliser ce skill

- Reconnaissance vocale, transcription, sous-titres (c'est de l'ASR)
- Clonage de voix, imitation d'une personne réelle, changement de locuteur
- Musique, effets sonores, traitement d'un audio existant
- TTS cloud avec voix premium ou multilingue dans une seule phrase
- Plus de 40 langues : Piper en couvre beaucoup, mais ce skill ne normalise que
  `fr` et `en` (étendre `RULES` et un lexique reste possible)

## Processus

1. **Préparer le texte** : du texte brut, ponctué. Une phrase = une ligne idéalement.
   Supprimer markdown, URLs nues, balises (`-> `/ `## `/ `**`), qu'un humain ne
   prononcerait pas ; garder les sigles et les nombres, ils sont normalisés.
2. **Choisir la langue et la voix** : `-l fr` (défaut) ou `-l en`. La voix par
   défaut est `fr_FR-siwis-medium` / `en_GB-alan-medium`.
3. **Synthétiser** :

   ```bash
   scripts/piper-tts.py -l fr -o sortie.wav "Bonjour, ceci est un test."
   ```

4. **Vérifier** : le script affiche `✅ sortie.wav (3.1s)`. Une durée de 0 s ou un
   fichier de moins de 20 Ko signale un modèle tronqué, pas un problème de texte.
5. **Contrôler la prononciation** d'un passage douteux avant de livrer :

   ```bash
   scripts/piper-tts.py -l fr --check "le XXe siècle, 12,50 €, un GPU"
   ```

   Il imprime le texte normalisé puis les phonèmes réels du modèle.

## Le script

`scripts/piper-tts.py` fait trois choses : normalisation par règles (chiffres,
dates, unités, sigles), application du lexique JSON de la langue, puis appel à
Piper. Le texte entre `[[ ]]` n'est jamais réécrit.

| Option | Effet |
|--------|-------|
| `-l fr` / `-l en` | langue (défaut : `fr`) |
| `-v NOM` | voix : `fr_FR-tom-medium`, `en_GB-cori-high`, ou un chemin `.onnx` |
| `-o FICHIER` | écrit le WAV ; sans `-o`, Piper joue directement |
| `--check` | texte normalisé + IPA, sans synthèse |
| `--print-text` | affiche le texte normalisé puis synthétise |
| `--length-scale 1.2` | plus lent (>1) ; 0.9 pour accélérer |
| `--sentence-silence 0.4` | secondes de silence entre phrases |
| `--volume 1.5` | volume (>1 plus fort) |
| `--extra "--cuda"` | options Piper brutes |
| `--self-test` | vérifie les règles et le lexique (à lancer après édition) |

Sans argument texte, le script lit **stdin** :

```bash
cat chapitre.txt | scripts/piper-tts.py -l fr -o chapitre.wav
printf 'Hello world.' | scripts/piper-tts.py -l en -o hello.wav
```

Variables lues : `PIPER_BIN`, `PIPER_VOICES_DIR`, `PIPER_VOICE`, `PIPER_LANG`,
`PIPER_PYTHON`, `PIPER_LEXICONS`.

## Corriger une prononciation

Ordre de préférence — du plus simple au plus précis :

1. **Le mot est déjà dans le lexique** → rien à faire.
2. **Réécrire l'orthographe** de façon que espeak tombe juste. Ça dépend de la
   langue et des règles de lecture : `courriel` pour *e-mail*, `mégaoctets` pour
   *Mo*. Vérifier avec `--check` : si les phonèmes ne bougent pas comme prévu,
   passer à l'étape 3.
3. **Injecter l'IPA** : `[[kɥijˈɛʁ]]` pour *cuillère*. C'est le seul mécanisme
   garanti, il court-circuite espeak et fonctionne avec n'importe quelle voix.
4. **Ne jamais inventer un IPA** : demander les phonèmes au modèle
   (`--check`), ou réécrire le mot phonétiquement en français courant.

Pour obtenir l'IPA d'un mot, les deux chemins donnent des conventions
différentes — utiliser celui de la voix cible :

```bash
# les phonèmes exacts qu'utilisera la voix (le plus sûr)
scripts/piper-tts.py -l fr --check "cuillère"

# alphabet espeak-ng, si le paquet espeak-ng est installé
espeak-ng -v fr --ipa=3 -q "cuillère"
```

Notes sur le format IPA de Piper : l'accent est `ˈ` (devant la syllabe), la
nasalisation est un tilde **combiné** (`ɑ̃`, `ɔ̃`, `ɛ̃`, `œ̃`), et le français
utilise `ʁ ɥ ʃ ʒ ɲ ɛ ɔ ɑ` — pas `r` ni `e` pour un *é* fermé (`e` convient pour
*é* en pratique, `ɛ` pour *è*).

### Mesures utiles

Corrections déjà en place, vérifiées sur `fr_FR-siwis-medium` et
`en_GB-alan-medium` (Piper 1.8.0) :

| Entrée | espeak seul | après normalisation |
|--------|-------------|---------------------|
| `M. Dupont` | « èm » | Monsieur Dupont |
| `2e étage` | « deuxième » avec un `ə` parasite | 2ème (deuzième) |
| `50 %` | « cinquante pour cent » correct | — |
| `5 €` | « cinq euro » (singulier) | cinq euros |
| `01/02/2025` | chiffres énumérés | premier février 2025 |
| `3/4` | « trois quatre » | trois quarts |
| `XXe siècle` | bruit | 20ème (vingtième) siècle |
| `WC` | « double-vé cé cé » | vécés (vésé) |
| `cuillère` | « kuyière » | kɥijɛʁ |
| `le week-end` | phonèmes anglais | ouikende |
| `Ms. Smith` (en) | « èm-èss » | mɪz |
| `No. 5` (en) | « no five » | Number five |
| `10/12/2025` (en) | « ten slash twelve… » | 12th October 2025 |
| `Henry VIII` (en) | « roman eight » | Henry eight |

Les cas restants sont listés dans [references/prononciation-fr.md](references/prononciation-fr.md)
et [references/prononciation-en.md](references/prononciation-en.md) : homographes
français (`fils`, `tous`, `plus`, `os`), homographes anglais (`close`, `lead`,
`record`, `read`), sigles, vocabulaire technique et pièges de graphie (`gn`,
`ill`, `ail`, `eill`, `œ`).

## Ajouter un mot au lexique

`assets/lexicon-fr.json` et `assets/lexicon-en.json` sont des dictionnaires
`"mot": "remplacement"`. Le remplacement est soit une réécriture, soit un bloc
`[[ IPA ]]`.

```json
{
  "words": {
    "AWS": "[[e a dubləve ɛs]]",
    "courriel": "courriel",
    "Claude": "[[klod]]"
  }
}
```

Règles du moteur de remplacement :

- insensible à la casse, mais sensible aux **frontières de mots** (`Pr` ne
  touche pas `prix`) ; les clés les plus longues passent d'abord
- toute clé contenant un espace ou une ponctuation finale (`M.`) est traitée
  avec les mêmes frontières de mots
- le texte entre `[[ ]]` est ignoré

Pour un lexique personnel, sans modifier ce skill :

```bash
PIPER_LEXICONS=~/mes-mots.json scripts/piper-tts.py -l fr -o a.wav "texte"
```

Après toute édition : `scripts/piper-tts.py --self-test` (il doit afficher
`✅ self-test`), puis `--check` sur le mot ajouté.

## Choisir la voix

| Langue | Voix installées | Usage |
|--------|-----------------|-------|
| fr | `fr_FR-siwis-medium` (défaut) | claire, neutre |
| fr | `fr_FR-tom-medium`, `fr_FR-gilles-low` | voix masculine |
| fr | `fr_FR-upmc-medium`, `fr_FR-mls-medium` | alternatives |
| fr | `fr_FR-siwis-low`, `fr_FR-mls_1840-low` | rapides, pour brouillon |
| en | `en_GB-alan-medium` (défaut) | anglais britannique neutre |
| en | `en_US-lessac-medium` | anglais américain |

`en_GB-*` utilise la phonétisation **RP** (`espeak.voice: en-gb-x-rp`) : les IPA
de `references/prononciation-en.md` sont notés dans cette variété. Pour une voix
`en_US`, les symboles diffèrent (`ɒ` devient `ɑː`, pas de `ɐ` final) : en cas de
doute, injecter `[[ ]]` avec les phonèmes renvoyés par `--check` sur cette voix.

## Paramètres de prosodie

`--length-scale 1.1` ralentit de ~10 % : en français, 1.05 à 1.15 rend une
narration moins mécanique. `--sentence-silence 0.3` aère les phrases.
`--noise-w-scale` n'est pas exposé par le script : passer par
`--extra "--noise-w-scale 1.0"` pour un débit plus régulier.

## Validation

Avant de livrer un audio :

- `scripts/piper-tts.py --self-test` renvoie `✅`
- le WAV existe, dure plus de 0 s (`✅ fichier.wav (Ns)`), taille > 20 Ko
- les nombres, dates, devises et sigles du texte sont ceux transformés par
  `--print-text`
- aucun bloc `[[ ]]` ne reste dans le texte affiché : un `[[` non fermé est lu
  littéralement par espeak
- les noms propres rares ont un `--check` relu à l'oreille ou à l'IPA
- longueur cohérente : ~150 mots par minute à `--length-scale 1.0`

## Erreurs courantes

| Symptôme | Cause | Correctif |
|----------|-------|-----------|
| `piper introuvable` | binaire absent du PATH | `uv tool install piper-tts`, `export PIPER_BIN=...` |
| `voix 'x' absente de …` | modèle non téléchargé | skill **piper-voices** : `scripts/piper-voices.sh install x` |
| `ModuleNotFoundError: No module named 'piper'` | script lancé avec le python système | utiliser `scripts/piper-tts.py` (il trouve seul le venv) ou `PIPER_PYTHON` |
| WAV de 0 s ou quelques octets | `.onnx` tronqué | re-télécharger la voix (`piper-voices.sh check`) |
| phonèmes anglais dans un texte français | mot anglais non couvert | ajouter le mot au lexique avec `[[ ]]` |
| `[[ ... ]]` lu à voix haute | bloc non fermé ou espace parasite | fermer le bloc, vérifier avec `--check` |
| voix qui prononce « èm » pour `M.` | normalisation contournée (texte dans `[[ ]]`) | mettre `Monsieur` en clair |

## Fichiers

- `scripts/piper-tts.py` — normalisation + synthèse (aucune dépendance hors Piper)
- `assets/lexicon-fr.json`, `assets/lexicon-en.json` — corrections mesurées
- `references/prononciation-fr.md` — homographes, graphies, sigles, vocabulaire
- `references/prononciation-en.md` — homographes, variante RP, dates et unités
