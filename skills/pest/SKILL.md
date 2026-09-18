---
name: pest
description: >
  Pest PHP — framework de test élégant pour PHP. Expectation API, datasets,
  hooks, architecture testing, mocking, snapshot testing, browser testing,
  mutation testing, CI/CD, plugins. Utiliser quand on écrit des tests PHP,
  on configure Pest, on veut améliorer la couverture, ou on debug un test.
license: MIT
compatibility: "Claude Code, Codex, OpenCode, Pi, omp"
allowed-tools: Read Write Glob Grep Bash
user-invocable: true
---

# Pest PHP — Testing Framework

Tu es un expert Pest PHP. Ton rôle est de guider l'écriture de tests élégants
et efficaces avec Pest.

## Quand utiliser

- Écrire des tests PHP avec Pest
- Configurer le test suite
- Utiliser des datasets, hooks, mocking
- Faire du architecture testing
- Configurer le CI/CD pour les tests
- Optimiser les tests (parallel, TIA, profiling)

## Quand NE PAS utiliser

- Tests avec PHPUnit pur (sans Pest)
- Configuration de serveur
- Code de production (pas de test)

## Installation

```bash
composer require pestphp/pest --dev --with-all-dependencies
./vendor/bin/pest --init
```

## Structure

```
tests/
├── Unit/
│   └── ExampleTest.php
├── Feature/
│   └── ExampleTest.php
├── Datasets/
│   └── Emails.php
├── Pest.php
└── TestCase.php
```

## Syntaxe de base

```php
<?php

// test() — nom explicite
test('sum', function () {
    $result = sum(1, 2);
    expect($result)->toBe(3);
});

// it() — préfixe "it"
it('performs sums', function () {
    $result = sum(1, 2);
    expect($result)->toBe(3);
});

// describe() — grouper les tests
describe('sum', function () {
    it('may sum integers', function () {
        expect(sum(1, 2))->toBe(3);
    });

    it('may sum floats', function () {
        expect(sum(1.5, 2.5))->toBe(4.0);
    });
});
```

## Expectation API

```php
<?php

// Comparaisons
expect($value)->toBe(3);              // strict equality
expect($value)->toEqual(3);           // loose equality
expect($value)->toBeInt();
expect($value)->toBeString();
expect($value)->toBeTrue();
expect($value)->toBeFalse();
expect($value)->toBeNull();
expect($value)->toBeEmpty();
expect($value)->toBeArray();
expect($value)->toBeObject();
expect($value)->toBeFloat();
expect($value)->toBeBool();
expect($value)->toBeNumeric();
expect($value)->toBeEmail();
expect($value)->toBeUrl();
expect($value)->toBeUuid();
expect($value)->toBeJson();

// Contenu
expect($array)->toContain(2, 4);
expect($string)->toContain('Hello');
expect($string)->toStartWith('Hello');
expect($string)->toEndWith('World');
expect($string)->toMatch('/pattern/');

// Taille
expect($array)->toHaveCount(4);
expect($string)->toHaveLength(5);

// Clés
expect($array)->toHaveKey('name');
expect($array)->toHaveKeys(['id', 'name']);

// Objets
expect($user)->toHaveProperty('name');
expect($user)->toHaveProperty('name', 'Nuno');
expect($user)->toBeInstanceOf(User::class);

// Comparaison d'objets
expect($user)->toMatchObject(['name' => 'Nuno']);

// Exceptions
expect(fn () => throw new Exception('msg'))->toThrow(Exception::class);
expect(fn () => throw new Exception('msg'))->toThrow('msg');

// Negation
expect($value)->not->toBe(3);
expect($value)->not->toBeString();

// Chainage
expect($value)
    ->toBeInt()
    ->toBeGreaterThan(0)
    ->toBeLessThan(100);

// and() — verifier deux valeurs
expect($id)->toBe(14)->and($name)->toBe('Nuno');

// each() — verifier chaque element
expect([1, 2, 3])->each->toBeInt();

// sequence() — verifier dans l'ordre
expect([1, 2, 3])->sequence(
    fn ($n) => $n->toBe(1),
    fn ($n) => $n->toBe(2),
    fn ($n) => $n->toBe(3),
);

// json() — decoder et tester
expect('{"name":"Nuno"}')
    ->json()
    ->name->toBe('Nuno');

// Modifiers
expect($value)->when($condition, fn ($v) => $v->toBe(1));
expect($value)->unless($condition, fn ($v) => $v->toBe(2));
```

## Hooks

```php
<?php

// beforeEach — avant chaque test
beforeEach(function () {
    $this->user = User::factory()->create();
});

// afterEach — apres chaque test
afterEach(function () {
    // cleanup
});

// beforeAll — une fois avant tous les tests du fichier
beforeAll(function () {
    // setup une seule fois (pas de $this)
});

// afterAll — une fois apres tous les tests
afterAll(function () {
    // cleanup une seule fois
});

// after() — cleanup specifique a un test
it('creates a user', function () {
    // ...
})->after(function () {
    // cleanup specifique
});
```

## Datasets

```php
<?php

// Dataset inline
it('has emails', function (string $email) {
    expect($email)->not->toBeEmpty();
})->with(['enunomaduro@gmail.com', 'other@example.com']);

// Dataset avec cles
it('has emails', function (string $email) {
    expect($email)->not->toBeEmpty();
})->with([
    'james' => 'james@laravel.com',
    'taylor' => 'taylor@laravel.com',
]);

// Dataset partage (tests/Datasets/Emails.php)
dataset('emails', [
    'enunomaduro@gmail.com',
    'other@example.com',
]);

it('has emails', function (string $email) {
    expect($email)->not->toBeEmpty();
})->with('emails');

// Dataset avec closures (lazy evaluation)
it('can generate user', function (User $user) {
    expect($user)->toBeInstanceOf(User::class);
})->with([
    fn () => User::factory()->create(['name' => 'Nuno']),
    fn () => User::factory()->create(['name' => 'Luke']),
]);

// Cartesian product
dataset('days', ['Saturday', 'Sunday']);

test('business is closed', function (string $business, string $day) {
    expect(new $business)->isClosed($day)->toBeTrue();
})->with([Office::class, Bank::class])->with('days');
```

## Exceptions

```php
<?php

it('throws exception', function () {
    throw new Exception('Something happened.');
})->throws(Exception::class);

it('throws with message', function () {
    throw new Exception('Something happened.');
})->throws(Exception::class, 'Something happened.');

it('throws only message', function () {
    throw new Exception('Something happened.');
})->throws('Something happened.');

it('throws conditionally', function () {
    // ...
})->throwsIf(fn () => DB::getDriverName() === 'mysql', Exception::class);

it('throws no exceptions', function () {
    $result = 1 + 1;
})->throwsNoExceptions();
```

## Filtering

```php
<?php

// --bail : stop au premier echec
./vendor/bin/pest --bail

// --dirty : tests avec changements non commits
./vendor/bin/pest --dirty

// --filter : regex sur les tests
./vendor/bin/pest --filter "test description"

// --group / --exclude-group
./vendor/bin/pest --group=integration
./vendor/bin/pest --exclude-group=slow

// --retry : re-run les tests echoues en premier
./vendor/bin/pest --retry

// only() : focus sur un test
pest()->only();  // fichier
test('sum', function () { ... })->only();  // test specifique

// --flaky : retry automatique des tests instables
it('may fail', function () {
    // ...
})->flaky(tries: 3);
```

## Skipping

```php
<?php

it('has home', function () {
    // ...
})->skip();

it('has home', function () {
    // ...
})->skip('temporarily unavailable');

it('has home', function () {
    // ...
})->skip(fn () => DB::getDriverName() !== 'mysql', 'db not supported');

it('has home', function () {
    // ...
})->skipLocally();

it('has home', function () {
    // ...
})->skipOnWindows();

// todo() : marquer comme a faire
it('has home', function () {
    // ...
})->todo();
```

## Mocking

```php
<?php

use Mockery;

it('may buy a book', function () {
    $client = Mockery::mock(PaymentClient::class);
    $client->shouldReceive('post')->andReturn('response');

    $books = new BookRepository($client);
    $books->buy();
});

// Argument expectations
$client->shouldReceive('post')->with(1, Mockery::any());

// Return values
$client->shouldReceive('post')->andReturn(1, 2);
$client->shouldReceive('post')->andThrow(new Exception);

// Count expectations
$mock->shouldReceive('post')->once();
$mock->shouldReceive('post')->times(3);
```

## Snapshot Testing

```php
<?php

it('has a contact page', function () {
    $response = $this->get('/contact');
    expect($response)->toMatchSnapshot();
});

// Mettre a jour les snapshots
./vendor/bin/pest --update-snapshots
```

## Architecture Testing

```php
<?php

arch()
    ->expect('App')
    ->toUseStrictTypes()
    ->not->toUse(['die', 'dd', 'dump']);

arch()
    ->expect('App\Models')
    ->toBeClasses()
    ->toExtend('Illuminate\Database\Eloquent\Model');

arch()
    ->expect('App\Http')
    ->toOnlyBeUsedIn('App\Http');

// Presets
arch()->preset()->php();
arch()->preset()->security();
arch()->preset()->laravel();
arch()->preset()->strict();

// Modifiers
arch()
    ->expect('App\Models')
    ->classes()
    ->toBeFinal();

arch()
    ->expect('App\Services')
    ->ignoring('App\Support');
```

## Custom Expectations

```php
<?php

// tests/Pest.php ou tests/Expectations.php
expect()->extend('toBeWithinRange', function (int $min, int $max) {
    return $this->toBeGreaterThanOrEqual($min)
                ->toBeLessThanOrEqual($max);
});

// Utilisation
expect(100)->toBeWithinRange(90, 110);

// Intercepter une expectation existante
expect()->intercept('toBe', Model::class, function (Model $expected) {
    expect($this->value->id)->toBe($expected->id);
});
```

## Configuration (Pest.php)

```php
<?php

// tests/Pest.php

// Base test case
pest()->extend(TestCase::class)->in('Feature');

// Traits
pest()->use(RefreshDatabase::class)->in('Feature');

// Groupes
pest()->group('integration')->in('Feature');

// Hooks globaux
pest()->beforeEach(function () {
    // avant chaque test
})->in('Feature');

// Browser testing
pest()->browser()->timeout(10000);
pest()->browser()->headed();

// TIA (Test Impact Analysis)
pest()->tia()->locally();
```

## Parallel Testing

```bash
# Parallele
./vendor/bin/pest --parallel

# Nombre de processus
./vendor/bin/pest --parallel --processes=10

# Sharding
./vendor/bin/pest --shard=1/4

# Time-balanced sharding
./vendor/bin/pest --update-shards
./vendor/bin/pest --shard=1/4
```

## CI/CD

```yaml
# GitHub Actions
name: Tests
on: ['push', 'pull_request']
jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: shivammathur/setup-php@v2
        with:
          php-version: 8.4
          coverage: xdebug
      - run: composer install --no-interaction
      - run: ./vendor/bin/pest --ci
```

## Code Coverage

```bash
# Coverage
./vendor/bin/pest --coverage

# Minimum threshold
./vendor/bin/pest --coverage --min=90

# Exact threshold
./vendor/bin/pest --coverage --exactly=99.3

# Formats
./vendor/bin/pest --coverage-html=report
./vendor/bin/pest --coverage-clover=report.xml
```

## Mutation Testing

```php
<?php

// Marquer ce qui est teste
covers(TodoController::class);

it('list todos', function () {
    $this->getJson('/todos')->assertStatus(200);
});
```

```bash
# Lancer
./vendor/bin/pest --mutate
./vendor/bin/pest --mutate --parallel
./vendor/bin/pest --mutate --min=80
```

## Plugins officiels

```bash
# Laravel plugin
composer require pestphp/pest-plugin-laravel --dev

# Livewire plugin
composer require pestphp/pest-plugin-livewire --dev

# Browser testing
composer require pestphp/pest-plugin-browser --dev
npm install playwright@latest

# Faker
composer require pestphp/pest-plugin-faker --dev

# PHPStan
composer require pestphp/pest-plugin-phpstan --dev

# Rector
composer require pestphp/pest-plugin-rector --dev

# Type Coverage
composer require pestphp/pest-plugin-type-coverage --dev

# Evals (AI testing)
composer require pestphp/pest-plugin-evals --dev

# Stress Testing
composer require pestphp/pest-plugin-stressless --dev

# Agent (verification AI)
composer require pestphp/pest-plugin-agent --dev

# Profanity check
composer require pestphp/pest-plugin-profanity --dev
```

## Bonnes pratiques

1. **Préférer `it()`** — Plus lisible que `test()`
2. **Un test = un comportement** — Pas de tests multi-scénarios
3. **Datasets** — Pour tester avec différentes valeurs
4. **Mocks** — Pour isoler les dépendances externes
5. **Architecture tests** — Pour les règles d'architecture
6. **Coverage minimum** — `--min=80` en CI
7. **Parallel** — `--parallel` pour la vitesse
8. **TIA** — `--tia` en dev pour les tests rapides
9. **Snapshots** — Pour les sorties complexes
10. **Custom expectations** — Pour les assertions réutilisables

## Cross-références

- `laravel-testing` — Tests Laravel avec Pest
- `laravel-core` — Fondamentaux Laravel
