---
name: spatie-query-builder
description: >
  Spatie Laravel Query Builder — filtrer, trier, inclure des relations et
  sélectionner des champs depuis les query parameters HTTP. Pour les APIs
  REST avec pagination, filtering, sorting, sparse fieldsets. Utiliser
  quand on crée une API avec des query parameters dynamiques.
license: MIT
compatibility: "Claude Code, Codex, OpenCode, Pi, omp"
allowed-tools: Read Write Glob Grep Bash
user-invocable: true
---

# Spatie Laravel Query Builder — APIs REST dynamiques

Tu es un expert Spatie Query Builder pour Laravel. Ton rôle est de construire
des APIs REST avec filtering, sorting, includes et field selection dynamiques.

## Quand utiliser

- Créer une API avec des query parameters dynamiques
- Filtrer, trier, inclure des relations depuis l'URL
- Implémenter des sparse fieldsets
- Pagination avec query parameters préservés
- API conforme au JSON API spec

## Quand NE PAS utiliser

- Requêtes internes sans query parameters
- APIs simples sans filtering dynamique
- Batch jobs

## Installation

```bash
composer require spatie/laravel-query-builder
```

## Usage de base

```php
<?php

use Spatie\QueryBuilder\QueryBuilder;

// Filtering : GET /users?filter[name]=John
$users = QueryBuilder::for(User::class)
    ->allowedFilters('name')
    ->get();

// Sorting : GET /users?sort=-name
$users = QueryBuilder::for(User::class)
    ->allowedSorts('name')
    ->get();

// Including relations : GET /users?include=posts
$users = QueryBuilder::for(User::class)
    ->allowedIncludes('posts')
    ->get();

// Selecting fields : GET /users?fields[users]=id,name
$users = QueryBuilder::for(User::class)
    ->allowedFields('id', 'name')
    ->get();

// Combiné
$users = QueryBuilder::for(User::class)
    ->allowedFilters('name', 'email')
    ->allowedSorts('name', 'created_at')
    ->allowedIncludes('posts', 'permissions')
    ->allowedFields('id', 'name', 'email')
    ->paginate();
```

## Filtering

### Filters partiels (défaut)

```php
// GET /users?filter[name]=john
$users = QueryBuilder::for(User::class)
    ->allowedFilters('name')
    ->get();
// WHERE name LIKE '%john%'
```

### Filters exact

```php
use Spatie\QueryBuilder\AllowedFilter;

// GET /users?filter[id]=1
$users = QueryBuilder::for(User::class)
    ->allowedFilters(AllowedFilter::exact('id'))
    ->get();
// WHERE id = 1
```

### Filters par opérateur

```php
use Spatie\QueryBuilder\Enums\FilterOperator;

// GET /users?filter[salary]=>3000
$users = QueryBuilder::for(User::class)
    ->allowedFilters(
        AllowedFilter::operator('salary', FilterOperator::DYNAMIC),
    )
    ->get();
// WHERE salary > 3000
```

### Filters scope

```php
// Modèle avec scope
public function scopeActive(Builder $query): Builder
{
    return $query->where('active', true);
}

// GET /users?filter[active]=1
$users = QueryBuilder::for(User::class)
    ->allowedFilters(AllowedFilter::scope('active'))
    ->get();
```

### Filters sur relations

```php
// GET /users?filter[posts.title]=laravel
$users = QueryBuilder::for(User::class)
    ->allowedFilters(AllowedFilter::exact('posts.title'))
    ->get();
// WHEREHas posts WHERE title = 'laravel'
```

### BelongsTo filters

```php
// GET /comments?filter[post_id]=5
$users = QueryBuilder::for(Comment::class)
    ->allowedFilters(AllowedFilter::belongsTo('post_id', 'post'))
    ->get();
```

### Callback filters

```php
$users = QueryBuilder::for(User::class)
    ->allowedFilters(
        AllowedFilter::callback('has_posts', fn ($query) => $query->whereHas('posts')),
    )
    ->get();
```

### Custom filters

```php
use Spatie\QueryBuilder\Filters\Filter;

class FiltersUserPermission implements Filter
{
    public function __invoke(Builder $query, $value, string $property): void
    {
        $query->whereHas('permissions', fn ($q) => $q->where('name', $value));
    }
}

$users = QueryBuilder::for(User::class)
    ->allowedFilters(AllowedFilter::custom('permission', new FiltersUserPermission))
    ->get();
```

### Filter aliases

```php
// GET /users?filter[name]=John
// Filtre sur la colonne 'user_passport_full_name'
$users = QueryBuilder::for(User::class)
    ->allowedFilters(AllowedFilter::exact('name', 'user_passport_full_name'))
    ->get();
```

### Default values & nullable

```php
$users = QueryBuilder::for(User::class)
    ->allowedFilters(
        AllowedFilter::exact('name')->default('Joe'),
        AllowedFilter::scope('deleted')->default(false),
        AllowedFilter::exact('email')->nullable(), // filtre null avec valeur vide
    )
    ->get();
```

### Ignored values

```php
$users = QueryBuilder::for(User::class)
    ->allowedFilters(
        AllowedFilter::exact('name')->ignore(null, '-1'),
    )
    ->get();
```

## Sorting

```php
// GET /users?sort=-name
$users = QueryBuilder::for(User::class)
    ->allowedSorts('name')
    ->get();

// Default sort
$users = QueryBuilder::for(User::class)
    ->defaultSort('name')
    ->allowedSorts('name', 'street')
    ->get();

// Custom sort
use Spatie\QueryBuilder\AllowedSort;

$users = QueryBuilder::for(User::class)
    ->allowedSorts(
        AllowedSort::field('street', 'actual_column_street'), // alias
    )
    ->get();
```

## Including relationships

```php
// GET /users?include=posts,permissions
$users = QueryBuilder::for(User::class)
    ->allowedIncludes('posts', 'permissions')
    ->get();

// Nested
$users = QueryBuilder::for(User::class)
    ->allowedIncludes('posts.comments')
    ->get();

// Count
$users = QueryBuilder::for(User::class)
    ->allowedIncludes('posts', AllowedInclude::count('friendsCount'))
    ->get();

// Alias
use Spatie\QueryBuilder\AllowedInclude;

$users = QueryBuilder::for(User::class)
    ->allowedIncludes(AllowedInclude::relationship('profile', 'userProfile'))
    ->get();
```

## Selecting fields

```php
// GET /users?fields[users]=id,name
$users = QueryBuilder::for(User::class)
    ->allowedFields('id', 'name')
    ->get();

// Fields pour relations
$posts = QueryBuilder::for(Post::class)
    ->allowedFields('id', 'title', 'authors.id', 'authors.name')
    ->allowedIncludes('author')
    ->get();
```

## Pagination

```php
$users = QueryBuilder::for(User::class)
    ->allowedFilters('name')
    ->allowedSorts('name')
    ->paginate()
    ->appends(request()->query()); // Préserve les query params
```

## Controller complet

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\User;
use Spatie\QueryBuilder\AllowedFilter;
use Spatie\QueryBuilder\QueryBuilder;

class UserController extends Controller
{
    public function index()
    {
        $users = QueryBuilder::for(User::class)
            ->allowedFilters([
                AllowedFilter::exact('id'),
                'name',
                'email',
                AllowedFilter::scope('active'),
                AllowedFilter::exact('posts.title'),
            ])
            ->allowedSorts('name', 'email', 'created_at')
            ->allowedIncludes('posts', 'permissions')
            ->allowedFields('id', 'name', 'email')
            ->paginate()
            ->appends(request()->query());

        return UserResource::collection($users);
    }
}
```

## Config

```php
// config/query-builder.php
return [
    'parameters' => [
        'include' => 'include',
        'filter' => 'filter',
        'sort' => 'sort',
        'fields' => 'fields',
        'append' => 'append',
    ],
    'delimiter' => ',',
    'filter_value_splitting_enabled' => true,
    'disable_invalid_filter_query_exception' => false,
    'disable_invalid_sort_query_exception' => false,
    'disable_invalid_include_query_exception' => false,
];
```

## Bonnes pratiques

1. **Toujours `allowed*`** — Filtrer les entrées pour la sécurité
2. **Paginer** — `paginate()` avec `appends()` pour préserver les query params
3. **Eager loading** — `allowedIncludes` pour éviter le N+1
4. **Aliases** — Cacher les noms de colonnes internes
5. **Defaults** — Valeurs par défaut pour les filtres optionnels
6. **API Resources** — Combiner avec des ressources typées
7. **JSON API spec** — Suivre les conventions pour les query params
8. **Fields** — Réduire la taille des réponses avec `fields[resource]`
9. **Custom filters** — Pour la logique métier complexe
10. **Disable exceptions** — En production, désactiver les exceptions de filtres invalides

## Cross-références

- `laravel-api` — Patterns REST API
- `laravel-nuxt` — API pour Nuxt (query params via `useFetch`)
- `laravel-core` — Fondamentaux Laravel
- `scribe` — Documentation des query params
