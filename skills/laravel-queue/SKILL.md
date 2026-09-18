---
name: laravel-queue
description: >
  Traitement asynchrone avec les queues Laravel. Jobs, batches, chains,
  Horizon, workers. Utiliser quand on crée des jobs, on configure les queues,
  on debug un job, ou on optimise les workers.
license: MIT
compatibility: "Claude Code, Codex, OpenCode, Pi, omp"
allowed-tools: Read Write Glob Grep Bash
user-invocable: true
---

# Laravel Queue — Jobs & Queues dans Laravel 13

Tu es un expert en queues Laravel. Ton rôle est de guider le traitement
asynchrone avec des jobs robustes et performants.

## Quand utiliser

- Créer des jobs pour tâches longues
- Configurer les queues et workers
- Implémenter des batches ou chains
- Configurer Horizon
- Debuguer des jobs échoués

## Job simple

```php
<?php

namespace App\Jobs;

use App\Models\Post;
use App\Notifications\PostPublished;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Notification;

class SendPostPublishedNotification implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $timeout = 60;
    public int $tries = 3;
    public int $backoff = 60;
    public string $queue = 'notifications';

    public function __construct(
        public Post $post,
    ) {}

    public function handle(): void
    {
        $this->post->load('user');

        Notification::send(
            $this->post->user,
            new PostPublished($this->post)
        );
    }

    public function failed(\Throwable $exception): void
    {
        logger()->error('Failed to send notification', [
            'post_id' => $this->post->id,
            'error' => $exception->getMessage(),
        ]);
    }
}
```

## Job avec middleware

```php
<?php

namespace App\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\Middleware\RateLimited;
use Illuminate\Queue\Middleware\WithoutOverlapping;
use Illuminate\Queue\SerializesModels;

class ProcessImport implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function middleware(): array
    {
        return [
            new RateLimited('imports'),
            new WithoutOverlapping('import:' . $this->importId),
        ];
    }

    public function __construct(
        public int $importId,
    ) {}

    public function handle(): void
    {
        // Traitement...
    }
}
```

## Batches

```php
<?php

use App\Jobs\ProcessRecord;
use Illuminate\Bus\Batch;
use Illuminate\Support\Facades\Bus;

$batch = Bus::batch([
    new ProcessRecord(1),
    new ProcessRecord(2),
    new ProcessRecord(3),
])->then(function (Batch $batch) {
    // Tout est terminé
    logger()->info('Batch terminé');
})->catch(function (Batch $batch, \Throwable $e) {
    // Un job a échoué
    logger()->error('Batch échoué', ['error' => $e->getMessage()]);
})->finally(function (Batch $batch) {
    // Toujours exécuté
})->name('process-records')
 ->onConnection('redis')
 ->onQueue('imports')
 ->dispatch();
```

## Chains

```php
<?php

use App\Jobs\{FetchData, ProcessData, StoreData};

Bus::chain([
    new FetchData($url),
    new ProcessData(),
    new StoreData(),
])->onConnection('redis')
  ->onQueue('pipeline')
  ->dispatch();
```

## Dispatch

```php
<?php

// Simple
ProcessPodcast::dispatch($podcast);

// Sur une queue spécifique
ProcessPodcast::dispatch($podcast)->onQueue('podcasts');

// Avec délai
ProcessPodcast::dispatch($podcast)->delay(now()->addMinutes(5));

// Unique job
ProcessPodcast::dispatch($podcast)->unique();
// ou
ProcessPodcast::dispatchIf($shouldProcess, $podcast);

// Après une DB transaction
Bus::afterCommit(function () {
    ProcessPodcast::dispatch($podcast);
});
```

## Job routing (Laravel 13)

```php
<?php

use Illuminate\Support\Facades\Queue;

Queue::route(ProcessPodcast::class, connection: 'redis', queue: 'podcasts');
Queue::route(SendNotification::class, connection: 'redis', queue: 'notifications');
```

## PHP Attributes (Laravel 13)

```php
<?php

use Illuminate\Queue\Attributes\Backoff;
use Illuminate\Queue\Attributes\FailOnTimeout;
use Illuminate\Queue\Attributes\Timeout;
use Illuminate\Queue\Attributes\Tries;

#[Tries(3)]
#[Timeout(120)]
#[Backoff(60)]
#[FailOnTimeout]
class ProcessPodcast implements ShouldQueue
{
    // ...
}
```

## Horizon

```php
// config/horizon.php
return [
    'environments' => [
        'production' => [
            'supervisor-1' => [
                'connection' => 'redis',
                'queue' => ['default', 'notifications', 'imports'],
                'balance' => 'auto',
                'autoScalingStrategy' => 'time',
                'maxProcesses' => 10,
                'maxTime' => 3600,
                'maxJobs' => 1000,
                'memory' => 128,
                'tries' => 3,
                'timeout' => 60,
                'nice' => 0,
            ],
        ],
    ],
];
```

## Testing

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

it('does not dispatch if already processed', function () {
    Queue::fake();

    ProcessPodcast::dispatchIf(false, $podcast);

    Queue::assertNothingPushed();
});
```

## Bonnes pratiques

1. **Jobs idempotents** — Retry-safe
2. **Timeout et tries** — Sur tous les jobs
3. **Batches** pour les opérations en masse
4. **Chains** pour les workflows séquentiels
5. **Middleware** — Rate limiting, WithoutOverlapping
6. **Logging** — Pour le debugging
7. **Failed jobs** — Handler `failed()`
8. **Queue routing** — Centraliser la config (Laravel 13)
9. **Horizon** — Monitoring en production
10. **Tests** — `Queue::fake()` partout

## Validation

- [ ] Jobs avec timeout et tries
- [ ] Middleware configuré
- [ ] Batches/Chains utilisés quand pertinent
- [ ] Failed jobs gérés
- [ ] Horizon configuré en production
- [ ] Tests avec Queue::fake()
