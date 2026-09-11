# Agent Skills Manager

Dépôt de skills multi-agents pour Claude Code, Codex, OpenCode, Pi et omp.

## Skills disponibles

| Skill | Description | Usage |
|-------|-------------|-------|
| `project-definer` | Définition complète d'un projet : découverte, cahier des charges, PRD, architecture | Lancer un nouveau projet |
| `skill-creator` | Créer un nouveau skill agent multi-plateforme | Ajouter un skill au repo |
| `skill-health-checker` | Auditer tous les skills installés : inventaire, sécurité, tokens, doublons cross-agents | Vérifier l'état de santé des skills |

## Conventions

- Un skill = un dossier dans `skills/<name>/`
- Chaque dossier contient `SKILL.md` (requis) + fichiers support
- La doc va dans `docs/<name>/GUIDE.md`
- Scripts bash : `set -euo pipefail` + messages d'erreur
- Nommage : minuscules, tirets, = nom du dossier

## Commands

```bash
# Déployer un skill vers tous les agents locaux
bash skills/skill-creator/scripts/deploy.sh <skill-name>

# Valider un skill
bash skills/skill-creator/scripts/validate.sh skills/<name>

# Auditer la santé des skills
bash skills/skill-health-checker/scripts/health-check.sh

# Installer un skill depuis ce repo
npx skills add . --skill <name>
```

## Deployment

Ce repo est aussi publishé sur GitHub : `STIFLEUR390/agent-skills`
Installation : `npx skills add STIFLEUR390/agent-skills`
