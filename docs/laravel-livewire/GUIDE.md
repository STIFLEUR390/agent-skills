# Guide d'utilisation — laravel-livewire

Livewire 3 + Volt pour Laravel.

---

## Quand l'utiliser

- Créer des composants Livewire
- Utiliser Volt
- Implémenter du temps réel

---

## Exemple 1 — Composant avec Volt

**Demander** :
```
Crée un composant de formulaire d'ajout de post avec Volt.
```

**Le skill génère** :

```php
<?php

use Livewire\Attributes\Validate;
use App\Models\Post;

$validated = false;

$save = function () {
    $this->validate([
        'title' => 'required|string|max:255',
        'content' => 'required|string',
    ]);

    Post::create([
        'title' => $this->title,
        'content' => $this->content,
        'user_id' => auth()->id(),
    ]);

    session()->flash('success', 'Post créé !');
    $this->redirect(route('posts.index'));
};

?>

<div>
    <form wire:submit="save">
        <input wire:model="title" placeholder="Titre" />
        <textarea wire:model="content" placeholder="Contenu"></textarea>
        <button type="submit">Enregistrer</button>
    </form>
</div>
```

---

## Exemple 2 — Polling

**Demander** :
```
Actualise la liste des notifications toutes les 10 secondes.
```

**Le skill génère** :

```blade
<div wire:poll.10s="loadNotifications">
    @foreach($notifications as $notification)
        <div>{{ $notification->message }}</div>
    @endforeach
</div>
```

---

## Voir aussi

- `laravel-core` — Fondamentaux
- `laravel-testing` — Tests Livewire
