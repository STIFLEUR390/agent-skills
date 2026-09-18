---
name: laravel-microservice
description: >
  Architecture microservices avec Laravel. Communication inter-services,
  event-driven, saga pattern, circuit breaker. Utiliser quand on décompose
  une app en microservices, on communique entre services, ou on implémente
  de l'event sourcing.
license: MIT
compatibility: "Claude Code, Codex, OpenCode, Pi, omp"
allowed-tools: Read Write Glob Grep Bash
user-invocable: true
---

# Laravel Microservice — Microservices avec Laravel 13

Tu es un expert en architecture microservices avec Laravel. Ton rôle est de
guider la décomposition et la communication entre services.

## Quand utiliser

- Décomposer une app en microservices
- Communciation inter-services
- Event sourcing
- Circuit breaker
- Transactions distribuées

## Structure

```
project/
├── app/
│   ├── Services/
│   │   ├── OrderService/
│   │   │   ├── Http/
│   │   │   ├── Models/
│   │   │   ├── Events/
│   │   │   ├── Jobs/
│   │   │   └── config/
│   │   └── PaymentService/
│   │       ├── Http/
│   │       ├── Models/
│   │       └── ...
│   └── Shared/
│       ├── Events/
│       ├── DTOs/
│       └── Contracts/
├── services/
│   ├── order-service/
│   ├── payment-service/
│   └── notification-service/
└── docker-compose.yml
```

## Communication synchrone (HTTP)

```php
<?php

namespace App\Services\Order;

use Illuminate\Support\Facades\Http;

class PaymentClient
{
    public function __construct(
        protected string $baseUrl,
    ) {}

    public function createPayment(array $data): array
    {
        $response = Http::withHeaders([
            'X-Service-Key' => config('services.payment.key'),
        ])->timeout(10)->post("{$this->baseUrl}/api/payments", $data);

        if ($response->failed()) {
            throw new PaymentFailedException($response->json('message'));
        }

        return $response->json('data');
    }
}
```

## Communication asynchrone (Events)

```php
<?php

namespace App\Services\Order\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class OrderCreated implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public int $orderId,
        public float $amount,
        public string $currency,
        public array $items,
    ) {}

    public function broadcastOn(): array
    {
        return [new Channel('orders')];
    }

    public function broadcastWith(): array
    {
        return [
            'order_id' => $this->orderId,
            'amount' => $this->amount,
            'currency' => $this->currency,
        ];
    }
}
```

## Listeners inter-services

```php
<?php

namespace App\Services\Payment\Listeners;

use App\Services\Order\Events\OrderCreated;
use App\Services\Payment\Jobs\ProcessPayment;

class CreatePaymentForOrder
{
    public function handle(OrderCreated $event): void
    {
        ProcessPayment::dispatch(
            orderId: $event->orderId,
            amount: $event->amount,
            currency: $event->currency,
        );
    }
}
```

## Circuit Breaker

```php
<?php

namespace App\Services\Shared;

use Illuminate\Support\Facades\Cache;

class CircuitBreaker
{
    public static function call(
        string $service,
        callable $fallback,
        callable $action,
        int $threshold = 5,
        int $timeout = 60,
    ): mixed {
        $failures = Cache::get("circuit.{$service}.failures", 0);

        if ($failures >= $threshold) {
            $lastFailure = Cache::get("circuit.{$service}.last_failure");
            if ($lastFailure && now()->diffInSeconds($lastFailure) < $timeout) {
                return $fallback();
            }
            Cache::put("circuit.{$service}.failures", 0);
        }

        try {
            $result = $action();
            Cache::put("circuit.{$service}.failures", 0);
            return $result;
        } catch (\Exception $e) {
            Cache::increment("circuit.{$service}.failures");
            Cache::put("circuit.{$service}.last_failure", now());
            return $fallback();
        }
    }
}

// Utilisation
$payment = CircuitBreaker::call(
    service: 'payment',
    fallback: fn () => ['status' => 'pending'],
    action: fn () => $this->paymentClient->createPayment($data),
);
```

## DTOs (Data Transfer Objects)

```php
<?php

namespace App\Services\Shared\DTOs;

readonly class OrderDTO
{
    public function __construct(
        public int $id,
        public int $userId,
        public float $total,
        public string $status,
        public array $items,
        public \DateTimeImmutable $createdAt,
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            id: $data['id'],
            userId: $data['user_id'],
            total: $data['total'],
            status: $data['status'],
            items: $data['items'],
            createdAt: new \DateTimeImmutable($data['created_at']),
        );
    }
}
```

## Sagas (Transactions distribuées)

```php
<?php

namespace App\Services\Order\Sagas;

use App\Services\Order\States\{Created, Paid, Shipped, Completed, Failed};

class OrderSaga
{
    public function __construct(
        protected int $orderId,
    ) {}

    public function handle(): void
    {
        try {
            $state = new Created($this->orderId);
            $state = $state->create();     // Créer la commande
            $state = $state->pay();        // Payer
            $state = $state->ship();       // Expédier
            $state->complete();            // Finaliser
        } catch (\Exception $e) {
            $this->compensate($state);
            throw $e;
        }
    }

    protected function compensate($state): void
    {
        // Annuler dans l'ordre inverse
        if ($state instanceof Shipped) {
            $state->cancelShipping();
        }
        if ($state instanceof Paid) {
            $state->refund();
        }
        if ($state instanceof Created) {
            $state->cancel();
        }
    }
}
```

## Bonnes pratiques

1. **Chaque service a sa propre DB** — Isolation des données
2. **Communication synchrone** = HTTP/gRPC, asynchrone = queues
3. **Event sourcing** pour l'audit trail
4. **Circuit breaker** pour la résilience
5. **DTOs** pour les données inter-services
6. **Sagas** pour les transactions distribuées
7. **API versioning** — Chaque service versionne son API
8. **Monitoring** — Logs structurés, métriques
9. **Tests d'intégration** — Tester les communication
10. **Documentation** — Contrats d'API entre services

## Validation

- [ ] Chaque service a sa propre DB
- [ ] Communication asynchrone via events
- [ ] Circuit breaker configuré
- [ ] DTOs pour les données inter-services
- [ ] Sagas pour les transactions complexes
- [ ] Monitoring et logs
- [ ] Tests d'intégration
