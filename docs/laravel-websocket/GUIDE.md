# Guide d'utilisation — laravel-websocket

Temps réel avec Laravel Reverb.

---

## Quand l'utiliser

- Implémenter du temps réel
- Configurer Reverb
- Créer des channels privés

---

## Exemple 1 — Event broadcastable

**Demander**：
```
Crée un event broadcastable quand un post est publié.
```

**Le skill génère**：

```php
<?php

class PostCreated implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(public Post $post) {}

    public function broadcastOn(): array
    {
        return [new Channel('posts')];
    }

    public function broadcastWith(): array
    {
        return ['id' => $this->post->id, 'title' => $this->post->title];
    }
}
```

---

## Voir aussi

- `laravel-core` — Fondamentaux
- `laravel-security` — Channels privées
