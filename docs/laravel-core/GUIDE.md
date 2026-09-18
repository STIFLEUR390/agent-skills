# Guide d'utilisation — laravel-core

Gateway et fondamentaux pour tout projet Laravel 13.

---

## Installation

Le skill est déjà installé. Vérifiez :

| Agent | Commande |
|-------|----------|
| Claude Code | `/skill:laravel-core` |
| Pi | `/skill:laravel-core` |
| omp | `/skill:laravel-core` |

---

## Quand l'utiliser

- On travaille sur un projet Laravel
- On crée un nouveau projet Laravel
- On veut comprendre l'architecture d'un projet Laravel
- On demande de l'aide avec du code Laravel

---

## Comment ça marche

### 1. Détection automatique

Le skill analyse le projet et identifie le pattern :

```bash
bash skills/laravel-core/scripts/detect-pattern.sh /chemin/vers/projet
```

Sortie :
```
✅ Projet Laravel détecté
📦 Inertia.js détecté → Vue.js
📦 Queues configurées (non-sync)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Patterns détectés : inertia queue
📋 Skills recommandés :
   laravel-core (obligatoire)
   laravel-inertia
   laravel-queue
   laravel-testing (recommandé)
   laravel-security (recommandé)
   laravel-performance (recommandé)
   laravel-deploy (recommandé)
```

### 2. Routing vers les skills

Selon le pattern détecté, `laravel-core` route automatiquement :

| Pattern | Skills activés |
|---------|----------------|
| Monolithe Blade | core + testing + security + performance + deploy |
| Inertia.js | core + inertia + testing + security + performance + deploy |
| Livewire | core + livewire + testing + security + performance + deploy |
| API REST | core + api + testing + security + performance + deploy |
| API + AI | core + api + ai + mcp + testing + security |
| Microservices | core + microservice + api + queue + testing + deploy |
| SaaS multi-tenant | core + multi-tenancy + api + testing + security + deploy |

---

## Exemple 1 — Analyser un projet existant

**Demander** :
```
Analyse ce projet Laravel et dis-moi quel pattern il utilise.
```

**Le skill fait** :
1. Lit `composer.json` pour les packages
2. Vérifie la structure des dossiers
3. Détecte les patterns (Inertia, Livewire, API, etc.)
4. Affiche les skills recommandés

---

## Exemple 2 — Créer un nouveau projet

**Demander** :
```
Crée un projet Laravel 13 avec Inertia.js et Vue 3.
```

**Le skill guide** :
1. Initialise le projet Laravel
2. Installe Inertia.js + Vue 3
3. Configure le routing (laravel-core)
4. Crée la structure de base (laravel-inertia)
5. Ajoute les tests (laravel-testing)
6. Sécurise l'app (laravel-security)

---

## Exemple 3 — Comprendre les conventions

**Demander** :
```
Quelles sont les conventions de naming dans ce projet Laravel ?
```

**Le skill répond** :

| Élément | Convention | Exemple |
|---------|-----------|---------|
| Model | Singular, PascalCase | `User`, `BlogPost` |
| Controller | PascalCase + Controller | `UserController` |
| Migration | snake_case, timestamped | `2026_01_01_000001_create_users_table` |
| Form Request | PascalCase + Request | `StorePostRequest` |
| Route name | dot.notation | `posts.index` |

---

## Skills complémentaires

| Skill | Quand le charger |
|-------|------------------|
| `laravel-inertia` | Projet avec Inertia.js |
| `laravel-livewire` | Projet avec Livewire |
| `laravel-api` | API REST |
| `laravel-ai` | Intégration AI/LLM |
| `laravel-mcp` | Serveur MCP |
| `laravel-testing` | Tests (recommandé) |
| `laravel-security` | Sécurité (recommandé) |
| `laravel-performance` | Performance (recommandé) |
| `laravel-deploy` | Déploiement (recommandé) |
| `laravel-queue` | Jobs/queues |
| `laravel-websocket` | Temps réel |
| `laravel-admin` | Panneau admin |
| `laravel-microservice` | Microservices |
| `laravel-multi-tenancy` | SaaS multi-tenant |

---

## Validation

Le skill est activé quand :
1. Le projet contient `laravel/framework` dans `composer.json`
2. La structure suit les conventions Laravel
3. Le script `detect-pattern.sh` identifie un pattern valide
