# Compatibilité multi-agents

## Emplacements de déploiement

| Agent | Emplacement global | Emplacement projet |
|-------|-------------------|-------------------|
| Claude Code | `~/.claude/skills/` | `.claude/skills/` |
| Codex | `~/.agents/skills/` | `.agents/skills/` |
| OpenCode | `~/.config/opencode/skills/` | `.opencode/skills/` |
| Pi | `~/.pi/agent/skills/` | `.pi/skills/` |
| omp | `~/.omp/agent/skills/` | `.omp/skills/` |

## Frontmatter par agent

### Standard Agent Skills (tous agents)

```yaml
---
name: mon-skill
description: ...
---
```

### Extensions Claude Code

```yaml
---
name: mon-skill
description: ...
license: MIT
allowed-tools: Read Write Bash
user-invocable: true
disable-model-invocation: false
argument-hint: "[args]"
context: fork
agent: Explore
---
```

### Extensions Pi

```yaml
---
name: mon-skill
description: ...
license: MIT
allowed-tools: Read Write Glob Grep Bash
metadata:
  audience: developers
---
```

## Invocation par agent

| Agent | Syntaxe | Exemple |
|-------|---------|---------|
| Claude Code | `/skill-name` | `/project-definer` |
| Codex | `$skill-name` | `$project-definer` |
| OpenCode | `/skill-name` | `/project-definer` |
| Pi | `/skill:skill-name` | `/skill:project-definer` |
| omp | `/skill:skill-name` | `/skill:project-definer` |

## Fonctionnalités avancées

| Fonctionnalité | Claude Code | Codex | OpenCode | Pi | omp |
|----------------|:-----------:|:-----:|:--------:|:--:|:---:|
| Skills de base | ✅ | ✅ | ✅ | ✅ | ✅ |
| `allowed-tools` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `context: fork` | ✅ | ❌ | ❌ | ❌ | ❌ |
| Hooks | ✅ | ❌ | ❌ | ❌ | ❌ |
| `disable-model-invocation` | ✅ | ❌ | ❌ | ❌ | ❌ |
| `argument-hint` | ✅ | ❌ | ❌ | ❌ | ❌ |

## Installation via CLI

```bash
# Installer pour tous les agents détectés
npx skills add STIFLEUR390/agent-skills --skill mon-skill

# Installer pour un agent spécifique
npx skills add STIFLEUR390/agent-skills --skill mon-skill -a claude-code

# Installer en global
npx skills add STIFLEUR390/agent-skills --skill mon-skill -g
```
