# Architecture Laravel 13

## Nouveautés Laravel 13

### PHP 8.3 minimum
- Readonly properties
- `match` expressions (remplace nested ternary)
- Enums (backed et non-backed)
- First-class callable syntax
- Named arguments (attention : les noms peuvent changer entre versions)

### AI SDK natif
Laravel 13 inclut le `laravel/ai` — un SDK unifié pour OpenAI, Anthropic, Gemini, etc.

```php
use Laravel\Ai\Image;

$response = agent()->prompt('Analyse ce code...');
$image = Image::of('Un donut sur le comptoir')->generate();
```

### JSON:API Resources
Réponses conformes au standard JSON:API :
```php
use App\Http\Resources\JsonApiResource;

return JsonApiResource::make($post);
```

### PHP Attributes étendus
```php
#[Middleware('auth')]
#[Authorize('create', [Comment::class, 'post'])]
public function store(Post $post) { ... }

#[Tries(3)]
#[Timeout(60)]
#[Backoff(60)]
class ProcessPodcast implements ShouldQueue { ... }
```

### Queue Routing
```php
Queue::route(ProcessPodcast::class, connection: 'redis', queue: 'podcasts');
```

### Cache TTL Extension
```php
Cache::touch('key', 300); // Étend le TTL sans re-stocker
```

### Semantic / Vector Search
```php
$documents = DB::table('documents')
    ->whereVectorSimilarTo('embedding', 'Meilleurs vins de Napa Valley')
    ->limit(10)
    ->get();
```

### PreventRequestForgery
Nouveau middleware `PreventRequestForgery` avec vérification d'origine.

## Structure standard

```
project/
├── app/
│   ├── Http/
│   │   ├── Controllers/
│   │   ├── Middleware/
│   │   └── Requests/
│   ├── Models/
│   ├── Services/
│   ├── Jobs/
│   ├── Events/
│   ├── Listeners/
│   ├── Notifications/
│   ├── Policies/
│   ├── Exceptions/
│   └── Providers/
├── bootstrap/
├── config/
├── database/
│   ├── migrations/
│   ├── seeders/
│   └── factories/
├── public/
├── resources/
│   ├── views/
│   ├── css/
│   └── js/
├── routes/
│   ├── web.php
│   ├── api.php
│   ├── console.php
│   └── channels.php
├── storage/
├── tests/
│   ├── Feature/
│   └── Unit/
├── composer.json
└── artisan
```

## Conventions de naming

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
| Config key | snake_case | `app.name`, `database.default` |
| Env variable | SCREAMING_SNAKE_CASE | `APP_NAME`, `DB_HOST` |
