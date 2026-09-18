# Agent Skills Manager

Dépôt de skills multi-agents pour Claude Code, Codex, OpenCode, Pi et omp.

## Skills disponibles

| Skill | Description | Usage |
|-------|-------------|-------|
| `project-definer` | Définition complète d'un projet : découverte, cahier des charges, PRD, architecture | Lancer un nouveau projet |
| `skill-creator` | Créer un nouveau skill agent multi-plateforme | Ajouter un skill au repo |
| `skill-health-checker` | Auditer tous les skills installés : inventaire, sécurité, tokens, doublons cross-agents | Vérifier l'état de santé des skills |

## Skills Laravel 13

| Skill | Description | Usage |
|-------|-------------|-------|
| `laravel-core` | Gateway : analyse le projet et route vers les skills spécialisés | Tout projet Laravel |
| `laravel-inertia` | Inertia.js + Vue/React | Frontend full-stack |
| `laravel-livewire` | Livewire 3 + Volt | Composants dynamiques |
| `laravel-api` | REST API, JSON:API, Sanctum | API backend |
| `laravel-mcp` | Serveur MCP pour outils AI | Intégration AI |
| `laravel-ai` | Laravel AI SDK, RAG, embeddings | Features AI |
| `laravel-microservice` | Microservices, event-driven | Architecture distribuée |
| `laravel-testing` | Pest, PHPUnit, factories | Tests |
| `laravel-deploy` | Docker, CI/CD, Forge, Vapor | Déploiement |
| `laravel-security` | Auth, CSRF, headers, rate limiting | Sécurité |
| `laravel-performance` | Cache, queries, profiling | Performance |
| `laravel-multi-tenancy` | SaaS multi-tenant, isolation | Multi-tenancy |
| `laravel-queue` | Jobs, batches, chains, Horizon | Traitement async |
| `laravel-websocket` | Reverb, broadcasting, presence | Temps réel |
| `laravel-admin` | Filament, ressources, widgets | Panneau admin |
| `laravel-nuxt` | API Laravel optimisée pour Nuxt.js | Laravel ↔ Nuxt |

## Skills Nuxt.js

| Skill | Description | Usage |
|-------|-------------|-------|
| `nuxt-core` | Fondamentaux Nuxt v4 : pages, routing, composables | Tout projet Nuxt |
| `nuxt-ui` | Composants UI, dark mode, tables, formulaires | Interfaces Nuxt UI |
| `sentry` | Sentry pour Laravel + Nuxt : erreurs, logs, tracing | Monitoring complet |
| `pest` | Pest PHP : expectation API, datasets, mocking, arch testing | Testing PHP |

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
