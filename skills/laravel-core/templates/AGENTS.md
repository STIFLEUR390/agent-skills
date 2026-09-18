# {{ project_name }} — Laravel 13

## Architecture
- **Type** : {{ pattern }} (Monolithe Blade / Inertia.js / Livewire / API / Microservice)
- **PHP** : 8.3+
- **Laravel** : 13.x
- **Frontend** : {{ frontend }} (Blade / Vue 3 / React / Livewire / API only)
- **Database** : {{ database }} (MySQL / PostgreSQL / SQLite)

## Skills actifs

L'agent doit charger les skills suivants au démarrage :

1. `laravel-core` — Fondamentaux (obligatoire)
2. `laravel-{{ pattern }}` — Selon le type de projet
3. `laravel-testing` — Tests
4. `laravel-security` — Sécurité
5. `laravel-performance` — Performance
6. `laravel-deploy` — Déploiement

## Conventions

- **PSR-12** pour le code PHP
- Conventions Laravel pour le naming
- **Form Requests** pour la validation
- **API Resources** pour les réponses API
- **Factories** pour les données de test
- **Pest** pour les tests
- **Enums** pour les états et options
- **PHP Attributes** pour la configuration déclarative

## Règles d'or

1. Toujours valider les entrées (Form Requests)
2. Toujours typer les retours (return types)
3. Toujours paginer les listes
4. Toujours tester les controllers (HTTP tests)
5. Jamais de logique dans les routes
6. Jamais de DB dans les views/templates
7. Utiliser `match` au lieu de nested ternary
8. Utiliser des Enums pour les états
9. Utiliser les PHP Attributes quand disponibles
10. Cache avec `Cache::touch()` pour étendre le TTL

## Structure du projet

```
app/Http/Controllers/    — Controllers
app/Http/Requests/       — Form Requests
app/Http/Middleware/     — Middleware
app/Models/              — Models Eloquent
app/Services/            — Services métier
app/Jobs/                — Jobs queues
app/Events/              — Events
app/Listeners/           — Listeners
app/Notifications/       — Notifications
app/Policies/            — Policies auth
app/Exceptions/          — Exceptions custom
database/migrations/     — Migrations
database/seeders/        — Seeders
database/factories/      — Factories
routes/web.php           — Routes web
routes/api.php           — Routes API
tests/Feature/           — Tests HTTP
tests/Unit/              — Tests unitaires
```

## Patterns détectés

{{#if inertia}}
### Inertia.js
- Controllers retournent `Inertia::render()`
- Pages dans `resources/js/Pages/`
- Layouts partagés via `HandleInertiaRequests`
{{/if}}

{{#if livewire}}
### Livewire
- Composants dans `app/Livewire/`
- Volt pour les composants simples
- `wire:model.live` pour la réactivité
{{/if}}

{{#if api}}
### API REST
- API Resources pour chaque modèle exposé
- Rate limiting via `throttle` middleware
- Versioning par URI (`/api/v1/...`)
- Réponses standardisées : `{ data, meta, links }`
{{/if}}

{{#if ai}}
### AI/LLM
- Jobs pour les appels LLM (pas en sync)
- Vector store pour le RAG
- Streaming via SSE ou WebSockets
{{/if}}

{{#if mcp}}
### MCP
- Exposer les données via le protocole MCP
- Validation des entrées MCP
- Rate limiting sur les endpoints
{{/if}}
