---
name: laravel-mcp
description: >
  Serveur MCP (Model Context Protocol) pour Laravel. Exposer des données et
  actions via le protocole MCP pour les outils AI. Utiliser quand on crée un
  serveur MCP, on expose des données à un assistant AI, ou on configure Laravel Boost.
license: MIT
compatibility: "Claude Code, Codex, OpenCode, Pi, omp"
allowed-tools: Read Write Glob Grep Bash
user-invocable: true
---

# Laravel MCP — Serveur MCP pour Laravel 13

Tu es un expert en MCP (Model Context Protocol) avec Laravel. Ton rôle est
d'exposer des données et actions Laravel via le protocole MCP pour les outils AI.

## Quand utiliser

- Créer un serveur MCP pour Laravel
- Exposer des données à un assistant AI
- Configurer Laravel Boost
- Créer des tools MCP personnalisés

## Installation (Laravel Boost)

```bash
composer require laravel/boost --dev
php artisan boost:install
```

## Architecture MCP

```
MCP Server
├── Tools       — Actions exécutables (GET, POST, etc.)
├── Resources   — Données exposées (lecture seule)
└── Prompts     — Templates de prompts réutilisables
```

## Tool MCP

```php
<?php

namespace App\Mcp\Tools;

use Laravel\Mcp\Tool;
use Illuminate\Support\Facades\DB;

class SearchUsers extends Tool
{
    protected string $name = 'search_users';
    protected string $description = 'Recherche des utilisateurs par nom ou email';
    protected array $inputSchema = [
        'type' => 'object',
        'properties' => [
            'query' => [
                'type' => 'string',
                'description' => 'Terme de recherche (nom ou email)',
            ],
            'limit' => [
                'type' => 'integer',
                'description' => 'Nombre max de résultats',
                'default' => 10,
            ],
        ],
        'required' => ['query'],
    ];

    public function execute(array $params): array
    {
        $users = DB::table('users')
            ->where('name', 'LIKE', "%{$params['query']}%")
            ->orWhere('email', 'LIKE', "%{$params['query']}%")
            ->limit($params['limit'] ?? 10)
            ->get();

        return [
            'content' => [
                [
                    'type' => 'text',
                    'text' => json_encode($users, JSON_PRETTY_PRINT),
                ],
            ],
        ];
    }
}
```

## Resource MCP

```php
<?php

namespace App\Mcp\Resources;

use Laravel\Mcp\Resource;
use App\Models\Post;

class PostResource extends Resource
{
    protected string $name = 'posts';
    protected string $uri = 'laravel://posts';
    protected string $description = 'Liste des articles du blog';

    public function read(): array
    {
        $posts = Post::with('user')
            ->latest()
            ->limit(50)
            ->get();

        return [
            'contents' => [
                [
                    'uri' => $this->uri,
                    'mimeType' => 'application/json',
                    'text' => json_encode($posts),
                ],
            ],
        ];
    }
}
```

## Prompt MCP

```php
<?php

namespace App\Mcp\Prompts;

use Laravel\Mcp\Prompt;

class AnalyzePost extends Prompt
{
    protected string $name = 'analyze_post';
    protected string $description = 'Analyse un article et suggère des améliorations';

    public function arguments(): array
    {
        return [
            [
                'name' => 'post_id',
                'description' => 'ID de l\'article à analyser',
                'required' => true,
            ],
        ];
    }

    public function execute(array $params): array
    {
        $post = Post::findOrFail($params['post_id']);

        return [
            'description' => "Analyse de l'article : {$post->title}",
            'messages' => [
                [
                    'role' => 'user',
                    'content' => [
                        'type' => 'text',
                        'text' => "Analyse cet article et suggère des améliorations :\n\nTitre : {$post->title}\nContenu : {$post->content}",
                    ],
                ],
            ],
        ];
    }
}
```

## Configuration

```php
// config/mcp.php
return [
    'servers' => [
        'default' => [
            'driver' => 'stdio',
            'tools' => [
                \App\Mcp\Tools\SearchUsers::class,
                \App\Mcp\Tools\GetPost::class,
            ],
            'resources' => [
                \App\Mcp\Resources\PostResource::class,
            ],
            'prompts' => [
                \App\Mcp\Prompts\AnalyzePost::class,
            ],
        ],
    ],
];
```

## .mcp.json pour les agents

```json
{
  "mcpServers": {
    "laravel": {
      "command": "php",
      "args": ["artisan", "mcp:serve"],
      "env": {
        "APP_ENV": "local"
      }
    }
  }
}
```

## Bonnes pratiques

1. **Principe du moindre privilège** — Exposer uniquement les données nécessaires
2. **Validation** — Valider les entrées MCP comme des API classiques
3. **Description claire** — Chaque tool doit avoir une description précise
4. **Rate limiting** — Sur les endpoints MCP
5. **Authentification** — Restreindre l'accès aux données sensibles
6. **Logging** — Tracer les appels MCP
7. **Tests** — Tester chaque tool individuellement
8. **Documentation** — Décrire les inputs/outputs de chaque tool

## Validation

- [ ] Tools MCP créés avec descriptions
- [ ] Resources exposées
- [ ] Prompts configurés
- [ ] .mcp.json généré
- [ ] Validation des entrées
- [ ] Rate limiting configuré
- [ ] Tests des tools
