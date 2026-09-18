---
name: laravel-websocket
description: >
  Temps réel avec Laravel Reverb et Broadcasting. Channels, events, presence,
  notifications push. Utiliser quand on implémente du temps réel, on configure
  Reverb, on crée des channels, ou on broadcast des events.
license: MIT
compatibility: "Claude Code, Codex, OpenCode, Pi, omp"
allowed-tools: Read Write Glob Grep Bash
user-invocable: true
---

# Laravel WebSocket — Temps réel avec Reverb

Tu es un expert en temps réel avec Laravel Reverb. Ton rôle est d'implémenter
des communications WebSocket robustes.

## Quand utiliser

- Implémenter du temps réel
- Configurer Laravel Reverb
- Créer des channels privés
- Broadcast des events
- Notifications push

## Installation

```bash
php artisan install:broadcasting
```

## Broadcast Event

```php
<?php

namespace App\Events;

use App\Models\Post;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class PostCreated implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public Post $post,
    ) {}

    public function broadcastOn(): array
    {
        return [
            new PrivateChannel('user.' . $this->post->user_id),
            new Channel('posts'),
        ];
    }

    public function broadcastAs(): string
    {
        return 'post.created';
    }

    public function broadcastWith(): array
    {
        return [
            'id' => $this->post->id,
            'title' => $this->post->title,
            'user' => [
                'id' => $this->post->user->id,
                'name' => $this->post->user->name,
            ],
            'created_at' => $this->post->created_at->toISOString(),
        ];
    }
}
```

## Channels

```php
// routes/channels.php
use Illuminate\Support\Facades\Broadcast;

Broadcast::channel('user.{id}', function ($user, $id) {
    return (int) $user->id === (int) $id;
});

Broadcast::channel('post.{post}', function ($user, Post $post) {
    return $user->id === $post->user_id || $post->is_published;
});

// Presence channel
Broadcast::channel('room.{room}', function ($user, Room $room) {
    if ($user->can('join', $room)) {
        return [
            'id' => $user->id,
            'name' => $user->name,
            'avatar' => $user->avatar,
        ];
    }
});
```

## Côté JavaScript (Vue/React)

```javascript
// Vue 3
import { Echo } from '@/echo';
import { ref, onMounted, onUnmounted } from 'vue';

const posts = ref([]);

onMounted(() => {
    Echo.private(`user.${userId}`)
        .listen('.post.created', (e) => {
            posts.value.unshift(e);
        });

    Echo.join('room.1')
        .here((users) => {
            console.log('Users in room:', users);
        })
        .joining((user) => {
            console.log('User joined:', user);
        })
        .leaving((user) => {
            console.log('User left:', user);
        });
});

onUnmounted(() => {
    Echo.leave('room.1');
});
```

## Model Broadcasting

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Broadcasts;

class Post extends Model
{
    use Broadcasts;

    protected $broadcastUpdateRelations = ['user'];

    public function broadcastOn($event): array
    {
        return match ($event) {
            'created' => [new Channel('posts')],
            'updated' => [new PrivateChannel('user.' . $this->user_id)],
            'deleted' => [new PrivateChannel('user.' . $this->user_id)],
            default => [],
        };
    }
}
```

## Notifications Push

```php
<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;
use Illuminate\Notifications\Messages\BroadcastMessage;

class NewComment extends Notification
{
    use Queueable;

    public function via(object $notifiable): array
    {
        return ['broadcast', 'database'];
    }

    public function broadcastOn(object $notifiable): array
    {
        return [
            new PrivateChannel('user.' . $notifiable->id),
        ];
    }

    public function toArray(object $notifiable): array
    {
        return [
            'message' => 'Nouveau commentaire sur votre post',
            'post_id' => $this->comment->post_id,
        ];
    }
}
```

## Configuration Reverb

```ini
# .env
BROADCAST_CONNECTION=reverb
REVERB_APP_ID=app-id
REVERB_APP_KEY=app-key
REVERB_APP_SECRET=app-secret
REVERB_HOST="localhost:8080"
REVERB_PORT=8080
REVERB_SCHEME=http
```

## Bonnes pratiques

1. **Reverb** comme driver par défaut (Laravel 12+)
2. **Channels privées** pour les données sensibles
3. **Presence channels** pour le tracking utilisateur
4. **Rate limiting** sur les channels
5. **Modèles broadcastables** avec `Broadcasts` trait
6. **Events typés** avec `broadcastAs()`
7. **Cleanup** — `Echo.leave()` en unmount
8. **Tests** — `Broadcast::fake()`
9. **Fallback** — Notification DB en plus du broadcast
10. **Monitoring** — Logs des connections

## Validation

- [ ] Reverb configuré
- [ ] Channels définis
- [ ] Events broadcastables
- [ ] Côté JS configuré
- [ ] Presence channels si nécessaire
- [ ] Tests avec Broadcast::fake()
