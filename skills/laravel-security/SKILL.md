---
name: laravel-security
description: >
  Sécurité des applications Laravel 13. Auth, authorization, CSRF, injection,
  headers, rate limiting, audit. Utiliser quand on sécurise une app, on audit
  du code, on configure l'auth, ou on répond à une faille de sécurité.
license: MIT
compatibility: "Claude Code, Codex, OpenCode, Pi, omp"
allowed-tools: Read Write Glob Grep Bash
user-invocable: true
---

# Laravel Security — Sécurité Laravel 13

Tu es un expert en sécurité Laravel 13. Ton rôle est de durcir les applications
contre les vulnérabilités courantes.

## Quand utiliser

- Sécuriser une application Laravel
- Auditor du code pour des failles
- Configurer l'authentification et l'autorisation
- Répondre à une CVE ou une faille signalée

## Quand NE PAS utiliser

- Feature development (pas de sécurité)
- Performance optimization
- Déploiement

## Checklist sécurité

### Authentification

```php
// ✅ Bon : Rate limiting sur login
Route::post('/login', [LoginController::class, 'login'])
    ->middleware('throttle:5,1');

// ✅ Bon : Validation forte du mot de passe
class StoreUserRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'password' => ['required', 'string', Password::min(8)->mixedCase()->numbers()->symbols()],
        ];
    }
}

// ✅ Bon : Confirmation de mot de passe pour actions sensibles
Route::middleware('password.confirm')->group(function () {
    Route::delete('/account', [AccountController::class, 'destroy']);
});
```

### Authorization

```php
<?php

namespace App\Policies;

use App\Models\Post;
use App\Models\User;

class PostPolicy
{
    public function viewAny(User $user): bool
    {
        return true;
    }

    public function view(User $user, Post $post): bool
    {
        return $user->id === $post->user_id;
    }

    public function create(User $user): bool
    {
        return $user->hasVerifiedEmail();
    }

    public function update(User $user, Post $post): bool
    {
        return $user->id === $post->user_id;
    }

    public function delete(User $user, Post $post): bool
    {
        return $user->id === $post->user_id;
    }
}
```

### Mass Assignment

```php
<?php

// ✅ Bon : $fillable (whitelist)
class Post extends Model
{
    protected $fillable = ['title', 'content', 'user_id'];
}

// ✅ Bon : $guarded (blacklist)
class Post extends Model
{
    protected $guarded = ['id', 'created_at', 'updated_at'];
}

// ❌ Mal : ni $fillable ni $guarded
class Post extends Model
{
    // Risque de mass assignment vulnerability
}
```

### SQL Injection

```php
// ✅ Bon : Requêtes préparées
Post::where('user_id', $userId)->get();
DB::select('SELECT * FROM posts WHERE user_id = ?', [$userId]);

// ❌ Mal : Injection SQL
DB::select("SELECT * FROM posts WHERE user_id = $userId");
Post::whereRaw("user_id = $userId")->get();
```

### XSS

```blade
{{-- ✅ Bon : Échappement automatique --}}
{{ $user->name }}

{{-- ❌ Mal : Pas d'échappement --}}
{!! $user->name !!}  {{-- Seulement si nécessaire et avec nettoyage --}}
```

### CSRF

```php
// ✅ Bon : CSRF token dans les formulaires
<form method="POST" action="/posts">
    @csrf
    <input type="text" name="title">
</form>

// ✅ Bon : Exclusion pour les webhooks
class VerifyCsrfToken extends Middleware
{
    protected $except = [
        'webhooks/*',
    ];
}
```

### Headers de sécurité

```php
// ✅ Bon : Headers de sécurité dans Kernel
protected $middlewareGroups = [
    'web' => [
        \Illuminate\Http\Middleware\HandleCors::class,
        \App\Http\Middleware\EncryptCookies::class,
        // ...
    ],
];

// ✅ Bon : CSP Headers
class ContentSecurityPolicyHeaders
{
    public function handle($request, Closure $next)
    {
        $response = $next($request);
        $response->headers->set('Content-Security-Policy', "default-src 'self'");
        $response->headers->set('X-Content-Type-Options', 'nosniff');
        $response->headers->set('X-Frame-Options', 'DENY');
        $response->headers->set('X-XSS-Protection', '1; mode=block');
        return $response;
    }
}
```

### Rate Limiting

```php
<?php

use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Http\Request;

Route::middleware('throttle:api')->group(function () {
    Route::get('/user', function (Request $request) {
        return $request->user();
    });
});

// Configurer dans AppServiceProvider
RateLimiter::for('api', function (Request $request) {
    return Limit::perMinute(60)->by($request->user()?->id ?: $request->ip());
});
```

### Environnement

```ini
# ✅ Bon : Variables d'env pour les secrets
APP_KEY=base64:...
DB_PASSWORD=secret
MAIL_PASSWORD=secret

# ❌ Mal : Secrets en dur dans le code
$apiKey = 'sk-1234567890abcdef';
```

## Audit de sécurité

```bash
# Vérifier les dépendances vulnérables
composer audit

# Vérifier les variables d'env exposées
grep -r "password\|secret\|key" --include="*.php" .

# Vérifier les masses assignment
grep -r "protected \$guarded = \[\]" --include="*.php" .

# Vérifier les requêtes Raw
grep -r "whereRaw\|DB::select\|DB::statement" --include="*.php" .
```

## Bonnes pratiques

1. **Validation côté serveur TOUJOURS** — Même si le frontend valide
2. **Mass assignment protection** — `$fillable` ou `$guarded`
3. **Rate limiting** — Sur tous les endpoints sensibles
4. **CSP headers** — En production
5. **Audit des dépendances** — `composer audit` régulièrement
6. **Pas de secrets en dur** — Toujours les variables d'env
7. **HTTPS partout** — Rediriger HTTP → HTTPS
8. **Cookies sécurisés** — `secure`, `httpOnly`, `sameSite`
9. **Logging des actions sensibles** — Audit trail
10. **Principe du moindre privilège** — Le moins de permissions possible

## Validation

- [ ] `composer audit` passe sans vulnerabilities
- [ ] Tous les modèles ont `$fillable` ou `$guarded`
- [ ] Rate limiting sur les endpoints auth
- [ ] CSP headers configurés
- [ ] Pas de secrets en dur
- [ ] HTTPS forcé
- [ ] Cookies sécurisés
