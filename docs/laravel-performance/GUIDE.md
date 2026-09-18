# Guide d'utilisation — laravel-performance

Optimisation des performances Laravel 13.

---

## Quand l'utiliser

- Application lente
- Requêtes DB lentes (N+1)
- Configuration du cache
- Profiling des performances

---

## Exemple 1 — Détecter le N+1

**Demander** :
```
Trouve les N+1 queries dans ce projet.
```

**Le skill fait** :

```bash
# Activer la détection en dev
# app/Providers/AppServiceProvider.php
Model::preventLazyLoading(!app()->isProduction());

# Chercher les foreach qui accèdent aux relations
grep -r "->with(" --include="*.php" app/
```

---

## Exemple 2 — Ajouter du cache

**Demander** :
```
Cache la liste des posts pendant 30 minutes.
```

**Le skill génère** :

```php
$posts = Cache::remember('posts.all', now()->addMinutes(30), function () {
    return Post::with('user')->latest()->paginate(20);
});
```

---

## Exemple 3 — Optimiser une requête

**Demander** :
```
Optimise cette requête qui est lente.
```

**Le skill suggère** :

```php
// ❌ Avant
$posts = Post::all();
foreach ($posts as $post) {
    echo $post->user->name; // N+1 !
}

// ✅ Après
$posts = Post::with('user')->get();
```

---

## Bonnes pratiques

1. **`preventLazyLoading()`** — Détecter le N+1
2. **`Cache::remember()`** — Cache les queries fréquentes
3. **`paginate()`** — Toujours paginer
4. **Index** — Sur les colonnes query
5. **Jobs** — Pour les tâches longues

---

## Voir aussi

- `laravel-core` — Fondamentaux
- `laravel-queue` — Tâches asynchrones
