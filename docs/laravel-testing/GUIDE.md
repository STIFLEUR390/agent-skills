# Guide d'utilisation — laravel-testing

Tests Laravel 13 avec Pest et PHPUnit.

---

## Quand l'utiliser

- Écrire de nouveaux tests
- Debuguer un test qui échoue
- Améliorer la couverture de tests
- Configurer le CI pour les tests

---

## Exemple 1 — Test HTTP simple

**Demander** :
```
Écris un test pour vérifier que l'endpoint GET /api/posts fonctionne.
```

**Le skill génère** :

```php
<?php

use App\Models\Post;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('can list posts', function () {
    $posts = Post::factory()->count(3)->create();

    $response = $this->getJson('/api/posts');

    $response->assertOk()
        ->assertJsonCount(3, 'data');
});
```

---

## Exemple 2 — Test avec authentification

**Demander** :
```
Teste que seul l'auteur peut modifier son post.
```

**Le skill génère** :

```php
<?php

it('allows author to update own post', function () {
    $user = User::factory()->create();
    $post = Post::factory()->create(['user_id' => $user->id]);

    $this->actingAs($user)
        ->putJson("/api/posts/{$post->id}", ['title' => 'Updated'])
        ->assertOk();
});

it('prevents others from updating post', function () {
    $user = User::factory()->create();
    $other = User::factory()->create();
    $post = Post::factory()->create(['user_id' => $other->id]);

    $this->actingAs($user)
        ->putJson("/api/posts/{$post->id}", ['title' => 'Hacked'])
        ->assertForbidden();
});
```

---

## Exemple 3 — Fake les services externes

**Demander** :
```
Teste l'envoi d'un email sans vraiment envoyer.
```

**Le skill génère** :

```php
<?php

use App\Models\User;
use App\Notifications\WelcomeNotification;
use Illuminate\Support\Facades\Notification;

it('sends welcome notification on registration', function () {
    Notification::fake();

    $user = User::factory()->create();

    Notification::assertSentTo($user, WelcomeNotification::class);
});
```

---

## Règles importantes

1. **Préférer Pest** — Syntaxe plus moderne
2. **`RefreshDatabase`** — Pour les tests qui touchent la DB
3. **Factories** — Pas de données en dur
4. **`actingAs`** — Pour simuler l'auth
5. **Fakes** — `Queue::fake()`, `Event::fake()`, `Notification::fake()`

---

## Voir aussi

- `laravel-security` — Sécurité des tests
- `laravel-core` — Conventions de naming pour les tests
