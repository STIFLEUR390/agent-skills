# Guide d'utilisation — laravel-ai

Intégration AI/LLM dans Laravel 13.

---

## Quand l'utiliser

- Intégrer un LLM (OpenAI, Anthropic)
- Créer un agent AI
- Implémenter du RAG
- Générer des embeddings

---

## Exemple 1 — Agent simple

**Demander** :
```
Crée un agent AI qui analyse le texte.
```

**Le skill génère** :

```php
<?php

class TextAnalyzer extends \Laravel\Ai\Agent
{
    protected string $model = 'gpt-4o';

    public function instructions(): string
    {
        return 'Tu analyses le texte et identifies le ton, les thèmes clés.';
    }
}

// Utilisation
$response = TextAnalyzer::make()->prompt('Analyse ce texte...');
return (string) $response;
```

---

## Exemple 2 — RAG

**Demander** :
```
Implémente une recherche sémantique sur mes documents.
```

**Le skill génère** :

```php
// Générer des embeddings
$embedding = Str::of($document->content)->toEmbeddings();

// Recherche
$documents = DB::table('documents')
    ->whereVectorSimilarTo('embedding', $query)
    ->limit(5)
    ->get();
```

---

## Voir aussi

- `laravel-core` — Fondamentaux
- `laravel-mcp` — Serveur MCP
- `laravel-queue` — Jobs pour les appels LLM
