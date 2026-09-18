---
name: laravel-ai
description: >
  Intégration AI/LLM dans Laravel 13 avec le Laravel AI SDK. Agents, tools,
  embeddings, RAG, vector stores, streaming. Utiliser quand on intègre de l'IA
  dans une app Laravel, on crée des agents, ou on fait du RAG.
license: MIT
compatibility: "Claude Code, Codex, OpenCode, Pi, omp"
allowed-tools: Read Write Glob Grep Bash
user-invocable: true
---

# Laravel AI — Intégration AI/LLM dans Laravel 13

Tu es un expert en intégration AI avec Laravel. Ton rôle est de guider
l'implémentation de features AI natives dans les applications Laravel.

## Quand utiliser

- Intégrer un LLM (OpenAI, Anthropic, etc.)
- Créer un agent AI avec tools
- Implémenter du RAG (Retrieval-Augmented Generation)
- Générer des embeddings
- Faire du streaming de réponses AI

## Installation

```bash
composer require laravel/ai
php artisan vendor:publish --provider="Laravel\Ai\AiServiceProvider"
php artisan migrate
```

## Configuration

```ini
# .env
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
GEMINI_API_KEY=...
```

## Agent simple

```php
<?php

use App\Ai\Agents\SalesCoach;

class SalesCoach extends \Laravel\Ai\Agent
{
    protected string $name = 'Sales Coach';
    protected string $model = 'gpt-4o';

    public function instructions(): string
    {
        return <<<'EOT'
        Tu es un coach commercial expert. Tu analyses les transcripts
        de vente et donnes des conseils/actionables pour améliorer
        les performances.
        EOT;
    }
}

// Utilisation
$response = SalesCoach::make()->prompt('Analyse ce transcript...');
return (string) $response;
```

## Agent avec tools

```php
<?php

use App\Ai\Agents\DataAnalyst;
use App\Ai\Tools\SearchProducts;
use App\Ai\Tools\GetSalesStats;

class DataAnalyst extends \Laravel\Ai\Agent
{
    protected string $name = 'Data Analyst';
    protected string $model = 'gpt-4o';

    public function instructions(): string
    {
        return 'Tu analyses les données de vente et identifies les tendances.';
    }

    public function tools(): array
    {
        return [
            new SearchProducts(),
            new GetSalesStats(),
        ];
    }
}

// Utilisation
$response = DataAnalyst::make()
    ->prompt('Quels sont les top produits ce mois ?')
    ->withTools();

return (string) $response;
```

## Streaming

```php
<?php

use Laravel\Ai\Enums\Lab;

// Streaming simple
$response = agent()
    ->prompt('Raconte-moi une histoire...')
    ->stream();

foreach ($response as $chunk) {
    echo $chunk;
}

// Streaming dans une response HTTP
return response()->stream(function () use ($prompt) {
    $stream = agent()->prompt($prompt)->stream();
    foreach ($stream as $chunk) {
        echo "data: " . json_encode(['content' => $chunk]) . "\n\n";
        ob_flush();
        flush();
    }
    echo "data: [DONE]\n\n";
}, 200, [
    'Content-Type' => 'text/event-stream',
    'Cache-Control' => 'no-cache',
]);
```

## Embeddings

```php
<?php

use Illuminate\Support\Facades\DB;

// Générer des embeddings
$embedding = Str::of('Laravel est un framework PHP')->toEmbeddings();

// Stocker en base (avec pgvector)
DB::table('documents')->insert([
    'content' => $document->content,
    'embedding' => $embedding->toArray(),
]);

// Recherche par similarité
$documents = DB::table('documents')
    ->whereVectorSimilarTo('embedding', 'Framework PHP moderne')
    ->limit(10)
    ->get();
```

## RAG (Retrieval-Augmented Generation)

```php
<?php

class RagService
{
    public function query(string $question): string
    {
        // 1. Rechercher les documents pertinents
        $documents = DB::table('documents')
            ->whereVectorSimilarTo('embedding', $question)
            ->limit(5)
            ->get();

        // 2. Construire le contexte
        $context = $documents->pluck('content')->implode("\n---\n");

        // 3. Prompt avec contexte
        $response = agent()->prompt(<<<EOT
            Réponds à la question en te basant sur le contexte ci-dessous.
            Si le contexte ne contient pas la réponse, dis-le.

            Contexte :
            $context

            Question : $question
        EOT);

        return (string) $response;
    }
}
```

## Images

```php
<?php

use Laravel\Ai\Image;

$image = Image::of('Un logo moderne pour une startup tech')
    ->size(1024, 1024)
    ->generate();

// Sauvegarder
Storage::disk('public')->put('images/logo.png', (string) $image);
```

## Audio (TTS)

```php
<?php

use Laravel\Ai\Audio;

$audio = Audio::of('Bienvenue dans notre application.')->generate();

Storage::disk('public')->put('audio/welcome.mp3', (string) $audio);
```

## Jobs pour les appels LLM

```php
<?php

namespace App\Jobs;

use App\Ai\Agents\DataAnalyst;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class AnalyzeSalesData implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $timeout = 120;
    public int $tries = 3;
    public string $queue = 'ai';

    public function __construct(
        public int $userId,
        public string $period,
    ) {}

    public function handle(): void
    {
        $response = DataAnalyst::make()
            ->prompt("Analyse les ventes de {$this->period}")
            ->withTools();

        // Sauvegarder le résultat
        AnalysisResult::create([
            'user_id' => $this->userId,
            'period' => $this->period,
            'result' => (string) $response,
        ]);
    }
}
```

## Providers supportés

| Feature | Providers |
|---------|-----------|
| Text | OpenAI, Anthropic, Gemini, Azure, Groq, xAI, DeepSeek, Mistral, Ollama |
| Images | OpenAI, Gemini, xAI, Azure |
| TTS | OpenAI, ElevenLabs, Gemini, Mistral |
| STT | OpenAI, ElevenLabs, Groq, Mistral |
| Embeddings | OpenAI, Gemini, Cohere, Ollama |
| Reranking | Cohere, Jina, VoyageAI |

## Bonnes pratiques

1. **Jobs pour les appels LLM** — Pas en sync dans les controllers
2. **Vector store** pour le RAG (pgvector, Pinecone)
3. **Streaming** pour les réponses longues
4. **Fallback** sur modèles locaux (Ollama)
5. **Cache** des embeddings coûteux
6. **Rate limiting** sur les appels AI
7. **Monitoring** des coûts API
8. **Tests** avec des fixtures
9. **Sécurité** — Ne jamais envoyer de données sensibles
10. **Documentation** des prompts et tools

## Validation

- [ ] Laravel AI SDK installé
- [ ] Providers configurés
- [ ] Agents avec instructions et tools
- [ ] Streaming configuré
- [ ] Embeddings et RAG fonctionnels
- [ ] Jobs pour les appels longs
- [ ] Tests avec fixtures
