# Guide d'utilisation — spatie-query-builder

Filtrer, trier, inclure et sélectionner les champs depuis les query parameters HTTP.

---

## Installation

```bash
composer require spatie/laravel-query-builder
```

---

## Exemple 1 — API avec filtering

**Demander**：
```
Crée l'endpoint GET /api/users avec filtering, sorting et pagination.
```

**Le skill génère**：

```php
public function index()
{
    $users = QueryBuilder::for(User::class)
        ->allowedFilters(['name', 'email', AllowedFilter::exact('id')])
        ->allowedSorts('name', 'created_at')
        ->paginate()
        ->appends(request()->query());

    return UserResource::collection($users);
}

// GET /api/users?filter[name]=john&sort=-created_at&page=2
```

---

## Exemple 2 — Avec relations

**Demander**：
```
Ajoute l'inclusion des relations posts et comments.
```

**Le skill génère**：

```php
$users = QueryBuilder::for(User::class)
    ->allowedIncludes('posts', 'posts.comments')
    ->allowedFilters('name')
    ->get();

// GET /api/users?include=posts,posts.comments
```

---

## Exemple 3 — Sparse fieldsets

**Demander**：
```
Ajoute la sélection de champs pour réduire la taille des réponses.
```

**Le skill génère**：

```php
$users = QueryBuilder::for(User::class)
    ->allowedFields('id', 'name', 'email', 'posts.id', 'posts.title')
    ->allowedIncludes('posts')
    ->get();

// GET /api/users?fields[users]=id,name,email&fields[posts]=id,title
```

---

## Voir aussi

- `laravel-api` — Patterns REST API
- `laravel-nuxt` — API pour Nuxt
- `scribe` — Documentation API
