# Guide d'utilisation — laravel-microservice

Microservices avec Laravel.

---

## Quand l'utiliser

- Décomposer une app en microservices
- Communication inter-services
- Event sourcing

---

## Exemple 1 — Circuit Breaker

**Demander**：
```
Ajoute un circuit breaker pour l'appel au service de paiement.
```

**Le skill génère**：

```php
<?php

class CircuitBreaker
{
    public static function call(string $service, callable $fallback, callable $action): mixed
    {
        $failures = Cache::get("circuit.{$service}.failures", 0);
        if ($failures >= 5) return $fallback();

        try {
            $result = $action();
            Cache::put("circuit.{$service}.failures", 0);
            return $result;
        } catch (\Exception $e) {
            Cache::increment("circuit.{$service}.failures");
            return $fallback();
        }
    }
}
```

---

## Voir aussi

- `laravel-core` — Fondamentaux
- `laravel-queue` — Communication async
- `laravel-api` — APIs entre services
