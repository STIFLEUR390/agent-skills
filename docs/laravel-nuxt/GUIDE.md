# Guide d'utilisation — laravel-nuxt

API Laravel optimisée pour Nuxt.js.

---

## Quand l'utiliser

- Créer une API Laravel pour un frontend Nuxt
- Configurer Sanctum SPA auth
- Structurer les endpoints pour SSR/CSR

---

## Exemple 1 — Setup complet

**Demander**：
```
Configure une API Laravel pour un frontend Nuxt avec auth Sanctum.
```

**Le skill fait**：

1. Configure CORS (`supports_credentials: true`)
2. Installe Sanctum
3. Crée les routes API (`/api/v1/...`)
4. Crée les API Resources
5. Configure le rate limiting

---

## Exemple 2 — Endpoint CRUD

**Demander**：
```
Crée les endpoints API pour les posts, destinés à Nuxt.
```

**Le skill génère**：

```php
// routes/api.php
Route::prefix('v1')->group(function () {
    Route::get('/posts', [PostController::class, 'index']);
    Route::get('/posts/{post}', [PostController::class, 'show']);
    Route::middleware('auth:sanctum')->group(function () {
        Route::post('/posts', [PostController::class, 'store']);
        Route::put('/posts/{post}', [PostController::class, 'update']);
        Route::delete('/posts/{post}', [PostController::class, 'destroy']);
    });
});
```

---

## Exemple 3 — Réponse typée pour Nuxt

**Demander**：
```
Crée un API Resource pour les posts avec pagination.
```

**Le skill génère**：

```php
class PostCollection extends ResourceCollection
{
    public function toArray($request): array
    {
        return [
            'data' => $this->collection,
            'meta' => [
                'current_page' => $this->resource->currentPage(),
                'last_page' => $this->resource->lastPage(),
            ],
        ];
    }
}
```

---

## Voir aussi

- `laravel-core` — Fondamentaux Laravel
- `laravel-security` — Sécurité API
- `nuxt-core` — Frontend Nuxt
