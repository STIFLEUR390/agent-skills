# Skill Health Checker — Guide d'utilisation

## Aperçu

Le Skill Health Checker est un outil CLI qui audite tous les skills installés
sur tes agents IA. Il combine inventaire, sécurité, tokens et doublons dans
un seul rapport. Un skill symlinké dans 5 agents est compté et analysé une
seule fois (dédup par realpath).

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

# Lint frontmatter
bash scripts/health-check.sh --lint

# Auto-fix (dry-run)
bash scripts/health-check.sh --fix

# Auto-fix (appliquer)
bash scripts/health-check.sh --fix --apply
```

## Options

| Option | Description |
|--------|-------------|
| `--brief` | Inventaire minimal (nombre de skills par agent) |
| `--json` | Sortie JSON machine-readable |
| `--security` | Scan sécurité seul |
| `--tokens` | Estimation coût token seul |
| `--dupes` | Détection doublons seul |
| `--lint` | Lint frontmatter (quality checks) |
| `--fix` | Auto-fix commun (dry-run par défaut) |
| `--apply` | Appliquer les fixes (avec `--fix`) |
| `--audit` | Audit via skills.sh API (nos skills) |
| `--audit-all` | Audit tous les skills via l'API |
| `--token <TOKEN>` | Token Vercel OIDC pour l'API |
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

## Comportement

### Déduplication

Un même skill symlinké dans plusieurs agents est compté **une seule fois**.
Le rapport affiche :
- `Unique skills` : nombre de skills physiques
- `Installed copies` : nombre total d'emplacements (symlinks inclus)

Exemple : `graphify` dans Pi + Claude + Codex + opencode = 1 skill unique, 4 copies.

### Sécurité — filtrage des faux positifs

Le scan security filtre automatiquement :
- Les commentaires HTML dans les blocs de code (```` ``` ````)
- Les commentaires courts (< 50 caractères) — annotations légitimes
- Les commentaires contenant des attributs CSS/HTML (width, class, data-, etc.)
- Les balises HTML dans la documentation (div, span, img, etc.)

Seuls les commentaires HTML longs et suspects sont flaggés.

### Tokens — regroupement par nom

Le classement token regroupe les copies d'un même skill. `talking-head-recut`
installé dans 3 agents apparaît une fois avec "Agents: .agents, .claude, agent".

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
- `md-htmlcomment` — Instructions dans commentaires HTML (> 50 chars, filtré)
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
Unique skills: 85 | Installed copies: 163 across 5 agents

  .agents: 41 skills
  .claude: 47 skills
  agent:   42 skills
  claude:  20 skills
  opencode: 13 skills
```

### --security

```
=== Security Scan ===
Scanned: 85 unique skills | RISK: 0 | REVIEW: 2 | PASS: 83

[REVIEW] hyperframes-cli (.agents, .claude, agent)
    MEDIUM HTML comment with content
           references/init-and-scaffold.md
```

### --tokens

```
=== Token Cost Estimate ===
Budget: 200,000 tokens
Total:  214,838 tokens (107.4% of budget)

Skill                               Agents               Tokens
-----------------------------------------------------------------
talking-head-recut                  .agents, .claude, agent  16328
graphify                            .agents, .claude, agent, opencode  10098
slideshow                           .agents, .claude, agent   8396
```

### --dupes

```
=== Duplicate Detection ===

--- Name Collisions (8) ---
  graphify
    [agent] /home/user/.pi/agent/skills/graphify
    [.claude] /home/user/.claude/skills/graphify
    [.agents] /home/user/.agents/skills/graphify
    [opencode] /home/user/.config/opencode/skills/graphify

--- Description Overlap (2) ---
  [100%] generate-git-commit <-> git-helper
       Scopes: user / user
```

## Lint frontmatter

Vérifie la qualité de chaque SKILL.md :

| Sévérité | Vérification |
|----------|-------------|
| CRITICAL | Frontmatter manquant ou cassé |
| CRITICAL | Description absente (agent ne peut pas déclencher) |
| WARNING | Description trop courte (< 30 chars) |
| WARNING | Pas de mot de déclenchement ("Use when...") |
| WARNING | Body trop court (< 3 lignes) |
| INFO | Description trop longue (> 500 chars) |
| INFO | Pas de section Gotchas |
| INFO | Fichier trop gros (> 500 lignes) |
| INFO | Le nom du dossier ne correspond pas au champ `name` |

## Auto-fix

Corrections automatiques (dry-run par défaut, `--apply` pour écrire) :
- Ajout du closing `---` manquant dans le frontmatter
- Ajout d'une description template si absente
- Ajout de `metadata.version: "1.0.0"` si absent

Ne touche PAS : les skills plugin/marketplace, les liens brisés, les fichiers sans SKILL.md.

## Audit skills.sh

Vérifie l'état de vos skills sur [skills.sh](https://skills.sh) :
- Détecte les doublons (forks/copies)
- Affiche les résultats de sécurité (Gen, Socket, Snyk)
- Affiche le nombre d'installs

Nécessite un token Vercel OIDC :

```bash
# Depuis un projet Vercel lié
vercel env pull
bash scripts/health-check.sh --audit

# Ou directement
bash scripts/health-check.sh --audit --token <VERCEL_OIDC_TOKEN>
```

## Différence avec skills-janitor

| Aspect | skills-janitor | skill-health-checker |
|--------|---------------|---------------------|
| Agents | Claude Code + Codex | Pi + Claude + Codex + omp + OpenCode |
| Plugin support | ✅ Claude plugins | ✅ Claude plugins + sources |
| Security | ✅ Heuristiques | ✅ + filtrage faux positifs HTML |
| Tokens | Via transcripts | Estimation statique + regroupement |
| Usage | Via history.jsonl | Pas encore (futur) |
| Dédup | Par realpath | Par realpath + par nom |
| TUI Swipe | ✅ Tinder-style | ❌ Pas encore (futur) |
| MCP servers | ✅ (v1.7) | ❌ Pas encore (futur) |
| Dépendances | Bash + Python3 | Bash + Python3 |
