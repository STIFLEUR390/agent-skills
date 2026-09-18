# Guide d'utilisation — scribe

Documentation API Laravel avec Scribe.

---

## Installation

```bash
composer require knuckleswtf/scribe --dev
php artisan vendor:publish --tag=scribe-config
```

---

## Exemple 1 — Documenter un endpoint

**Demander**：
```
Documente l'endpoint GET /api/users/{id}.
```

**Le skill génère**：

```php
/**
 * Get a user.
 *
 * Retrieves the user with the given ID.
 *
 * @urlParam id integer required The ID of the user.
 * @responseField id integer The user's unique identifier.
 * @responseField name string The user's name.
 * @responseField email string The user's email.
 *
 * @response 404 {"message": "User not found"}
 */
public function show(int $id)
{
    return User::findOrFail($id);
}
```

---

## Exemple 2 — Endpoint CRUD complet

**Demander**：
```
Documente l'endpoint POST /api/users avec validation.
```

**Le skill génère**：

```php
/**
 * Create a user.
 *
 * @bodyParam name string required The user's name. Example: John Doe
 * @bodyParam email string required The user's email. Example: john@example.com
 * @bodyParam password string required The password. Minimum: 8 characters.
 *
 * @response 201 {"id": 1, "name": "John Doe", "email": "john@example.com"}
 * @response 422 {"message": "Validation failed", "errors": {"email": ["The email has already been taken."]}}
 */
public function store()
{
    // ...
}
```

---

## Exemple 3 — Avec API Resource

**Demander**：
```
Documente les endpoints users avec API Resource.
```

**Le skill génère**：

```php
/**
 * @apiResource App\Http\Resources\UserResource
 * @apiResourceModel App\Models\User
 */
public function show(int $id)
{
    return new UserResource(User::findOrFail($id));
}

/**
 * @apiResourceCollection App\Http\Resources\UserResource
 * @apiResourceModel App\Models\User
 */
public function index()
{
    return UserResource::collection(User::paginate(20));
}
```

---

## Voir aussi

- `laravel-core` — Fondamentaux Laravel
- `laravel-api` — REST API patterns
