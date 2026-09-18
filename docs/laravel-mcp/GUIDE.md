# Guide d'utilisation — laravel-mcp

Serveur MCP pour Laravel 13.

---

## Quand l'utiliser

- Exposer des données à un assistant AI
- Créer un serveur MCP
- Configurer Laravel Boost

---

## Exemple 1 — Tool MCP

**Demander** :
```
Crée un tool MCP pour rechercher des users.
```

**Le skill génère** :

```php
<?php

class SearchUsers extends \Laravel\Mcp\Tool
{
    protected string $name = 'search_users';
    protected string $description = 'Recherche des utilisateurs par nom';

    public function execute(array $params): array
    {
        $users = DB::table('users')
            ->where('name', 'LIKE', "%{$params['query']}%")
            ->limit(10)
            ->get();

        return [
            'content' => [['type' => 'text', 'text' => json_encode($users)]],
        ];
    }
}
```

---

## Voir aussi

- `laravel-core` — Fondamentaux
- `laravel-ai` — AI/LLM
- `laravel-api` — API classiques
