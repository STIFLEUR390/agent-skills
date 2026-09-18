# Guide d'utilisation — laravel-api

REST API avec Laravel 13.

---

## Quand l'utiliser

- Créer une API REST
- Exposer des données via API
- Configurer Sanctum

---

## Exemple 1 — API Resource

**Demander** :
```
Crée un API Resource pour le modèle Post.
```

**Le skill génère** :

```php
<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class PostResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'content' => $this->content,
            'user' => new UserResource($this->whenLoaded('user')),
            'links' => [
                'self' => route('api.posts.show', $this->id),
            ],
        ];
    }
}
```

---

## Exemple 2 — Controller API

**Demander** :
```
Crée un controller API pour les posts avec CRUD complet.
```

**Le skill génère** :

```php
<?php

namespace App\Http\Controllers\Api;

class PostController extends Controller
{
    public function index(): PostCollection
    {
        return new PostCollection(Post::paginate(20));
    }

    public function store(StorePostRequest $request): JsonResponse
    {
        $post = Post::create($request->validated());
        return (new PostResource($post))->response()->setStatusCode(201);
    }
}
```

---

## Voir aussi

- `laravel-core` — Fondamentaux
- `laravel-security` — Sécurité API
- `laravel-testing` — Tests API
