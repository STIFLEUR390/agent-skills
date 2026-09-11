---
name: skill-health-checker
description: >
  Auditer et nettoyer les skills installés sur tous les agents (Pi, Claude Code,
  Codex, omp, OpenCode). Inventaire complet, détection de doublons, liens brisés,
  estimation du coût token, scan de sécurité, et rapport consolidé. Utiliser quand
  l'utilisateur veut vérifier l'état de ses skills, libérer du contexte, repérer
  des skills inutiles ou dangereux, ou optimiser son budget token.
  Ne PAS utiliser pour créer ou modifier un skill (utiliser skill-creator).
license: MIT
compatibility: "Pi, Claude Code, Codex, OpenCode, omp"
allowed-tools: Read Glob Grep Bash
user-invocable: true
argument-hint: "[--json] [--brief] [--scope user|project|all]"
---

# Skill Health Checker

Audite l'ensemble de tes skills installés sur tous les agents IA.
Inspiré par [skills-janitor](https://github.com/khendzel/skills-janitor),
adapté pour notre setup multi-agents.

## Quand utiliser

- Vérifier l'état de santé de la collection de skills
- Libérer du contexte en supprimant les skills inutiles
- Détecter les doublons entre agents
- Repérer des patterns de sécurité suspects
- Optimiser le budget token (chaque skill décrit = tokens permanents)

## Quand NE PAS utiliser

- Créer un nouveau skill → utiliser `skill-creator`
- Modifier le contenu d'un skill → éditer directement le SKILL.md
- Installer un skill tiers → utiliser `npx skills add`

## Agents couverts

| Agent | Emplacement |
|-------|-------------|
| Pi | `~/.pi/agent/skills/` |
| Claude Code | `~/.claude/skills/` |
| Codex | `~/.agents/skills/` |
| OpenCode | `~/.config/opencode/skills/` |
| omp | `~/.omp/agent/skills/` |
| Plugins Claude | `~/.claude/plugins/marketplaces/*/skills/` |
| Sources Claude | `~/.claude/sources/*/skills/` |

## Processus

| Phase | Objectif | Script |
|-------|----------|--------|
| 1. Scan | Inventaire complet | `scripts/health-check.sh --scan` |
| 2. Sécurité | Détection patterns suspects | `scripts/health-check.sh --security` |
| 3. Tokens | Estimation coût contexte | `scripts/health-check.sh --tokens` |
| 4. Doublons | Chevauchements cross-agents | `scripts/health-check.sh --dupes` |
| 5. Rapport | Synthèse consolidée | `scripts/health-check.sh` (tout) |

## Utilisation

### Rapport complet (défaut)

```bash
bash scripts/health-check.sh
```

### Mode bref (inventory only)

```bash
bash scripts/health-check.sh --brief
```

### JSON (pour pipeline)

```bash
bash scripts/health-check.sh --json
```

### Un scope spécifique

```bash
bash scripts/health-check.sh --scope user    # ~/.pi/agent/skills + ~/.claude/skills
bash scripts/health-check.sh --scope project  # ./.claude/skills + ./.agents/skills
bash scripts/health-check.sh --scope all      # tout (défaut)
```

### Scan sécurité seul

```bash
bash scripts/health-check.sh --security
```

### Estimation tokens seul

```bash
bash scripts/health-check.sh --tokens
```

### Doublons seul

```bash
bash scripts/health-check.sh --dupes
```

## Ce que le rapport contient

### 1. Inventaire
- Nombre de skills **uniques** vs copies installées (symlinks)
- Skills avec/sans SKILL.md
- Skills avec/sans frontmatter valide
- Liens symboliques (et les brisés, dédupés par realpath)

### 2. Sécurité (heuristiques, pas preuve)
- Phrases d'injection prompt ("ignore previous instructions", etc.)
- Instructions cachées dans commentaires HTML (> 50 chars, hors code fences)
- Bases64 suspectes (smuggling)
- Scripts avec `curl|wget` piped into shell
- Accès aux magasins de credentials
- URLs raccourcies (destination cachée)
- Unicode zero-width / RTL override

Filtrage automatique : commentaires courts (< 50 chars), CSS/HTML attributes, balises doc.

Verdicts : PASS / REVIEW / RISK

### 3. Tokens
- Taille de chaque skill en tokens estimés (≈4 chars/token)
- Regroupé par nom (pas de duplication par agent)
- Pourcentage du budget contexte (défaut 200k)
- Séparation toujours-chargé (description) vs on-trigger (body)
- Top 10 des plus gourmands avec agents listés

### 4. Doublons
- **Name collisions** : même nom, chemin physique différent
- **Description overlaps** : similarité Jaccard > 30% entre skills différents
- Les copies cross-agents (même nom) ne sont PAS flagged comme overlap

## Validation — comment savoir qu'on a fini

- [ ] Rapport affiché sans erreur
- [ ] `RISK` vérifiés manuellement
- [ ] `Broken symlinks` nettoyés
- [ ] Skills inutiles supprimés ou désactivés
- [ ] Budget token < 100% (sinon, réduire les skills ou augmenter le contexte)

## Erreurs courantes à éviter

1. **Ne pas supprimer aveuglément** — le scan security donne des heuristiques, pas des preuves de malice
2. **Vérifier les plugins** — un skill plugin ne peut pas être supprimé individuellement, il faut déinstaller le plugin entier
3. **Les liens brisés ne sont pas toujours des erreurs** — un skill déplacé mais encore référencé peut être voulu

## Règles générales

- Toujours en mode dry-run par défaut (juste le rapport)
- Les chemins sont résolus par `realpath` pour éviter les faux doublons
- Compatible bash 3.2 (macOS) — pas d'associative arrays
- Aucune dépendance externe (bash + python3 uniquement)
