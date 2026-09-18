---
name: laravel-performance
description: >
  Optimisation des performances Laravel 13. Cache, query optimization,
  profiling, lazy loading, Pulse. Utiliser quand on optimise une app lente,
  on debug des requêtes lentes, on configure le cache, ou on profile.
license: MIT
compatibility: "Claude Code, Codex, OpenCode, Pi, omp"
allowed-tools: Read Write Glob Grep Bash
user-invocable: true
---

# Laravel Performance — Performance Laravel 13

Tu es un expert en performance Laravel 13. Ton rôle est d'optimiser les
applications pour la vitesse et l'efficacité.

## Quand utiliser

- Application lente
- Requêtes DB lentes (N+1)
- Configuration du cache
- Profiling des performances
- Optimisation pour la production

## Patterns de performance

### Cache

```php
<?php

use Illuminate\Support\Facades\Cache;

// Cache simple
$posts = Cache::remember('posts.all', now()->addMinutes(30), function () {
    return Post::all();
});

// Cache avec tags
Cache::tags(['posts', 'home'])->put('featured', $posts, 3600);

// Étendre le TTL sans re-stocker (Laravel 13)
Cache::touch('posts.all', 1800);

// Cache memoization (même requête = même réponse dans la même requête)
$posts = Cache::memo()->remember('posts.all', 300, fn () => Post::all());
```

### Query Optimization

```php
<?php

// ❌ Mal : N+1 query
$posts = Post::all();
foreach ($posts as $post) {
    echo $post->user->name; // Query supplémentaire !
}

// ✅ Bon : Eager loading
$posts = Post::with('user')->get();

// ✅ Bon : Select spécifique
$posts = Post::select('id', 'title', 'user_id')->with('user:id,name')->get();

// ✅ Bon : Cursor pour les gros datasets
$posts = Post::cursor();
foreach ($posts as $post) {
    // Traitement un par un, pas de charge mémoire
}

// ✅ Bon : Chunking pour les opérations en masse
Post::chunk(100, function ($posts) {
    foreach ($posts as $post) {
        // Traitement par lots
    }
});

// ✅ Bon : Détecter le N+1 en dev
Model::preventLazyLoading(!app()->isProduction());
```

### Indexing

```php
<?php

// ✅ Bon : Index sur les colonnes fréquemment query
Schema::table('posts', function (Blueprint $table) {
    $table->index('user_id');
    $table->index(['status', 'created_at']);
    $table->fullText('content'); // Pour la recherche full-text
});

// ✅ Bon : Composite index
$table->index(['user_id', 'status', 'created_at']);
```

### Pagination

```php
<?php

// ✅ Bon : Toujours paginer les listes
$posts = Post::paginate(20);

// ✅ Bon : Cursor pagination pour les gros datasets
$posts = Post::cursorPaginate(50);

// ✅ Bon : Simple pour les APIs
$posts = Post::simplePaginate(20);
```

### Lazy Loading vs Eager Loading

```php
<?php

// Lazy loading (par défaut) — charge à l'accès
$user->posts; // Charge ici

// Eager loading — charge en avance
$users = User::with('posts')->get(); // Tout charge d'un coup

// Lazy eager loading — charge à la demande mais en batch
$users = User::all();
$users->load('posts'); // Charge tous les posts d'un coup
```

### Profiling

```php
<?php

// Laravel Telescope (dev)
composer require laravel/telelescope --dev
php artisan telescope:install

// Laravel Pulse (production)
composer require laravel/pulse
php artisan pulse:install

// Debugbar (dev)
composer require barryvdh/laravel-debugbar --dev
```

### Queue pour les tâches lourdes

```php
<?php

// ✅ Bon : Job pour les tâches longues
class ProcessCsv implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $timeout = 300;
    public int $tries = 3;

    public function handle(): void
    {
        // Traitement long...
    }
}

// Dispatch asynchrone
ProcessCsv::dispatch($file);
```

### CDN et Assets

```php
// ✅ Bon : CDN pour les assets statiques
APP_URL=https://example.com
ASSET_URL=https://cdn.example.com

// ✅ Bon : Mix/Vite pour le versioning
// vite.config.js
import { defineConfig } from 'vite';
export default defineConfig({
    build: {
        rollupOptions: {
            output: {
                manualChunks: {
                    vendor: ['axios', 'lodash'],
                },
            },
        },
    },
});
```

## Bonnes pratiques

1. **Cache les queries fréquentes** — Avec `Cache::remember()` ou tags
2. **Éviter le N+1** — `with()` ou `preventLazyLoading()`
3. **Toujours paginer** — `paginate()` ou `cursorPaginate()`
4. **Indexer les colonnes query** — Composite index quand nécessaire
5. **Utiliser des jobs** — Pour les tâches longues
6. **CDN pour les assets** — Réduire la charge sur le serveur
7. **Monitoring** — Pulse en production
8. **Optimiser les images** — Compression, lazy loading
9. **HTTP caching** — Cache-Control headers
10. **Database optimization** — `EXPLAIN` pour analyser les requêtes

## Validation

- [ ] Pas de N+1 queries (`php artisan pulse:check`)
- [ ] Cache configuré pour les données fréquentes
- [ ] Toutes les listes paginées
- [ ] Index sur les colonnes query
- [ ] Jobs pour les tâches longues
- [ ] Assets versionnés et CDN
