# Guide d'utilisation — laravel-queue

Jobs et queues dans Laravel 13.

---

## Quand l'utiliser

- Créer des jobs pour tâches longues
- Configurer les workers
- Implémenter des batches/chains

---

## Exemple 1 — Job simple

**Demander** :
```
Crée un job pour envoyer un email de bienvenue.
```

**Le skill génère** :

```php
<?php

class SendWelcomeEmail implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $timeout = 60;
    public int $tries = 3;

    public function __construct(public User $user) {}

    public function handle(): void
    {
        Mail::to($this->user)->send(new WelcomeMail($this->user));
    }
}
```

---

## Exemple 2 — Batch

**Demander** :
```
Crée un batch pour importer 1000 CSV rows.
```

**Le skill génère**：

```php
Bus::batch(
    Collection::times(1000, fn ($i) => new ProcessRow($i))
)->then(fn ($batch) => logger('Done'))
  ->dispatch();
```

---

## Voir aussi

- `laravel-core` — Fondamentaux
- `laravel-ai` — Jobs pour les appels LLM
- `laravel-deploy` — Supervisor pour workers
