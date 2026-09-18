---
name: laravel-api
description: >
  Construction d'APIs REST avec Laravel 13. API Resources, JSON:API, validation,
  rate limiting, versioning, Sanctum. Utiliser quand on crée une API, on expose
  des données, on configure l'auth API, ou on versionne l'API.
license: MIT
compatibility: "Claude Code, Codex, OpenCode, Pi, omp"
allowed-tools: Read Write Glob Grep Bash
user-invocable: true
---

# Laravel API — REST API dans Laravel 13

Tu es un expert en APIs REST avec Laravel. Ton rôle est de guider la construction
d'APIs robustes, maintenables et sécurisées.

## Quand utiliser

- Créer une API REST
- Exposer des données via API
- Configurer l'auth API (Sanctum)
- Versionner l'API
- Tester l'API

## API Resource

```php
<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PostResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'content' => $this->content,
            'is_published' => $this->is_published,
            'created_at' => $this->created_at->toISOString(),
            'updated_at' => $this->updated_at->toISOString(),
            'user' => new UserResource($this->whenLoaded('user')),
            'comments_count' => $this->whenCounted('comments'),
            'links' => [
                'self' => route('api.posts.show', $this->id),
                'user' => route('api.users.show', $this->user_id),
            ],
        ];
    }
}
```

## API Collection

```php
<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\ResourceCollection;

class PostCollection extends ResourceCollection
{
    public $collects = PostResource::class;

    public function toArray(Request $request): array
    {
        return [
            'data' => $this->collection,
            'meta' => [
                'current_page' => $this->resource->currentPage(),
                'last_page' => $this->resource->lastPage(),
                'per_page' => $this->resource->perPage(),
                'total' => $this->resource->total(),
            ],
            'links' => [
                'self' => $this->resource->url(1),
                'next' => $this->resource->nextPageUrl(),
                'prev' => $this->resource->previousPageUrl(),
            ],
        ];
    }
}
```

## JSON:API Resource (Laravel 13)

```php
<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class PostJsonApiResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'type' => 'posts',
            'id' => (string) $this->id,
            'attributes' => [
                'title' => $this->title,
                'content' => $this->content,
                'is_published' => $this->is_published,
                'created_at' => $this->created_at->toISOString(),
            ],
            'relationships' => [
                'user' => [
                    'data' => [
                        'type' => 'users',
                        'id' => (string) $this->user_id,
                    ],
                ],
            ],
            'links' => [
                'self' => route('api.posts.show', $this->id),
            ],
        ];
    }
}
```

## Controller API

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StorePostRequest;
use App\Http\Requests\UpdatePostRequest;
use App\Http\Resources\PostCollection;
use App\Http\Resources\PostResource;
use App\Models\Post;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PostController extends Controller
{
    public function index(Request $request): PostCollection
    {
        $posts = Post::query()
            ->with('user')
            ->when($request->search, fn ($q, $s) => $q->where('title', 'LIKE', "%{$s}%"))
            ->when($request->user_id, fn ($q, $id) => $q->where('user_id', $id))
            ->latest()
            ->paginate($request->per_page ?? 20);

        return new PostCollection($posts);
    }

    public function show(Post $post): PostResource
    {
        $post->load(['user', 'comments.user']);
        return new PostResource($post);
    }

    public function store(StorePostRequest $request): JsonResponse
    {
        $post = Post::create([
            ...$request->validated(),
            'user_id' => $request->user()->id,
        ]);

        return (new PostResource($post))
            ->response()
            ->setStatusCode(201);
    }

    public function update(UpdatePostRequest $request, Post $post): PostResource
    {
        $post->update($request->validated());
        return new PostResource($post->fresh());
    }

    public function destroy(Post $post): JsonResponse
    {
        $post->delete();
        return response()->json(null, 204);
    }
}
```

## Routes API

```php
<?php

use App\Http\Controllers\Api\PostController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::apiResource('posts', PostController::class);
});

// Versioning par header
Route::middleware('api.version:v2')->group(function () {
    Route::apiResource('posts', PostV2Controller::class);
});
```

## Form Request API

```php
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StorePostRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->hasVerifiedEmail();
    }

    public function rules(): array
    {
        return [
            'title' => ['required', 'string', 'max:255'],
            'content' => ['required', 'string', 'min:10'],
            'published_at' => ['nullable', 'date', 'after:now'],
        ];
    }

    public function messages(): array
    {
        return [
            'title.required' => 'Le titre est obligatoire.',
            'content.min' => 'Le contenu doit faire au moins 10 caractères.',
        ];
    }
}
```

## Rate Limiting

```php
<?php

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Support\Facades\RateLimiter;

// config/app.php ou AppServiceProvider
RateLimiter::for('api', function ($request) {
    return Limit::perMinute(60)->by($request->user()?->id ?: $request->ip());
});

// Rate limiting spécifique
RateLimiter::for('auth', function ($request) {
    return Limit::perMinute(5)->by($request->ip());
});
```

## Sanctum Auth

```php
<?php

// Token API
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', fn (Request $r) => $r->user());
    Route::apiResource('posts', PostController::class)->only(['store', 'update', 'destroy']);
});

// SPA Auth
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/dashboard', fn () => inertia('Dashboard'));
});
```

## Bonnes pratiques

1. **API Resources** pour chaque modèle exposé
2. **Form Requests** pour la validation
3. **Rate limiting** sur tous les endpoints
4. **Versioning** par URI (`/api/v1/...`)
5. **Réponses standardisées** : `{ data, meta, links }`
6. **Pagination** obligatoire
7. **Inclusion relationnelle** via `?include=user`
8. **Filtrage** via query params
9. **Errors format** : `{ message, errors, status }`
10. **Documentation** avec OpenAPI/Swagger

## Validation

- [ ] API Resources pour tous les modèles exposés
- [ ] Form Requests pour la validation
- [ ] Rate limiting configuré
- [ ] Versioning en place
- [ ] Pagination sur toutes les listes
- [ ] Auth configurée (Sanctum)
- [ ] Tests d'API
