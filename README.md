# Agent Skills Manager

[![skills.sh](https://skills.sh/b/STIFLEUR390/agent-skills)](https://skills.sh/STIFLEUR390/agent-skills)

Skills multi-agents compatibles Claude Code, Codex, OpenCode, Pi, omp et [75+ agents](https://skills.sh).

## Installation rapide

```bash
# Via le CLI skills (recommandé)
npx skills add STIFLEUR390/agent-skills --all

# Un skill spécifique
npx skills add STIFLEUR390/agent-skills --skill project-definer

# Un agent spécifique
npx skills add STIFLEUR390/agent-skills --skill project-definer -a claude-code
```

## Skills disponibles

| Skill | Description | Usage |
|-------|-------------|-------|
| [project-definer](skills/project-definer/) | Définition complète d'un projet : découverte, cahier des charges, PRD, architecture, rôles/permissions, isolation, paiements | Lancer un nouveau projet |
| [skill-creator](skills/skill-creator/) | Créer un nouveau skill agent multi-plateforme avec les bonnes pratiques | Ajouter un skill au repo |
| [skill-health-checker](skills/skill-health-checker/) | Auditer tous les skills installés sur Pi, Claude, Codex, omp, OpenCode : inventaire, sécurité, tokens, doublons cross-agents | Vérifier l'état de santé des skills |

## Développement

### Créer un skill

```bash
# 1. Créer le dossier
mkdir -p skills/mon-skill

# 2. Écrire SKILL.md (ou utiliser skill-creator)
# 3. Valider
bash skills/skill-creator/scripts/validate.sh skills/mon-skill

# 4. Déployer localement
bash skills/skill-creator/scripts/deploy.sh mon-skill
```

### Structure

```
skills/
├── project-definer/        # Définition de projet
│   ├── SKILL.md
│   ├── workflows/
│   ├── templates/
│   ├── references/
│   └── scripts/
├── skill-creator/          # Création de skills
│   ├── SKILL.md
│   ├── templates/
│   ├── references/
│   └── scripts/
├── skill-health-checker/   # Audit multi-agents
│   ├── SKILL.md
│   ├── scripts/
│   └── references/
└── [prochain-skill]/
```

### Déploiement local

```bash
# Un skill
bash skills/skill-creator/scripts/deploy.sh <skill-name>

# Tous les skills
for skill in skills/*/; do
  bash skills/skill-creator/scripts/deploy.sh "$(basename "$skill")"
done
```

### Audit santé

```bash
# Rapport complet (inventaire + sécurité + tokens + doublons)
bash skills/skill-health-checker/scripts/health-check.sh

# Mode bref
bash skills/skill-health-checker/scripts/health-check.sh --brief

# Scan sécurité seul
bash skills/skill-health-checker/scripts/health-check.sh --security

# Estimation tokens
bash skills/skill-health-checker/scripts/health-checker.sh --tokens
```

## Compatibilité

| Agent | Emplacement | Invocation |
|-------|-------------|------------|
| Claude Code | `~/.claude/skills/` | `/skill-name` |
| Codex | `~/.agents/skills/` | `$skill-name` |
| OpenCode | `~/.config/opencode/skills/` | `/skill-name` |
| Pi | `~/.pi/agent/skills/` | `/skill:skill-name` |
| omp | `~/.omp/agent/skills/` | `/skill:skill-name` |

## Documentation

| Skill | Guide |
|-------|-------|
| project-definer | [docs/project-definer/GUIDE.md](docs/project-definer/GUIDE.md) |
| skill-creator | [docs/skill-creator/GUIDE.md](docs/skill-creator/GUIDE.md) |
| skill-health-checker | [docs/skill-health-checker/GUIDE.md](docs/skill-health-checker/GUIDE.md) |

## Contribuer

1. Créer le skill avec `skill-creator` ou manuellement
2. Valider : `bash skills/skill-creator/scripts/validate.sh skills/<name>`
3. Déployer : `bash skills/skill-creator/scripts/deploy.sh <name>`
4. Ajouter la doc dans `docs/<name>/GUIDE.md`
5. Audit santé : `bash skills/skill-health-checker/scripts/health-check.sh`
6. Push

## skills.sh

Ce repo est listé sur [skills.sh/STIFLEUR390/agent-skills](https://skills.sh/STIFLEUR390/agent-skills).
Le fichier `skills.sh.json` contrôle le grouping sur la page du repo.

## License

[MIT](LICENSE)
