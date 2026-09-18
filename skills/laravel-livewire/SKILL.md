---
name: laravel-livewire
description: >
  Composants Livewire 3 et Volt pour Laravel. Formulaires, streaming, events,
  polling, modals. Utiliser quand on travaille sur un projet Livewire, on crée
  des composants, ou on debug du code Livewire.
license: MIT
compatibility: "Claude Code, Codex, OpenCode, Pi, omp"
allowed-tools: Read Write Glob Grep Bash
user-invocable: true
---

# Laravel Livewire — Livewire 3 + Volt dans Laravel 13

Tu es un expert Livewire 3 avec Laravel. Ton rôle est de guider le développement
d'interfaces dynamiques avec Livewire et Volt.

## Quand utiliser

- Créer des composants Livewire
- Utiliser Volt pour les composants simples
- Implémenter du temps réel (polling, events)
- Créer des modals, toasts, formulaires

## Composant classique

```php
<?php

namespace App\Livewire;

use App\Models\Post;
use Livewire\Attributes\Validate;
use Livewire\Component;

class PostForm extends Component
{
    #[Validate('required|string|max:255')]
    public string $title = '';

    #[Validate('required|string')]
    public string $content = '';

    public function save(): void
    {
        $this->validate();

        Post::create([
            'title' => $this->title,
            'content' => $this->content,
            'user_id' => auth()->id(),
        ]);

        $this->reset(['title', 'content']);

        $this->dispatch('post-created');
        session()->flash('success', 'Post créé !');
    }

    public function render()
    {
        return view('livewire.post-form');
    }
}
```

## Template Blade

```blade
{{-- resources/views/livewire/post-form.blade.php --}}
<div>
    <form wire:submit="save">
        <div>
            <label for="title">Titre</label>
            <input
                type="text"
                id="title"
                wire:model="title"
                class="@error('title') border-red-500 @enderror"
            />
            @error('title')
                <span class="text-red-500">{{ $message }}</span>
            @enderror
        </div>

        <div>
            <label for="content">Contenu</label>
            <textarea
                id="content"
                wire:model="content"
                rows="5"
            ></textarea>
            @error('content')
                <span class="text-red-500">{{ $message }}</span>
            @enderror
        </div>

        <button type="submit" wire:loading.attr="disabled">
            <span wire:loading.remove>Enregistrer</span>
            <span wire:loading>Sauvegarde...</span>
        </button>
    </form>
</div>
```

## Volt (composant single-file)

```php
<?php

use function Livewire\Volt\{state, mount, computed};
use App\Models\Post;

$posts = Post::with('user')->latest()->paginate(10);

$delete = function (Post $post) {
    $this->authorize('delete', $post);
    $post->delete();
    $this->dispatch('post-deleted');
};

?>

<div>
    <h1>Posts</h1>

    <div wire:key="post-{{ $post->id }}" x-data="{ show: true }">
        @foreach($posts as $post)
            <div x-show="show" x-transition>
                <h2>{{ $post->title }}</h2>
                <p>{{ $post->user->name }}</p>
                <button wire:click="delete({{ $post->id }})"
                        wire:confirm="Êtes-vous sûr ?">
                    Supprimer
                </button>
            </div>
        @endforeach
    </div>

    {{ $posts->links() }}
</div>
```

## Events

```php
// Émettre un event
$this->dispatch('post-created', postId: $post->id);

// Écouter côté Blade
<div wire:poll.5s> {{-- Polling toutes les 5s --}}
    {{ $this->posts->count() }} posts
</div>

// Écouter côté JS
<script>
    Livewire.on('post-created', (postId) => {
        console.log('Post créé:', postId);
    });
</script>
```

## Polling

```blade
{{-- Polling automatique --}}
<div wire:poll.10s="refreshPosts">
    @foreach($this->posts as $post)
        <div>{{ $post->title }}</div>
    @endforeach
</div>

{{-- Polling conditionnel --}}
<div wire:poll.5s="checkNotifications" wire:poll.visible>
    {{-- Poll seulement si visible --}}
</div>
```

## Loading States

```blade
<button wire:click="save" wire:loading.attr="disabled">
    <span wire:loading.remove wire:target="save">Enregistrer</span>
    <span wire:loading wire:target="save">Chargement...</span>
</button>

<div wire:loading>
    <div class="spinner"></div>
</div>
```

## Modals

```php
<?php

use Livewire\Attributes\On;

class PostModal extends Component
{
    public bool $show = false;
    public ?Post $post = null;

    #[On('edit-post')]
    public function editPost(Post $post): void
    {
        $this->post = $post;
        $this->show = true;
    }

    public function save(): void
    {
        $this->validate();
        $this->post->save();
        $this->show = false;
        $this->dispatch('post-updated');
    }
}
```

## Bonnes pratiques

1. **Volt pour les composants simples** — Réduit le boilerplate
2. **`wire:model.live`** pour la réactivité temps réel
3. **Validation via `#[Validate]`** attributes
4. **Events `$dispatch`** pour la communication inter-composants
5. **Loading states** pour le feedback utilisateur
6. **`wire:key`** pour les listes dynamiques
7. **`wire:confirm`** pour les actions destructrices
8. **Eager loading** dans les composants (pas de N+1)
9. **Transactions DB** pour les opérations multiples
10. **Tests** avec `Livewire::test()`

## Validation

- [ ] Composants dans `app/Livewire/`
- [ ] Volt utilisé pour les composants simples
- [ ] Validation via `#[Validate]`
- [ ] Loading states configurés
- [ ] Events pour la communication
- [ ] Tests avec `Livewire::test()`
