---
name: laravel-multi-tenancy
description: >
  Architecture SaaS multi-tenant avec Laravel. Isolation des données, teams,
  permissions, facturation par tenant. Utiliser quand on crée un SaaS
  multi-tenant, on isole les données, ou on configure les teams.
license: MIT
compatibility: "Claude Code, Codex, OpenCode, Pi, omp"
allowed-tools: Read Write Glob Grep Bash
user-invocable: true
---

# Laravel Multi-Tenancy — SaaS Multi-Tenant

Tu es un expert en multi-tenancy Laravel. Ton rôle est de guider l'architecture
de SaaS multi-tenant avec isolation des données.

## Quand utiliser

- Créer un SaaS multi-tenant
- Isoler les données par tenant
- Configurer les teams/organisations
- Gérer la facturation par tenant

## Patterns de multi-tenancy

### Pattern 1 : Single Database (recommandé pour le début)

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Scope;
use Illuminate\Database\Eloquent\Builder;

trait BelongsToTenant
{
    public static function bootBelongsToTenant(): void
    {
        static::addGlobalScope(new TenantScope);
    }

    public function scopeForCurrentTenant(Builder $query): Builder
    {
        return $query->where('tenant_id', tenant()->id);
    }
}

class Post extends Model
{
    use BelongsToTenant;

    protected $fillable = ['title', 'content', 'user_id', 'tenant_id'];

    public function tenant()
    {
        return $this->belongsTo(Tenant::class);
    }
}
```

### Tenant Scope

```php
<?php

namespace App\Scopes;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Scope;

class TenantScope implements Scope
{
    public function apply(Builder $builder, Model $model): void
    {
        if (!tenant()) {
            return;
        }

        $builder->where('tenant_id', tenant()->id);
    }
}
```

### Middleware tenant

```php
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use App\Models\Tenant;

class SetTenantContext
{
    public function handle(Request $request, Closure $next)
    {
        $tenant = $this->resolveTenant($request);

        if (!$tenant) {
            abort(404, 'Tenant not found');
        }

        // Définir le tenant courant
        tenant($tenant);

        // Configurer la base de données si nécessaire
        if ($tenant->database) {
            config(['database.default' => $tenant->database]);
        }

        return $next($request);
    }

    protected function resolveTenant(Request $request): ?Tenant
    {
        // Par subdomain
        $host = $request->getHost();
        $tenant = Tenant::where('domain', $host)->first();

        // Ou par header
        if (!$tenant) {
            $tenant = Tenant::find($request->header('X-Tenant-Id'));
        }

        return $tenant;
    }
}
```

### Routes tenant

```php
<?php

use App\Http\Controllers\Tenant\DashboardController;
use Illuminate\Support\Facades\Route;

Route::middleware(['tenant'])->prefix('app')->group(function () {
    Route::get('/dashboard', [DashboardController::class, 'index']);
    Route::resource('posts', PostController::class);
});
```

### Config

```php
<?php

namespace App\Support;

class TenantManager
{
    protected ?Tenant $currentTenant = null;

    public function set(?Tenant $tenant): void
    {
        $this->currentTenant = $tenant;
    }

    public function get(): ?Tenant
    {
        return $this->currentTenant;
    }

    public function id(): ?int
    {
        return $this->currentTenant?->id;
    }
}

// Helper global
function tenant(?Tenant $tenant = null): ?Tenant
{
    $manager = app(TenantManager::class);

    if ($tenant !== null) {
        $manager->set($tenant);
    }

    return $manager->get();
}
```

### Migration par tenant

```php
<?php

use Illuminate\Database\Migrations\Migration;

return new class extends Migration
{
    public function up(): void
    {
        // Créer les tables pour le tenant
        Schema::create('posts', function ($table) {
            $table->id();
            $table->foreignId('user_id')->constrained();
            $table->string('title');
            $table->text('content');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('posts');
    }
};
```

### Teams

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Team extends Model
{
    protected $fillable = ['name', 'owner_id'];

    public function owner()
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    public function users()
    {
        return $this->belongsToMany(User::class);
    }

    public function posts()
    {
        return $this->hasMany(Post::class);
    }
}
```

### Permissions

```php
<?php

namespace App\Policies;

use App\Models\{User, Post};

class PostPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->teams()->contains('id', tenant()->id);
    }

    public function view(User $user, Post $post): bool
    {
        return $user->id === $post->user_id &&
               $post->tenant_id === tenant()->id;
    }

    public function create(User $user): bool
    {
        return $user->teams()->contains('id', tenant()->id);
    }

    public function update(User $user, Post $post): bool
    {
        return $user->id === $post->user_id &&
               $post->tenant_id === tenant()->id;
    }
}
```

### Testing

```php
<?php

uses(RefreshDatabase::class);

it('isolates data between tenants', function () {
    $tenant1 = Tenant::create(['name' => 'Tenant 1']);
    $tenant2 = Tenant::create(['name' => 'Tenant 2']);

    // Créer des posts pour chaque tenant
    $this->actingAs($user1);
    tenant($tenant1);
    Post::create(['title' => 'Post 1', 'user_id' => $user1->id, 'tenant_id' => $tenant1->id]);

    $this->actingAs($user2);
    tenant($tenant2);
    Post::create(['title' => 'Post 2', 'user_id' => $user2->id, 'tenant_id' => $tenant2->id]);

    // Vérifier l'isolation
    tenant($tenant1);
    expect(Post::count())->toBe(1);
    expect(Post::first()->title)->toBe('Post 1');

    tenant($tenant2);
    expect(Post::count())->toBe(1);
    expect(Post::first()->title)->toBe('Post 2');
});
```

## Bonnes pratiques

1. **Isolation OBLIGATOIRE** — Chaque tenant ne voit que ses données
2. **Scope les queries** — Toujours filtrer par tenant
3. **Middleware tenant** — Résoudre le tenant au début de chaque requête
4. **Tests avec tenants multiples** — Vérifier l'isolation
5. **Migration par tenant** si DB per tenant
6. **Facturation par tenant** — Pricing par seat ou usage
7. **Audit** — Logger les actions par tenant
8. **Backup par tenant** — Restauration sélective
9. **Rate limiting par tenant** — Pas de shared limits
10. **Monitoring par tenant** — Métriques isolées

## Validation

- [ ] Tenant scope sur tous les modèles
- [ ] Middleware tenant configuré
- [ ] Tests d'isolation
- [ ] Permissions par tenant
- [ ] Facturation par tenant
- [ ] Backup par tenant
