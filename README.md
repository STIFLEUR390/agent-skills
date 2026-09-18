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

### Core

| Skill | Description | Usage |
|-------|-------------|-------|
| [project-definer](skills/project-definer/) | Définition complète d'un projet : découverte, cahier des charges, PRD, architecture | Lancer un nouveau projet |
| [skill-creator](skills/skill-creator/) | Créer un nouveau skill agent multi-plateforme | Ajouter un skill au repo |
| [skill-health-checker](skills/skill-health-checker/) | Auditer tous les skills installés | Vérifier l'état de santé des skills |

### Laravel 13

| Skill | Description | Usage |
|-------|-------------|-------|
| [laravel-core](skills/laravel-core/) | Gateway : analyse le projet et route vers les skills spécialisés | Tout projet Laravel |
| [laravel-inertia](skills/laravel-inertia/) | Inertia.js + Vue/React | Frontend full-stack |
| [laravel-livewire](skills/laravel-livewire/) | Livewire 3 + Volt | Composants dynamiques |
| [laravel-api](skills/laravel-api/) | REST API, JSON:API, Sanctum | API backend |
| [laravel-nuxt](skills/laravel-nuxt/) | API Laravel optimisée pour Nuxt.js | Laravel ↔ Nuxt |
| [laravel-mcp](skills/laravel-mcp/) | Serveur MCP pour outils AI | Intégration AI |
| [laravel-ai](skills/laravel-ai/) | Laravel AI SDK, RAG, embeddings | Features AI |
| [laravel-microservice](skills/laravel-microservice/) | Microservices, event-driven | Architecture distribuée |
| [laravel-testing](skills/laravel-testing/) | Pest, PHPUnit, factories | Tests |
| [laravel-deploy](skills/laravel-deploy/) | Docker, CI/CD, Forge, Vapor | Déploiement |
| [laravel-security](skills/laravel-security/) | Auth, CSRF, headers, rate limiting | Sécurité |
| [laravel-performance](skills/laravel-performance/) | Cache, queries, profiling | Performance |
| [laravel-multi-tenancy](skills/laravel-multi-tenancy/) | SaaS multi-tenant, isolation | Multi-tenancy |
| [laravel-queue](skills/laravel-queue/) | Jobs, batches, chains, Horizon | Traitement async |
| [laravel-websocket](skills/laravel-websocket/) | Reverb, broadcasting, presence | Temps réel |
| [laravel-admin](skills/laravel-admin/) | Filament, ressources, widgets | Panneau admin |

### Nuxt.js

| Skill | Description | Usage |
|-------|-------------|-------|
| [nuxt-core](skills/nuxt-core/) | Fondamentaux Nuxt v4 : pages, routing, composables | Tout projet Nuxt |
| [nuxt-ui](skills/nuxt-ui/) | Composants UI, dark mode, tables, formulaires | Interfaces Nuxt UI |

### Monitoring

| Skill | Description | Usage |
|-------|-------------|-------|
| [sentry](skills/sentry/) | Sentry pour Laravel + Nuxt : erreurs, logs, tracing | Monitoring complet |

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
├── skill-creator/          # Création de skills
├── skill-health-checker/   # Audit multi-agents
├── laravel-core/           # Gateway Laravel 13
├── laravel-inertia/        # Inertia.js
├── laravel-livewire/       # Livewire
├── laravel-api/            # REST API
├── laravel-nuxt/           # Laravel ↔ Nuxt
├── laravel-mcp/            # MCP pour AI
├── laravel-ai/             # AI/LLM
├── laravel-microservice/   # Microservices
├── laravel-testing/        # Tests
├── laravel-deploy/         # Déploiement
├── laravel-security/       # Sécurité
├── laravel-performance/    # Performance
├── laravel-multi-tenancy/  # Multi-tenancy
├── laravel-queue/          # Queues
├── laravel-websocket/      # WebSockets
├── laravel-admin/          # Filament admin
├── nuxt-core/              # Nuxt fondamentaux
├── nuxt-ui/                # Nuxt UI
└── sentry/                 # Sentry monitoring
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
# Rapport complet
bash skills/skill-health-checker/scripts/health-check.sh

# Mode bref
bash skills/skill-health-checker/scripts/health-check.sh --brief
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

Chaque skill a un guide dans `docs/<name>/GUIDE.md`.

## License

[MIT](LICENSE)
