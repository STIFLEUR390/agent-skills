# {{ project_name }} — Laravel 13

## Architecture

| Champ | Valeur |
|-------|--------|
| **Type** | {{ pattern }} |
| **PHP** | 8.3+ |
| **Laravel** | 13.x |
| **Frontend** | {{ frontend }} |
| **Database** | {{ database }} |
| **Queue** | {{ queue }} (sync / redis / database / sqs) |
| **Cache** | {{ cache }} (redis / database / file) |
| **Search** | {{ search }} (database full-text / Scout / pgvector) |

### Types de projet supportés

| Type | Description | Skills activés |
|------|-------------|----------------|
| Monolithe Blade | Classique avec Blade templates | core + testing + security + performance + deploy |
| Inertia.js | Vue 3 ou React + Inertia | core + inertia + testing + security + performance + deploy |
| Livewire | Composants dynamiques Livewire/Volt | core + livewire + testing + security + performance + deploy |
| API REST | Backend pur JSON | core + api + testing + security + performance + deploy |
| API + Nuxt | API Laravel pour frontend Nuxt | core + api + nuxt + testing + security + performance + deploy |
| API + AI | API avec intégration LLM | core + api + ai + mcp + testing + security |
| Microservices | Architecture distribuée | core + microservice + api + queue + testing + deploy |
| SaaS multi-tenant | Application multi-tenant | core + multi-tenancy + api + testing + security + deploy |
| Admin panel | Panneau administrateur | core + admin + testing + security |

---

## Skills disponibles

### Gateway

| Skill | Rôle | Chargement |
|-------|------|------------|
| `laravel-core` | Analyse le projet et route vers les skills | **Toujours** |

### Frontend

| Skill | Usage | Quand charger |
|-------|-------|---------------|
| `laravel-inertia` | Inertia.js + Vue 3 / React | `inertiajs/inertia-laravel` détecté |
| `laravel-livewire` | Livewire 3 + Volt | `livewire/livewire` détecté |
| `laravel-nuxt` | API pour consommation Nuxt | Frontend Nuxt séparé |

### Backend & API

| Skill | Usage | Quand charger |
|-------|-------|---------------|
| `laravel-api` | REST API, JSON:API, Sanctum | Routes API détectées |
| `laravel-mcp` | Serveur MCP pour outils AI | Config MCP présente |
| `laravel-ai` | Laravel AI SDK, RAG, embeddings | `laravel/ai` installé |
| `laravel-queue` | Jobs, batches, chains, Horizon | Queues non-sync |
| `laravel-websocket` | Reverb, broadcasting | `laravel/reverb` installé |

### Architecture

| Skill | Usage | Quand charger |
|-------|-------|---------------|
| `laravel-microservice` | Microservices, event-driven | Architecture distribuée |
| `laravel-multi-tenancy` | SaaS multi-tenant | Isolation données requise |
| `laravel-admin` | Filament, panneau admin | `filament/filament` installé |

### Qualité & Ops

| Skill | Usage | Chargement |
|-------|-------|------------|
| `laravel-testing` | Pest, factories, HTTP tests | **Toujours** |
| `laravel-security` | Auth, CSRF, headers, rate limiting | **Toujours** |
| `laravel-performance` | Cache, queries, profiling | **Toujours** |
| `laravel-deploy` | Docker, CI/CD, Forge, Vapor | **Toujours** |
| `pest` | Testing framework PHP | **Toujours** (si Pest utilisé) |
| `scribe` | Documentation API | API à documenter |
| `sentry` | Error tracking, logs, tracing | Monitoring |

---

## Conventions

### Code PHP

- **PSR-12** pour le style de code
- **PHP 8.3+** — Utiliser les features modernes :
  - `match` expressions (pas de nested ternary)
  - Enums (backed et non-backed)
  - Readonly properties
  - First-class callable syntax
  - Named arguments (avec prudence)
- **Return types** sur toutes les méthodes
- **Strict types** en début de fichier

### Conventions Laravel

| Élément | Convention | Exemple |
|---------|-----------|---------|
| Model | Singular, PascalCase | `User`, `BlogPost` |
| Controller | PascalCase + Controller | `UserController` |
| Migration | snake_case, timestamped | `2026_01_01_000001_create_users_table` |
| Seeder | PascalCase + Seeder | `DatabaseSeeder` |
| Factory | PascalCase + Factory | `UserFactory` |
| Form Request | PascalCase + Request | `StorePostRequest` |
| Policy | PascalCase + Policy | `PostPolicy` |
| Job | PascalCase | `ProcessPodcast` |
| Event | PascalCase | `PodcastProcessed` |
| Route name | dot.notation | `posts.index`, `posts.store` |
| View | dot.notation | `posts.index`, `posts.show` |
| Config key | snake_case | `app.name`, `database.default` |
| Env variable | SCREAMING_SNAKE_CASE | `APP_NAME`, `DB_HOST` |

### Validation & Forms

- **Form Requests** pour toute validation
- **API Resources** pour les réponses API
- **Inertia::render()** pour les pages Inertia
- **Livewire Components** pour les interfaces dynamiques

### Tests

- **Pest** comme framework de test principal
- **Factories** pour les données de test
- **HTTP tests** pour les controllers (pas de test de logique interne)
- **Fakes** — `Queue::fake()`, `Event::fake()`, `Notification::fake()`

### AI & MCP

- **Jobs** pour les appels LLM (pas en sync)
- **Vector store** pour le RAG (pgvector)
- **Streaming** via SSE ou WebSockets
- **MCP** pour exposer les données aux outils AI

---

## Règles d'or

### Toujours faire

1. **Valider les entrées** — Form Requests, jamais de validation côté client seul
2. **Typer les retours** — Return types sur toutes les méthodes publiques
3. **Paginer les listes** — `paginate()` ou `cursorPaginate()`
4. **Tester les controllers** — Tests HTTP, pas de test de logique interne
5. **Utiliser des factories** — Pas de données de test en dur
6. **Cache les queries** — `Cache::remember()` ou tags
7. **Éviter le N+1** — `preventLazyLoading()` en dev, `with()` partout
8. **Documenter l'API** — Scribe avec annotations/attributes

### Jamais faire

1. **Logique dans les routes** — Toujours un controller ou closure
2. **DB dans les views** — Utiliser les variables passées
3. **Secrets en dur** — Toujours les variables d'env
4. **Mass assignment sans protection** — `$fillable` ou `$guarded`
5. **Nested ternary** — Utiliser `match` à la place
6. **Appels LLM sync** — Toujours via des jobs

---

## Structure du projet

```
app/
├── Console/                — Commands artisan
├── Exceptions/             — Exceptions custom
├── Http/
│   ├── Controllers/        — Controllers
│   ├── Middleware/          — Middleware
│   └── Requests/           — Form Requests
├── Models/                 — Models Eloquent
├── Services/               — Services métier
├── Jobs/                   — Jobs queues
├── Events/                 — Events
├── Listeners/              — Listeners
├── Notifications/          — Notifications
├── Policies/               — Authorization policies
├── Providers/              — Service providers
└── Ai/                     — Agents AI (si applicable)
database/
├── migrations/             — Migrations
├── seeders/                — Seeders
├── factories/              — Factories
└── domains/                — Migrations par domaine (optionnel)
resources/
├── views/                  — Blade templates
├── js/                     — Frontend (Vue/React/Inertia)
│   ├── Pages/              — Pages Inertia
│   ├── Components/         — Composants frontend
│   └── layouts/            — Layouts frontend
└── css/                    — Styles
routes/
├── web.php                 — Routes web
├── api.php                 — Routes API
├── console.php             — Routes console
└── channels.php            — Broadcasting channels
server/
├── api/                    — Server API routes (Nuxt)
├── middleware/              — Server middleware
└── utils/                  — Server utils
tests/
├── Feature/                — Tests HTTP / intégration
├── Unit/                   — Tests unitaires
├── Evals/                  — Tests AI (si applicable)
└── Browser/                — Browser tests (si applicable)
```

---

## Patterns spécifiques

{{#if inertia}}
### Inertia.js

- Controllers : `Inertia::render('Page', [...props])`
- Pages : `resources/js/Pages/`
- Layouts : `HandleInertiaRequests` middleware
- Partial reloads : `router.reload({ only: ['comments'] })`
- Prefetching : `<Link prefetch>`
- SSR : configurer `ssr.enabled = true`

**Links** : `laravel-inertia`
{{/if}}

{{#if livewire}}
### Livewire + Volt

- Composants : `app/Livewire/`
- Volt : composants single-file
- Réactivité : `wire:model.live`
- Events : `$dispatch` / `wire:poll`
- Forms : `#[Validate]` attributes
- Loading : `wire:loading`

**Links** : `laravel-livewire`
{{/if}}

{{#if api}}
### API REST

- API Resources pour chaque modèle exposé
- Rate limiting : `throttle:api` middleware
- Versioning : `/api/v1/...`
- Réponses : `{ data, meta, links }`
- Auth : Sanctum SPA ou token
- CORS : `supports_credentials: true` si SPA

**Links** : `laravel-api`, `laravel-nuxt` (si Nuxt)
{{/if}}

{{#if ai}}
### AI / LLM

- Laravel AI SDK : `laravel/ai`
- Agents : classes avec `instructions()` et `tools()`
- Embeddings : `Str::of($text)->toEmbeddings()`
- Vector search : `whereVectorSimilarTo()`
- Streaming : `->stream()` ou SSE
- Jobs : toujours async pour les appels LLM
- Providers : OpenAI, Anthropic, Gemini, Ollama

**Links** : `laravel-ai`, `laravel-mcp`
{{/if}}

{{#if mcp}}
### MCP (Model Context Protocol)

- Laravel Boost : `composer require laravel/boost`
- Tools : actions exécutables
- Resources : données en lecture seule
- Prompts : templates réutilisables
- Validation : comme des API classiques
- Rate limiting : sur les endpoints

**Links** : `laravel-mcp`, `laravel-ai`
{{/if}}

{{#if microservice}}
### Microservices

- Communication synchrone : HTTP/gRPC
- Communication asynchrone : queues/events
- Event sourcing : audit trail
- Circuit breaker : résilience
- DTOs : données inter-services
- Sagas : transactions distribuées
- Chaque service : sa propre DB

**Links** : `laravel-microservice`, `laravel-queue`
{{/if}}

{{#if multiTenancy}}
### Multi-tenancy

- Isolation des données OBLIGATOIRE
- Tenant scope sur tous les modèles
- Middleware tenant au début de chaque requête
- Tests avec tenants multiples
- Facturation par tenant

**Links** : `laravel-multi-tenancy`, `laravel-security`
{{/if}}

{{#if admin}}
### Admin Panel (Filament)

- Ressources : CRUD automatisé
- Widgets : dashboard, charts, stats
- Custom pages : flux métier
- Permissions : via Policies
- Form builders : champs typés

**Links** : `laravel-admin`, `laravel-security`
{{/if}}

{{#if websocket}}
### WebSocket / Temps réel

- Laravel Reverb : driver par défaut
- Channels privées : données sensibles
- Presence channels : tracking utilisateur
- Broadcasting : events → JS
- Meta tags : distributed tracing Laravel ↔ Frontend

**Links** : `laravel-websocket`, `laravel-security`
{{/if}}

---

## Monitoring & Observabilité

### Sentry

```ini
# .env
SENTRY_LARAVEL_DSN=https://key@org.ingest.sentry.io/project
SENTRY_TRACES_SAMPLE_RATE=1.0
SENTRY_ENABLE_LOGS=true
```

- Errors : `Integration::handles()` dans `bootstrap/app.php`
- Logs : channel `sentry_logs`
- Tracing : meta tags pour distributed tracing
- Source maps : upload via Vite plugin

### Laravel Pulse

```bash
composer require laravel/pulse
php artisan pulse:install
```

---

## CI/CD

### GitHub Actions

```yaml
name: Tests
on: ['push', 'pull_request']
jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: shivammathur/setup-php@v2
        with:
          php-version: '8.4'
          coverage: xdebug
      - run: composer install --no-interaction
      - run: php artisan test
      - run: vendor/bin/phpstan analyse
```

---

## Déploiement

### Docker (multi-stage)

```dockerfile
FROM php:8.3-fpm AS builder
WORKDIR /var/www
COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader
COPY . .
RUN php artisan config:cache && php artisan route:cache

FROM php:8.3-fpm
COPY --from=builder /var/www /var/www
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache
EXPOSE 9000
CMD ["php-fpm"]
```

### Health check

```php
Route::get('/health', function () {
    try {
        DB::connection()->getPdo();
        Cache::get('test');
        return response('OK', 200);
    } catch (\Exception $e) {
        return response('ERROR', 500);
    }
});
```

---

## Nouveautés Laravel 13

| Feature | Description |
|---------|-------------|
| **AI SDK** | `laravel/ai` — agents, tools, embeddings, RAG |
| **JSON:API** | Resources conformes au standard JSON:API |
| **Semantic Search** | `whereVectorSimilarTo()` avec pgvector |
| **Queue Routing** | `Queue::route()` pour la config centralisée |
| **PHP Attributes** | `#[Middleware]`, `#[Authorize]`, `#[Tries]`, `#[Timeout]` |
| **Cache TTL** | `Cache::touch()` pour étendre sans re-stocker |
| **PreventRequestForgery** | Nouveau middleware CSRF avec vérification d'origine |

---

## Validation

Le template est valide quand :
1. Toutes les variables `{{ }}` sont remplies
2. Le pattern correspond aux skills listés
3. Les cross-références entre skills sont cohérentes
4. La structure correspond au type de projet
