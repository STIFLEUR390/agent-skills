---
name: laravel-core
description: >
  Point d'entrée obligatoire pour tout projet Laravel 13. Analyse le projet,
  identifie le pattern (monolithe, Inertia, Livewire, API, microservice, etc.),
  route vers les skills spécialisés, et applique les fondamentaux : routing,
  controllers, models, migrations, service providers. Utiliser quand on travaille
  sur un projet Laravel, quand on crée un nouveau projet Laravel, ou quand on
  demande de l'aide avec du code Laravel. Toujours charger en premier.
license: MIT
compatibility: "Claude Code, Codex, OpenCode, Pi, omp"
allowed-tools: Read Write Glob Grep Bash
user-invocable: true
---

# Laravel Core — Gateway & Fondamentaux Laravel 13

Tu es un expert Laravel 13. Ton rôle est d'analyser le projet, d'identifier
son pattern architectural, de router vers les skills appropriés, et d'appliquer
les fondamentaux du framework.

## Quand utiliser ce skill

- On travaille sur un projet Laravel (quel que soit le pattern)
- On crée un nouveau projet Laravel
- On demande de l'aide avec du code Laravel
- On veut comprendre l'architecture d'un projet Laravel

## Quand NE PAS utiliser ce skill

- Projet PHP sans Laravel
- Maintenance serveur sans code Laravel
- Question purement théorique sur PHP (sans contexte Laravel)

## Vue d'ensemble

| Phase | Objectif | Livrable |
|-------|----------|----------|
| 1. Analyse | Identifier le pattern du projet | Matrice de skills activés |
| 2. Routing | Charger les skills spécialisés | Skills combinés |
| 3. Fondamentaux | Appliquer les conventions Laravel 13 | Code conforme |

## Phase 1 — Analyse du projet

### Détection automatique

Exécuter le script de détection pour identifier le pattern :

```bash
bash ${SKILL_DIR:-$(dirname "$0")}/scripts/detect-pattern.sh
```

Sinon, analyser manuellement :

1. **Lire `composer.json`** — packages installés
2. **Vérifier la structure** — dossiers, noms de fichiers
3. **Identifier les patterns** :

| Fichier/Package détecté | Pattern | Skills à charger |
|--------------------------|---------|------------------|
| `inertiajs/inertia-laravel` | Inertia.js | `laravel-inertia` |
| `livewire/livewire` | Livewire | `laravel-livewire` |
| Routes `api/` ou `Route::apiResource` | API REST | `laravel-api` |
| `laravel/ai` ou `openai-php/client` | AI/LLM | `laravel-ai` |
| `laravel/boost` ou MCP config | MCP | `laravel-mcp` |
| `laravel/horizon` | Queues | `laravel-queue` |
| `laravel/reverb` | WebSocket | `laravel-websocket` |
| `laravel/filament` | Admin | `laravel-admin` |
| `laravel/pennant` | Feature flags | — |
| Multi-DB ou tenancy config | Multi-tenant | `laravel-multi-tenancy` |
| Services distants / event sourcing | Microservices | `laravel-microservice` |

### Matrice de routing

| Type de projet | Skills activés |
|----------------|----------------|
| Monolithe Blade | core + testing + security + performance + deploy |
| Inertia.js (Vue/React) | core + inertia + testing + security + performance + deploy |
| Livewire | core + livewire + testing + security + performance + deploy |
| API REST | core + api + testing + security + performance + deploy |
| API + AI | core + api + ai + mcp + testing + security |
| Microservices | core + microservice + api + queue + testing + deploy |
| SaaS multi-tenant | core + multi-tenancy + api + testing + security + deploy |
| Admin panel | core + admin + testing + security |

## Phase 2 — Fondamentaux Laravel 13

### PHP 8.3+ requis

Laravel 13 nécessite PHP 8.3 minimum. Utiliser les features modernes :
- `match` expressions (pas de nested ternary)
- Enums pour les états
- Readonly properties
- Named arguments (avec prudence, les noms peuvent changer)
- First-class callable syntax

### Structure du projet

```
app/
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
├── Exceptions/             — Exceptions custom
└── Providers/              — Service providers
database/
├── migrations/             — Migrations
├── seeders/                — Seeders
├── factories/              — Factories
├── domains/                — Migrations par domaine (optionnel)
routes/
├── web.php                 — Routes web
├── api.php                 — Routes API
├── console.php             — Routes console
└── channels.php            — Broadcasting channels
tests/
├── Feature/                — Tests HTTP / intégration
└── Unit/                   — Tests unitaires
```

### Conventions de naming

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

### Routes

```php
// routes/web.php
use App\Http\Controllers\PostController;
use Illuminate\Support\Facades\Route;

Route::get('/', fn () => view('welcome'));

// Ressources CRUD
Route::resource('posts', PostController::class);

// Routes avec middleware
Route::middleware('auth')->group(function () {
    Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');
});

// Routes API (routes/api.php)
Route::apiResource('posts', PostController::class);
```

### Controllers

```php
<?php

namespace App\Http\Controllers;

use App\Http\Requests\StorePostRequest;
use App\Models\Post;
use Illuminate\Http\JsonResponse;

class PostController extends Controller
{
    public function index()
    {
        $posts = Post::paginate(20);
        return view('posts.index', compact('posts'));
    }

    public function store(StorePostRequest $request): JsonResponse
    {
        $post = Post::create($request->validated());
        return response()->json($post, 201);
    }
}
```

### Models Eloquent

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Post extends Model
{
    use HasFactory;

    protected $fillable = ['title', 'content', 'user_id'];

    protected $casts = [
        'published_at' => 'datetime',
        'is_published' => 'boolean',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function comments(): HasMany
    {
        return $this->hasMany(Comment::class);
    }
}
```

### Form Requests

```php
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StorePostRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'title' => ['required', 'string', 'max:255'],
            'content' => ['required', 'string'],
            'published_at' => ['nullable', 'date'],
        ];
    }
}
```

### Migrations

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('posts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('title');
            $table->text('content');
            $table->boolean('is_published')->default(false);
            $table->timestamp('published_at')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('posts');
    }
};
```

### Testing (Pest)

```php
<?php

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('can list posts', function () {
    $user = User::factory()->create();
    $posts = Post::factory()->count(5)->create(['user_id' => $user->id]);

    $response = $this->getJson('/api/posts');

    $response->assertOk()
        ->assertJsonCount(5, 'data');
});

it('can create a post', function () {
    $user = User::factory()->create();

    $response = $this->actingAs($user)
        ->postJson('/api/posts', [
            'title' => 'Test Post',
            'content' => 'Test content',
        ]);

    $response->assertCreated()
        ->assertJsonFragment(['title' => 'Test Post']);
});
```

## Règles d'or Laravel 13

1. **Valider les entrées** — Toujours via Form Requests
2. **Typer les retours** — Return types sur tous les méthodes
3. **Paginer les listes** — `paginate()` ou `cursorPaginate()`
4. **Utiliser les Factories** — Pas de données de test en dur
5. **Tester les controllers** — Tests HTTP, pas de test de logique interne
6. **Pas de logique dans les routes** — Toujours un controller ou closure
7. **Pas de DB dans les views** — Utiliser les variables passées
8. **Utiliser les PHP Attributes** — `#[Middleware]`, `#[Authorize]`, `#[Tries]`
9. **Utiliser les Enums** — Pour les états et les options
10. **Cache TTL extension** — `Cache::touch()` pour étendre sans re-stocker

## Validation

Le skill est activé quand :
1. Le projet contient `laravel/framework` dans `composer.json`
2. La structure suit les conventions Laravel
3. Le script `detect-pattern.sh` identifie un pattern valide

## Erreurs courantes

1. **Nested ternary** — Utiliser `match` à la place
2. **Mass assignment sans protection** — Toujours définir `$fillable` ou `$guarded`
3. **N+1 queries** — Utiliser `with()` ou `preventLazyLoading()`
4. **Pas de pagination** — Toujours paginer les listes
5. **Logique dans les routes** — Déplacer dans un controller
6. **Tests qui passent en local mais pas en CI** — Utiliser `RefreshDatabase`
