# Skill Health Checker — Guide d'utilisation

## Aperçu

Le Skill Health Checker est un outil CLI qui audite tous les skills installés
sur tes agents IA. Il combine inventaire, sécurité, tokens et doublons dans
un seul rapport.

Inspiré par [skills-janitor](https://github.com/khendzel/skills-janitor),
adapté pour notre setup multi-agents (Pi + Claude Code + Codex + omp + OpenCode).

## Installation

```bash
# Depuis le repo skill-manager
bash skills/skill-creator/scripts/deploy.sh skill-health-checker

# Ou directement
cp -r skills/skill-health-checker/ ~/.pi/agent/skills/
```

## Utilisation rapide

```bash
# Rapport complet
bash scripts/health-check.sh

# Inventaire rapide
bash scripts/health-check.sh --brief

# Scan sécurité seul
bash scripts/health-check.sh --security

# Tokens seul
bash scripts/health-check.sh --tokens

# Doublons seul
bash scripts/health-check.sh --dupes

# JSON pour pipeline
bash scripts/health-check.sh --json
```

## Options

| Option | Description |
|--------|-------------|
| `--brief` | Inventaire minimal (nombre de skills par agent) |
| `--json` | Sortie JSON machine-readable |
| `--security` | Scan sécurité seul |
| `--tokens` | Estimation coût token seul |
| `--dupes` | Détection doublons seul |
| `--scope user` | Skills utilisateur uniquement |
| `--scope project` | Skills projet uniquement |
| `--scope all` | Tous les scopes (défaut) |
| `--budget N` | Budget token pour le % (défaut: 200000) |

## Agents couverts

| Agent | Chemin |
|-------|--------|
| Pi | `~/.pi/agent/skills/` |
| Claude Code | `~/.claude/skills/` |
| Codex | `~/.agents/skills/` |
| OpenCode | `~/.config/opencode/skills/` |
| omp | `~/.omp/agent/skills/` |
| Plugins Claude | `~/.claude/plugins/marketplaces/*/skills/` |
| Sources Claude | `~/.claude/sources/*/skills/` |

## Rapport de sécurité

Le scan security est **heuristique** — il détecte des patterns suspects,
pas des preuves de malice.

### Verdicts

| Verdict | Signification |
|---------|---------------|
| `PASS` | Aucun pattern suspect |
| `REVIEW` | Pattern moyen — lire avant de faire confiance |
| `RISK` | Pattern haut — nécessite vérification manuelle |

### Patterns détectés

#### Markdown (SKILL.md)
- `inj-ignore` — "ignore previous instructions" (injection classique)
- `inj-conceal` — "don't tell the user" (cacher l'activité)
- `inj-secrecy` — "secretly run/send" (directive de secret)
- `inj-newrole` — "you are no longer" (override de rôle)
- `uni-hidden` — Unicode zero-width / RTL override
- `md-htmlcomment` — Instructions dans commentaires HTML
- `md-b64` — Blob base64 décodable (smuggling)

#### Scripts
- `sh-curlpipe` — curl/wget piped into shell
- `sh-b64exec` — decode-and-execute
- `sh-creds` — Accès aux credentials (~/.ssh, ~/.aws, etc.)
- `sh-shortener` — URL raccourcies (bit.ly, tinyurl, etc.)
- `sh-http` — Appels HTTP sans TLS

## Estimation tokens

L'estimation est simple : `len(text) / 4` (≈4 caractères par token).

- **Always-loaded** = description (permanente dans le contexte)
- **On-trigger** = body (chargé seulement quand le skill s'active)

Le budget par défaut est 200k tokens (taille typique d'une fenêtre de contexte).

## Exemples de sortie

### --brief

```
=== Skill Health Checker ===
Skills found: 47 across 3 agents

  pi:           32 skills
  claude:       12 skills
  claude/plugin: 3 skills
```

### --security

```
=== Security Scan ===
Scanned: 47 skills | RISK: 1 | REVIEW: 2 | PASS: 44

[RISK] sketchfab-tools (user/pi)
    HIGH   Instruction-override phrase
           README.md: "...ignore previous instructions and..."

[REVIEW] web-scraper (user/claude)
    MEDIUM Plain-HTTP call
           scripts/fetch.sh: curl http://example.com/api
```

## Différence avec skills-janitor

| Aspect | skills-janitor | skill-health-checker |
|--------|---------------|---------------------|
| Agents | Claude Code + Codex | Pi + Claude + Codex + omp + OpenCode |
| Plugin support | ✅ Claude plugins | ✅ Claude plugins + sources |
| Security | ✅ Heuristiques | ✅ Mêmes heuristiques |
| Tokens | Via transcripts | Estimation statique |
| Usage | Via history.jsonl | Pas encore (futur) |
| TUI Swipe | ✅ Tinder-style | ❌ Pas encore (futur) |
| MCP servers | ✅ (v1.7) | ❌ Pas encore (futur) |
| Dépendances | Bash + Python3 | Bash + Python3 |
