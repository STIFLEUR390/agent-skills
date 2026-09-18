# Guide d'utilisation — laravel-inertia

Inertia.js + Vue 3 / React dans Laravel 13.

---

## Quand l'utiliser

- Créer des pages Inertia
- Configurer les layouts
- Gérer les navigations partielles

---

## Exemple 1 — Page liste

**Demander** :
```
Crée une page Index pour lister les posts avec pagination.
```

**Le skill génère** :

Controller :
```php
public function index(): Response
{
    return Inertia::render('Posts/Index', [
        'posts' => Post::paginate(20),
    ]);
}
```

Page Vue :
```vue
<script setup>
import { Link } from '@inertiajs/vue3';
defineProps(['posts']);
</script>

<template>
  <div v-for="post in posts.data" :key="post.id">
    <Link :href="route('posts.show', post.id)">{{ post.title }}</Link>
  </div>
  <Link v-for="link in posts.links" :href="link.url" v-html="link.label" />
</template>
```

---

## Exemple 2 — Partial reload

**Demander** :
```
Recharge seulement les comments quand on ajoute un commentaire.
```

**Le skill génère** :

```vue
<script setup>
import { router } from '@inertiajs/vue3';

const addComment = () => {
  router.post(route('comments.store'), form, {
    only: ['comments'], // Recharge seulement les comments
  });
};
</script>
```

---

## Voir aussi

- `laravel-core` — Fondamentaux
- `laravel-testing` — Tests Inertia
