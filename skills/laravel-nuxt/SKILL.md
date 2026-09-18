---
name: laravel-nuxt
description: >
  API Laravel 13 optimisée pour Nuxt.js. Routes API, Sanctum SPA auth,
  SSR-friendly responses, typed endpoints, JSON:API. Utiliser quand on crée
  une API Laravel destinée à un frontend Nuxt, on configure l'auth entre
  Laravel et Nuxt, ou on structure les endpoints pour la consommation Nuxt.
license: MIT
compatibility: "Claude Code, Codex, OpenCode, Pi, omp"
allowed-tools: Read Write Glob Grep Bash
user-invocable: true
---

# Laravel Nuxt — API Laravel pour Nuxt.js

Tu es un expert en APIs Laravel optimisées pour Nuxt.js. Ton rôle est de
concevoir des endpoints qui s'intègrent parfaitement avec les composables
Nuxt (`useFetch`, `useAsyncData`, `$fetch`).

## Quand utiliser

- Créer une API Laravel pour un frontend Nuxt
- Configurer Sanctum SPA auth entre Laravel et Nuxt
- Structurer les endpoints pour SSR-friendly responses
- Typer les réponses API pour TypeScript
- Optimiser les appels réseau pour SSR/CSR

## Quand NE PAS utiliser

- API purement interne (pas de frontend Nuxt)
- Application monolithe Blade sans Nuxt
- Microservice sans consommation Nuxt

## Architecture

```
Laravel (API)                    Nuxt (Frontend)
├── routes/api.php               ├── composables/useApi.ts
├── app/Http/Controllers/Api/    ├── plugins/api.ts
├── app/Http/Resources/          ├── types/api.ts
├── app/Http/Middleware/          └── middleware/auth.ts
└── config/cors.php
```

## 1. Configuration CORS

```php
// config/cors.php
return [
    'paths' => ['api/*', 'sanctum/csrf-cookie'],
    'allowed_methods' => ['*'],
    'allowed_origins' => [
        env('NUXT_URL', 'http://localhost:3000'),
    ],
    'allowed_origins_patterns' => [],
    'allowed_headers' => ['*'],
    'exposed_headers' => [],
    'max_age' => 0,
    'supports_credentials' => true, // REQUIS pour Sanctum SPA
];
```

## 2. Sanctum SPA Auth

```php
// routes/api.php
use Illuminate\Support\Facades\Route;

// Public routes
Route::post('/login', [AuthController::class, 'login']);
Route::post('/register', [AuthController::class, 'register']);
Route::post('/forgot-password', [PasswordResetController::class, 'store']);

// CSRF cookie pour Nuxt
Route::get('/sanctum/csrf-cookie', function () {
    return response()->json(['status' => 'ok']);
});

// Protected routes
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', fn (Request $r) => new UserResource($r->user()));
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::apiResource('posts', PostController::class);
});
```

```php
// app/Http/Controllers/Api/AuthController.php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function login(Request $request): JsonResponse
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
            'device_name' => 'required|string',
        ]);

        $user = \App\Models\User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Les identifiants sont incorrects.'],
            ]);
        }

        $token = $user->createToken($request->device_name)->plainTextToken;

        return response()->json([
            'user' => new UserResource($user),
            'token' => $token,
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(null, 204);
    }
}
```

## 3. Controller API typé

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
    // GET /api/posts — compatible avec useFetch/useAsyncData
    public function index(Request $request): PostCollection
    {
        $posts = Post::query()
            ->with('user:id,name,avatar')
            ->when($request->search, fn ($q, $s) =>
                $q->where('title', 'LIKE', "%{$s}%")
            )
            ->when($request->category, fn ($q, $c) =>
                $q->where('category', $c)
            )
            ->latest()
            ->paginate($request->per_page ?? 15);

        return new PostCollection($posts);
    }

    // GET /api/posts/{post}
    public function show(Post $post): PostResource
    {
        $post->load(['user:id,name,avatar', 'comments.user:id,name,avatar']);
        return new PostResource($post);
    }

    // POST /api/posts
    public function store(StorePostRequest $request): JsonResponse
    {
        $post = Post::create([
            ...$request->validated(),
            'user_id' => $request->user()->id,
        ]);

        return (new PostResource($post->load('user')))
            ->response()
            ->setStatusCode(201);
    }

    // PUT /api/posts/{post}
    public function update(UpdatePostRequest $request, Post $post): PostResource
    {
        $this->authorize('update', $post);
        $post->update($request->validated());
        return new PostResource($post->fresh()->load('user'));
    }

    // DELETE /api/posts/{post}
    public function destroy(Post $post): JsonResponse
    {
        $this->authorize('delete', $post);
        $post->delete();
        return response()->json(null, 204);
    }
}
```

## 4. API Resource pour Nuxt

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
            'slug' => $this->slug,
            'content' => $this->content,
            'excerpt' => $this->excerpt,
            'is_published' => $this->is_published,
            'published_at' => $this->published_at?->toISOString(),
            'created_at' => $this->created_at->toISOString(),
            'updated_at' => $this->updated_at->toISOString(),

            // Relations (seulement si chargées)
            'user' => new UserResource($this->whenLoaded('user')),
            'comments' => CommentResource::collection($this->whenLoaded('comments')),
            'comments_count' => $this->whenCounted('comments'),

            // Links pour la navigation Nuxt
            'links' => [
                'self' => route('api.posts.show', $this->id),
                'author' => route('api.users.show', $this->user_id),
            ],
        ];
    }
}
```

## 5. Réponses standardisées

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
                'self' => $this->resource->url($this->resource->currentPage()),
                'next' => $this->resource->nextPageUrl(),
                'prev' => $this->resource->previousPageUrl(),
                'first' => $this->resource->url(1),
                'last' => $this->resource->url($this->resource->lastPage()),
            ],
        ];
    }
}
```

## 6. Rate limiting

```php
<?php

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Support\Facades\RateLimiter;

// AppServiceProvider.php
public function boot(): void
{
    RateLimiter::for('api', function (Request $request) {
        return Limit::perMinute(60)->by(
            $request->user()?->id ?: $request->ip()
        );
    });

    // Rate limiting spécifique pour l'auth
    RateLimiter::for('auth', function (Request $request) {
        return Limit::perMinute(5)->by($request->ip());
    });
}
```

## 7. Routes API versionnées

```php
<?php

// routes/api.php
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    // Public
    Route::post('/login', [AuthController::class, 'login'])
        ->middleware('throttle:auth');
    Route::post('/register', [AuthController::class, 'register']);
    Route::get('/posts', [PostController::class, 'index'])
        ->middleware('cache:60'); // Cache 60 secondes

    // Protected
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/user', fn ($r) => new UserResource($r->user()));
        Route::apiResource('posts', PostController::class)
            ->except('index', 'show');
    });
});
```

## 8. Error responses pour Nuxt

```php
<?php

namespace App\Exceptions;

use Illuminate\Auth\AuthenticationException;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

class ApiExceptionHandler
{
    public function render($request, \Throwable $e)
    {
        if ($request->expectsJson() || $request->is('api/*')) {
            return match (true) {
                $e instanceof ValidationException => response()->json([
                    'message' => 'Erreur de validation',
                    'errors' => $e->errors(),
                ], 422),

                $e instanceof AuthenticationException => response()->json([
                    'message' => 'Non authentifié',
                ], 401),

                $e instanceof NotFoundHttpException => response()->json([
                    'message' => 'Ressource non trouvée',
                ], 404),

                default => response()->json([
                    'message' => $e->getMessage(),
                ], 500),
            };
        }

        return parent::render($request, $e);
    }
}
```

## Bonnes pratiques

1. **Sanctum SPA auth** — Token dans les cookies, `withCredentials: true`
2. **Réponses typées** — API Resources avec structure cohérente
3. **Pagination** — Toujours paginer, `meta` + `links`
4. **Loading states** — `pending` natif dans `useFetch`
5. **Error handling** — Format `{ message, errors }` pour Nuxt `useError()`
6. **Caching** — Routes GET cachées côté serveur et client
7. **Rate limiting** — Différent pour auth vs API
8. **CORS** — `supports_credentials: true` obligatoire
9. **Device name** — Requis pour Sanctum multi-device tokens
10. **Relations chargées** — `with()` pour éviter le N+1

## Validation

- [ ] CORS configuré avec `supports_credentials: true`
- [ ] Sanctum SPA auth fonctionnelle
- [ ] API Resources pour tous les modèles
- [ ] Pagination avec `meta` + `links`
- [ ] Error responses formatées
- [ ] Rate limiting configuré
- [ ] Routes versionnées (`/api/v1/...`)
