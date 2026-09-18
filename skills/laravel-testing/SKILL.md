---
name: laravel-testing
description: >
  Stratégie de test pour Laravel 13 avec Pest et PHPUnit. Tests unitaires,
  feature, HTTP, database, snapshots. Utiliser quand on écrit des tests,
  on veut améliorer la couverture, on configure le CI, ou on debug un test.
license: MIT
compatibility: "Claude Code, Codex, OpenCode, Pi, omp"
allowed-tools: Read Write Glob Grep Bash
user-invocable: true
---

# Laravel Testing — Tests Laravel 13

Tu es un expert en tests Laravel 13. Ton rôle est de guider l'écriture de tests
robustes avec Pest ou PHPUnit.

## Quand utiliser

- Écrire de nouveaux tests
- Améliorer la couverture de tests
- Debuguer un test qui échoue
- Configurer le CI pour les tests
- Ajouter des factories

## Quand NE PAS utiliser

- Écrire du code de production (pas de test)
- Déployer l'application
- Configurer le serveur

## Processus

| Phase | Objectif | Livrable |
|-------|----------|----------|
| 1. Analyse | Identifier ce qui doit être testé | Stratégie de test |
| 2. Setup | Configurer l'environnement de test | Config valide |
| 3. Écriture | Écrire les tests | Tests Pest/PHPUnit |
| 4. Validation | Vérifier que les tests passent | Tests verts |

## Patterns de test

### Test HTTP (Feature)

```php
<?php

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('can list posts', function () {
    $posts = Post::factory()->count(3)->create();

    $response = $this->getJson('/api/posts');

    $response->assertOk()
        ->assertJsonCount(3, 'data');
});

it('requires authentication', function () {
    $response = $this->getJson('/api/posts');

    $response->assertUnauthorized();
});

it('can create a post', function () {
    $user = User::factory()->create();

    $response = $this->actingAs($user)
        ->postJson('/api/posts', [
            'title' => 'Test',
            'content' => 'Content',
        ]);

    $response->assertCreated()
        ->assertJsonFragment(['title' => 'Test']);
});
```

### Test Unit

```php
<?php

use App\Models\Post;

it('generates slug from title', function () {
    $post = new Post(['title' => 'Hello World']);

    expect($post->getSlug())->toBe('hello-world');
});

it('casts published_at to datetime', function () {
    $post = Post::factory()->create([
        'published_at' => '2026-01-15 10:00:00',
    ]);

    expect($post->published_at)->toBeInstanceOf(\Illuminate\Support\Carbon::class);
});
```

### Test avec Factories

```php
<?php

use App\Models\User;
use App\Models\Post;

it('can access own posts', function () {
    $user = User::factory()->create();
    $post = Post::factory()->create(['user_id' => $user->id]);

    $this->actingAs($user)
        ->getJson("/api/posts/{$post->id}")
        ->assertOk();
});

it('cannot access other user posts', function () {
    $user = User::factory()->create();
    $other = User::factory()->create();
    $post = Post::factory()->create(['user_id' => $other->id]);

    $this->actingAs($user)
        ->getJson("/api/posts/{$post->id}")
        ->assertForbidden();
});
```

### Test de Job

```php
<?php

use App\Jobs\ProcessPodcast;
use Illuminate\Support\Facades\Queue;

it('dispatches job to correct queue', function () {
    Queue::fake();

    ProcessPodcast::dispatch($podcast);

    Queue::assertPushed(ProcessPodcast::class, function ($job) {
        return $job->queue === 'podcasts';
    });
});
```

### Test de Event

```php
<?php

use App\Events\PostPublished;
use Illuminate\Support\Facades\Event;

it('fires event when post is published', function () {
    Event::fake();

    $post = Post::factory()->create(['is_published' => false]);
    $post->update(['is_published' => true]);

    Event::assertDispatched(PostPublished::class, function ($event) use ($post) {
        return $event->post->id === $post->id;
    });
});
```

### Test de Notification

```php
<?php

use App\Models\User;
use App\Notifications\PostCommented;
use Illuminate\Support\Facades\Notification;

it('sends notification to post author', function () {
    Notification::fake();

    $author = User::factory()->create();
    $post = Post::factory()->create(['user_id' => $author->id]);
    $commenter = User::factory()->create();

    // Créer un commentaire
    $this->actingAs($commenter)
        ->postJson("/api/posts/{$post->id}/comments", [
            'content' => 'Great post!',
        ]);

    Notification::assertSentTo($author, PostCommented::class);
});
```

## Bonnes pratiques

1. **Préférer Pest** — Syntaxe plus moderne et lisible
2. **Utiliser `RefreshDatabase`** — Pour les tests qui touchent la DB
3. **Utiliser des factories** — Pas de données de test en dur
4. **Tester les controllers via HTTP** — Pas de test de logique interne
5. **Un test = un comportement** — Pas de tests multi-scénarios
6. **Nommer descriptivement** — `it_can_create_a_post`, pas `test_create`
7. **Utiliser `actingAs`** — Pour simuler l'authentification
8. **Fake les services externes** — `Queue::fake()`, `Event::fake()`, `Notification::fake()`
9. **Tests rapides** — Éviter les appels réseau, fake les services
10. **Couverture cible** — 80%+ sur le code métier

## Validation

- [ ] Tous les tests passent (`php artisan test`)
- [ ] Pas de déprecation warnings
- [ ] Factories utilisées partout
- [ ] Services externes fakés
- [ ] Tests nommés descriptivement
