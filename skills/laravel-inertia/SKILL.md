---
name: laravel-inertia
description: >
  Développement Laravel avec Inertia.js et Vue 3 ou React. Pages, composants,
  loadings, prefetching, SSR. Utiliser quand on travaille sur un projet
  Laravel + Inertia, on crée des pages, ou on debug du code frontend.
license: MIT
compatibility: "Claude Code, Codex, OpenCode, Pi, omp"
allowed-tools: Read Write Glob Grep Bash
user-invocable: true
---

# Laravel Inertia — Inertia.js + Vue/React dans Laravel 13

Tu es un expert Inertia.js avec Laravel. Ton rôle est de guider le développement
d'applications full-stack avec Inertia.

## Quand utiliser

- Créer des pages Inertia
- Configurer les layouts partagés
- Gérer les navigations partielles
- Implémenter le SSR
- Debuguer le code frontend

## Structure

```
resources/js/
├── Pages/              — Pages Inertia
│   ├── Posts/
│   │   ├── Index.vue   — Liste des posts
│   │   ├── Show.vue    — Détail d'un post
│   │   └── Create.vue  — Formulaire de création
│   └── Layouts/
│       └── App.vue     — Layout principal
├── Components/         — Composants réutilisables
├── composables/        — Composables Vue 3
└── app.ts              — Point d'entrée
```

## Controller Inertia

```php
<?php

namespace App\Http\Controllers;

use App\Models\Post;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class PostController extends Controller
{
    public function index(): Response
    {
        return Inertia::render('Posts/Index', [
            'posts' => Post::with('user')->paginate(20),
        ]);
    }

    public function show(Post $post): Response
    {
        return Inertia::render('Posts/Show', [
            'post' => $post->load('user', 'comments.user'),
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'content' => 'required|string',
        ]);

        $post = Post::create([
            ...$validated,
            'user_id' => $request->user()->id,
        ]);

        return redirect()->route('posts.show', $post)
            ->with('success', 'Post créé avec succès.');
    }
}
```

## Page Vue 3

```vue
<script setup lang="ts">
import AppLayout from '@/Layouts/App.vue';
import { Link, router } from '@inertiajs/vue3';
import { ref } from 'vue';

interface Post {
    id: number;
    title: string;
    content: string;
    user: { name: string };
    created_at: string;
}

const props = defineProps<{
    posts: {
        data: Post[];
        meta: { current_page: number; last_page: number; total: number };
    };
}>();

const search = ref('');

const filter = () => {
    router.get(route('posts.index'), { search: search.value }, {
        preserveState: true,
        replace: true,
    });
};
</script>

<template>
    <AppLayout title="Posts">
        <template #header>
            <h1>Posts</h1>
        </template>

        <!-- Recherche -->
        <input v-model="search" @input="filter" placeholder="Rechercher..." />

        <!-- Liste -->
        <div v-for="post in posts.data" :key="post.id">
            <Link :href="route('posts.show', post.id)">
                {{ post.title }}
            </Link>
            <span>{{ post.user.name }}</span>
        </div>

        <!-- Pagination -->
        <div>
            <Link
                v-for="link in posts.meta.links"
                :key="link.url"
                :href="link.url"
                :class="{ 'font-bold': link.active }"
                v-html="link.label"
            />
        </div>
    </AppLayout>
</template>
```

## Partial Reloads

```php
// Controller
public function show(Post $post): Response
{
    return Inertia::render('Posts/Show', [
        'post' => $post,
        'comments' => $post->comments, // Rechargé seulement si nécessaire
    ]);
}
```

```vue
<script setup>
import { router } from '@inertiajs/vue3';

// Recharger seulement les comments
router.reload({ only: ['comments'] });
</script>
```

## Prefetching

```vue
<script setup>
import { Link } from '@inertiajs/vue3';
</script>

<template>
    <!-- Prefetch au hover -->
    <Link :href="route('posts.show', post.id)" prefetch>
        {{ post.title }}
    </Link>

    <!-- Prefetch on intent (hover ou focus) -->
    <Link :href="route('posts.show', post.id)" prefetch="intent">
        {{ post.title }}
    </Link>
</template>
```

## Layouts partagés

```php
// app/Http/Middleware/HandleInertiaRequests.php
public function share(Request $request): array
{
    return [
        'user' => $request->user() ? [
            'id' => $request->user()->id,
            'name' => $request->user()->name,
            'email' => $request->user()->email,
        ] : null,
        'flash' => [
            'success' => fn () => $request->session()->get('success'),
            'error' => fn () => $request->session()->get('error'),
        ],
    ];
}
```

## SSR (Server-Side Rendering)

```bash
# Installer le SSR
php artisan inertia:middleware
```

```php
// config/inertia.php
return [
    'ssr' => [
        'enabled' => true,
        'url' => 'http://127.0.0.1:13714',
    ],
];
```

## Bonnes pratiques

1. **`Inertia::render()`** côté controller, pas de retour JSON
2. **Partial reloads** pour les navigations partielles
3. **Layouts partagés** via `HandleInertiaRequests`
4. **Props typées** côté frontend (TypeScript)
5. **Prefetching** pour les navigations prévisibles
6. **Progress bar** — `router.on('start', () => NProgress.start())`
7. **Preserve scroll** — `preserveScroll: true` quand nécessaire
8. **Error handling** — `router.onError()` pour les erreurs globales

## Validation

- [ ] Toutes les pages utilisent `Inertia::render()`
- [ ] Layouts partagés configurés
- [ ] Partial reloads utilisés quand pertinent
- [ ] Props typées en TypeScript
- [ ] SSR configuré si nécessaire
