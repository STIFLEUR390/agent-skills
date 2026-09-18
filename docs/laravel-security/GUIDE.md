# Guide d'utilisation — laravel-security

Sécurité des applications Laravel 13.

---

## Quand l'utiliser

- Sécuriser une application Laravel
- Auditor du code pour des failles
- Configurer l'authentification
- Répondre à une faille de sécurité

---

## Exemple 1 — Audit rapide

**Demander** :
```
Audit la sécurité de ce projet Laravel.
```

**Le skill fait** :

```bash
# Vérifier les dépendances vulnérables
composer audit

# Vérifier les masses assignment
grep -r "protected \$guarded = \[\]" --include="*.php" .

# Vérifier les requêtes Raw
grep -r "whereRaw\|DB::select" --include="*.php" .
```

---

## Exemple 2 — Configurer le rate limiting

**Demander** :
```
Ajoute du rate limiting sur l'endpoint de login.
```

**Le skill génère** :

```php
Route::post('/login', [LoginController::class, 'login'])
    ->middleware('throttle:5,1'); // 5 tentatives par minute
```

---

## Exemple 3 — Policy d'autorisation

**Demander** :
```
Crée une policy pour les posts : seul l'auteur peut modifier.
```

**Le skill génère** :

```php
<?php

namespace App\Policies;

use App\Models\{Post, User};

class PostPolicy
{
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

---

## Checklist sécurité

- [ ] `composer audit` passe
- [ ] `$fillable` ou `$guarded` sur tous les modèles
- [ ] Rate limiting sur les endpoints auth
- [ ] CSP headers configurés
- [ ] Pas de secrets en dur
- [ ] HTTPS forcé

---

## Voir aussi

- `laravel-core` — Conventions de sécurité
- `laravel-api` — Sécurité des APIs
