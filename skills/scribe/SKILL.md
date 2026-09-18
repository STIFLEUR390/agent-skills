---
name: scribe
description: >
  Scribe — génération de documentation API pour Laravel. Annotations docblock,
  PHP attributes, response calls, Postman collection, OpenAPI spec, Try It Out.
  Utiliser quand on documente une API Laravel, on génère la doc, on configure
  Scribe, ou on debug la génération de documentation.
license: MIT
compatibility: "Claude Code, Codex, OpenCode, Pi, omp"
allowed-tools: Read Write Glob Grep Bash
user-invocable: true
---

# Scribe — Documentation API Laravel

Tu es un expert Scribe pour Laravel. Ton rôle est de documenter les APIs
Laravel avec des annotations, générer la documentation, et configurer
le Postman collection et OpenAPI spec.

## Quand utiliser

- Documenter une API Laravel avec Scribe
- Ajouter des annotations aux controllers
- Générer la documentation HTML, Postman, OpenAPI
- Configurer l'auth, le Try It Out
- Debuguer la génération de documentation

## Quand NE PAS utiliser

- Documentation non-API (guides, tutorials)
- Projet sans Laravel
- API déjà documentée avec un autre outil (Swagger, etc.)

## Installation

```bash
composer require knuckleswtf/scribe --dev
php artisan vendor:publish --tag=scribe-config
```

## Configuration

```php
// config/scribe.php

return [
    // Type de docs : 'static' ou 'laravel'
    'type' => env('SCRIBE_TYPE', 'laravel'),

    // Titre de la doc
    'title' => config('app.name'),

    // Base URL affichée
    'base_url' => config('app.url'),

    // Routes à documenter
    'routes' => [
        [
            'match' => [
                'domains' => ['*'],
                'prefixes' => ['api/*'],
            ],
        ],
    ],

    // Auth
    'auth' => [
        'enabled' => true,
        'default' => true,  // tous les endpoints sont auth par défaut
        'in' => 'bearer',
        'name' => 'Authorization',
        'use_value' => env('SCRIBE_AUTH_KEY'),
        'placeholder' => '{ACCESS_TOKEN}',
    ],

    // Try It Out
    'try_it_out' => [
        'enabled' => true,
        'base_url' => config('app.url'),
    ],
];
```

## Annotations docblock

### Titre et description

```php
/**
 * Get a user.
 *
 * Retrieves the user with the given ID.
 *
 * @response 404 {"message": "User not found"}
 */
public function show(int $id)
{
    return User::findOrFail($id);
}
```

### Grouper les endpoints

```php
/**
 * @group User management
 *
 * APIs for managing users
 */
class UserController extends Controller
{
    /**
     * Create a user.
     */
    public function store()
    {
        // ...
    }
}
```

### Auth

```php
/**
 * @authenticated
 */
public function secret()
{
    // ...
}

/**
 * @unauthenticated
 */
public function publicEndpoint()
{
    // ...
}
```

### URL Parameters

```php
/**
 * @urlParam id integer required The ID of the user.
 * @urlParam lang string The language. Enum: en, fr. Example: en
 */
public function show(int $id)
{
    // ...
}
```

### Query Parameters

```php
/**
 * @queryParam sort string Field to sort by. Defaults to 'id'.
 * @queryParam fields required Comma-separated fields. Example: name,email
 * @queryParam page int Page number. Example: 1
 */
public function index()
{
    // ...
}
```

### Body Parameters

```php
/**
 * @bodyParam name string required The user's name.
 * @bodyParam email string required The user's email. Example: user@example.com
 * @bodyParam password string required The user's password. Minimum: 8 characters.
 * @bodyParam remember boolean Whether to remember the user. Example: false
 */
public function store()
{
    // ...
}
```

### Responses

```php
/**
 * @response {
 *  "id": 1,
 *  "name": "John Doe",
 *  "email": "john@example.com"
 * }
 */
public function show(int $id)
{
    return User::findOrFail($id);
}

/**
 * @response 201 {"id": 1, "name": "John Doe"}
 * @response 422 {"message": "Validation failed", "errors": {"name": ["The name field is required."]}}
 */
public function store()
{
    // ...
}

/**
 * @responseFile storage/responses/users.show.json
 */
public function show(int $id)
{
    // ...
}
```

### Response Fields

```php
/**
 * @responseField id integer The unique identifier.
 * @responseField name string The user's name.
 * @responseField email string The user's email address.
 * @responseField created_at string The creation date.
 */
public function show(int $id)
{
    return User::findOrFail($id);
}
```

### Cacher un endpoint

```php
/**
 * @hideFromAPIDocumentation
 */
public function internalEndpoint()
{
    // ...
}
```

## PHP Attributes

```php
use Knuckles\Scribe\Attributes\{Group, Authenticated, UrlParam, QueryParam, BodyParam, Response, ResponseField};

#[Group('User management')]
#[Authenticated]
class UserController extends Controller
{
    #[UrlParam('id', 'integer', required: true, 'The user ID')]
    #[Response(['id' => 1, 'name' => 'John'], 200, 'User found')]
    #[ResponseField('id', 'integer', 'The user ID')]
    public function show(int $id)
    {
        return User::findOrFail($id);
    }

    #[BodyParam('name', 'string', required: true, 'The name')]
    #[BodyParam('email', 'string', required: true, 'The email', example: 'user@example.com')]
    #[Response(['id' => 1], 201, 'User created')]
    public function store()
    {
        // ...
    }
}
```

## API Resources

```php
/**
 * @apiResource App\Http\Resources\UserResource
 * @apiResourceModel App\Models\User
 */
public function show(int $id)
{
    return new UserResource(User::findOrFail($id));
}

/**
 * @apiResourceCollection App\Http\Resources\UserResource
 * @apiResourceModel App\Models\User
 */
public function index()
{
    return UserResource::collection(User::paginate(20));
}

/**
 * @apiResourceCollection App\Http\Resources\UserResource
 * @apiResourceModel App\Models\User paginate=15
 */
public function index()
{
    return UserResource::collection(User::paginate(15));
}
```

## Validation Rules

```php
// Scribe extrait automatiquement des FormRequests
class StoreUserRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8'],
        ];
    }
}
```

## Form Requests avec annotations

```php
use Knuckles\Scribe\Attributes\{QueryParam, BodyParam};

class StoreUserRequest extends FormRequest
{
    #[BodyParam('name', 'string', required: true, 'The user name')]
    #[BodyParam('email', 'string', required: true, 'The email', example: 'user@example.com')]
    public function authorize(): bool
    {
        return true;
    }
}
```

## Génération

```bash
# Générer la doc
php artisan scribe:generate

# Avec debug
php artisan scribe:generate --verbose

# Avec un fichier .env spécifique
php artisan scribe:generate --env docs

# Forcer la régénération
php artisan scribe:generate --force
```

## Hooks (AppServiceProvider)

```php
use Knuckles\Scribe\Scribe;
use Knuckles\Scribe\Commands\GenerateDocumentation;

public function boot(): void
{
    if (class_exists(Scribe::class)) {
        // Avant les response calls (auth custom)
        Scribe::beforeResponseCall(function ($request, $endpointData) {
            $token = User::first()->api_token;
            $request->headers->set("Authorization", "Bearer $token");
        });

        // Après les response calls (filtrer les réponses)
        Scribe::afterResponseCall(function ($request, $endpointData, $response) {
            $json = $response->getData();
            if (!empty($json->data) && count($json->data) > 5) {
                $json->data = array_slice($json->data, 0, 5);
                $response->setData($json);
            }
        });

        // Après génération (upload S3, etc.)
        Scribe::afterGenerating(function (array $paths) {
            // $paths['html'], $paths['postman'], $paths['openapi']
        });
    }
}
```

## Tri des endpoints

```php
// config/scribe.php
'groups' => [
    'order' => [
        'User management' => [
            'POST /users',
            'GET /users',
        ],
        'Post management',
        '*',  // tous les autres groupes
    ],
],
```

## Multiple docs sets

```bash
# Créer un second fichier de config
cp config/scribe.php config/scribe_admin.php

# Modifier les routes dans scribe_admin.php
php artisan scribe:generate --config scribe_admin
```

## Résolution de problèmes

```bash
# Cache config
php artisan config:clear

# Cache views
php artisan view:clear

# Mémoire limitée
php -d memory_limit=1G artisan scribe:generate

# Debug mode pour les responses
# config/scribe.php → response_calls.config.app.debug = true
```

## HTML helpers

```html
<!-- Badges -->
<small class="badge badge-green">GET</small>
<small class="badge badge-darkred">REQUIRES AUTH</small>

<!-- Asides -->
<aside class="notice">This is important.</aside>
<aside class="warning">Don't do this.</aside>
<aside class="success">Do this.</aside>

<!-- Heading -->
<h4 class="fancy-heading-panel"><b>Body Parameters</b></h4>
```

## Bonnes pratiques

1. **Annotations sur le controller** — `@group` au niveau classe
2. **Form Requests** — La validation génère les docs automatiquement
3. **API Resources** — `@apiResource` pour les réponses typées
4. **Response calls** — En dev uniquement, pas en prod
5. **Postman + OpenAPI** — Toujours générer les deux
6. **Try It Out** — Configurer avec Sanctum CSRF si nécessaire
7. **Hooks** — `beforeResponseCall` pour l'auth custom
8. **Tri** — Ordonner les groupes dans le config
9. **`.scribe` folder** — Commit pour override les extras
10. **`.env.docs`** — Pour configurer la gen en CI

## Cross-références

- `laravel-core` — Fondamentaux Laravel
- `laravel-api` — REST API patterns
- `laravel-nuxt` — API pour Nuxt (les docs Scribe sont pour les consommateurs API)
