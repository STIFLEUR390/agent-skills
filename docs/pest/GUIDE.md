# Guide d'utilisation — pest

Pest PHP — testing framework élégant.

---

## Installation

```bash
composer require pestphp/pest --dev --with-all-dependencies
./vendor/bin/pest --init
```

---

## Exemple 1 — Test simple

**Demander**：
```
Écris un test pour la fonction sum().
```

**Le skill génère**：

```php
it('performs sums', function () {
    expect(sum(1, 2))->toBe(3);
});
```

---

## Exemple 2 — Test Laravel avec factory

**Demander**：
```
Teste l'endpoint GET /api/posts avec des données factory.
```

**Le skill génère**：

```php
it('can list posts', function () {
    Post::factory()->count(3)->create();

    $this->getJson('/api/posts')
        ->assertOk()
        ->assertJsonCount(3, 'data');
});
```

---

## Exemple 3 — Dataset

**Demander**：
```
Teste la validation d'email avec plusieurs cas.
```

**Le skill génère**：

```php
it('validates emails', function (string $email, bool $expected) {
    expect(Validator::isValid($email))->toBe($expected);
})->with([
    'valid' => ['test@example.com', true],
    'invalid' => ['not-an-email', false],
    'empty' => ['', false],
]);
```

---

## Voir aussi

- `laravel-testing` — Tests Laravel avec Pest
- `laravel-core` — Fondamentaux Laravel
