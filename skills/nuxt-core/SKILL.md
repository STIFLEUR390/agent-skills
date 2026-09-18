---
name: nuxt-core
description: >
  Point d'entrée pour tout projet Nuxt.js (v4). Pages, layouts, composables,
  middleware, plugins, server routes, data fetching, SSR/CSR/SSG. Utiliser
  quand on travaille sur un projet Nuxt, on crée des pages, on configure le
  routing, ou on debug du code Nuxt. Toujours charger en premier pour les
  projets Nuxt.
license: MIT
compatibility: "Claude Code, Codex, OpenCode, Pi, omp"
allowed-tools: Read Write Glob Grep Bash
user-invocable: true
---

# Nuxt Core — Fondamentaux Nuxt.js v4

Tu es un expert Nuxt.js v4. Ton rôle est de guider le développement
d'applications full-stack avec Nuxt.

## Quand utiliser

- On travaille sur un projet Nuxt
- On crée des pages, layouts, composables
- On configure le routing ou le data fetching
- On debug du code Nuxt

## Quand NE PAS utiliser

- Projet Vue sans Nuxt
- Backend pur sans frontend
- Application React/Next.js

## Structure du projet

```
├── app/
│   ├── components/       — Composants auto-importés
│   ├── composables/      — Composables auto-importés
│   ├── layouts/          — Layouts
│   ├── middleware/        — Route middleware
│   ├── pages/            — Pages (file-based routing)
│   ├── plugins/          — Plugins
│   ├── error.vue         — Page d'erreur globale
│   └── app.vue           — Root component
├── server/
│   ├── api/              — Server API routes
│   ├── middleware/        — Server middleware
│   ├── routes/           — Custom server routes
│   ├── plugins/          — Server plugins
│   └── utils/            — Server utils
├── public/               — Assets statiques
├── nuxt.config.ts        — Configuration
├── app.config.ts         — App config
└── package.json
```

## Routing (file-based)

```
pages/
├── index.vue             → /
├── about.vue             → /about
├── posts/
│   ├── index.vue         → /posts
│   ├── [id].vue          → /posts/:id
│   └── [slug].vue        → /posts/:slug
├── auth/
│   ├── login.vue         → /auth/login
│   └── register.vue      → /auth/register
└── [...slug].vue         → /catch-all (404)
```

## Page avec definePageMeta

```vue
<script setup lang="ts">
definePageMeta({
  title: 'Posts',
  middleware: ['auth'],
  layout: 'default',
})

const { data: posts, pending, error } = await useFetch('/api/posts')
</script>

<template>
  <div>
    <h1>Posts</h1>
    <div v-if="pending">Chargement...</div>
    <div v-else-if="error">Erreur: {{ error.message }}</div>
    <ul v-else>
      <li v-for="post in posts.data" :key="post.id">
        <NuxtLink :to="`/posts/${post.id}`">{{ post.title }}</NuxtLink>
      </li>
    </ul>
  </div>
</template>
```

## Data Fetching

```vue
<script setup lang="ts">
// useFetch — SSR-friendly, cached, auto-dedupe
const { data: posts } = await useFetch('/api/posts')

// useAsyncData — plus de contrôle
const { data: post } = await useAsyncData(
  `post-${route.params.id}`,
  () => $fetch(`/api/posts/${route.params.id}`)
)

// $fetch — client-side only (dans event handler)
const submit = async () => {
  const data = await $fetch('/api/posts', {
    method: 'POST',
    body: form,
  })
}
</script>
```

## Composable personnalisé

```typescript
// composables/usePosts.ts
export const usePosts = () => {
  const { data: posts, refresh, pending } = useFetch('/api/posts')

  const createPost = async (data: CreatePostInput) => {
    const newPost = await $fetch('/api/posts', {
      method: 'POST',
      body: data,
    })
    refresh()
    return newPost
  }

  return { posts, refresh, pending, createPost }
}
```

## Server API routes

```typescript
// server/api/posts/index.get.ts
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

export default defineEventHandler(async (event) => {
  const query = getQuery(event)

  const posts = await prisma.post.findMany({
    where: {
      is_published: true,
    },
    include: { user: { select: { id: true, name: true } } },
    take: Number(query.per_page) || 15,
    skip: ((Number(query.page) || 1) - 1) * (Number(query.per_page) || 15),
    orderBy: { created_at: 'desc' },
  })

  return { data: posts }
})
```

## Server API route POST

```typescript
// server/api/posts/index.post.ts
export default defineEventHandler(async (event) => {
  const body = await readBody(event)
  const auth = await requireUserSession(event) // Auth check

  const post = await prisma.post.create({
    data: {
      ...body,
      user_id: auth.user.id,
    },
  })

  return { data: post }
})
```

## Middleware

```typescript
// middleware/auth.ts
export default defineNuxtRouteMiddleware((to, from) => {
  const { loggedIn } = useAuth()

  if (!loggedIn.value) {
    return navigateTo('/auth/login')
  }
})
```

## Layouts

```vue
<!-- layouts/default.vue -->
<template>
  <div class="layout">
    <header>
      <nav>
        <NuxtLink to="/">Home</NuxtLink>
        <NuxtLink to="/posts">Posts</NuxtLink>
      </nav>
    </header>
    <main>
      <slot />
    </main>
    <footer>© 2026</footer>
  </div>
</template>
```

## Plugins

```typescript
// plugins/api.ts
export default defineNuxtPlugin(() => {
  const config = useRuntimeConfig()

  return {
    provide: {
      api: $fetch.create({
        baseURL: config.public.apiBase,
        headers: {
          Authorization: `Bearer ${useCookie('token').value}`,
        },
      }),
    },
  }
})
```

## Error handling

```vue
<!-- app/error.vue -->
<script setup lang="ts">
defineProps<{
  error: { statusCode: number; message: string }
}>()

const handleError = () => clearError({ redirect: '/' })
</script>

<template>
  <div>
    <h1>{{ error.statusCode }}</h1>
    <p>{{ error.message }}</p>
    <button @click="handleError">Retour</button>
  </div>
</template>
```

## Bonnes pratiques

1. **`useFetch`** pour le data fetching SSR-friendly
2. **`definePageMeta`** pour les métadonnées de page
3. **Auto-imports** — Pas besoin d'importer composables/composants
4. **File-based routing** — Les fichiers dans `pages/` = routes
5. **Server routes** — API côté serveur dans `server/api/`
6. **TypeScript** — Toujours typer les données
7. **Error handling** — `useError()` + `clearError()`
8. **Middleware** — Pour l'auth, la redirection, le tracking
9. **Composables** — Extraire la logique réutilisable
10. **SSR-friendly** — Éviter `window`/`document` dans setup

## Validation

- [ ] Pages dans `app/pages/`
- [ ] Composables dans `app/composables/`
- [ ] Server routes dans `server/api/`
- [ ] `definePageMeta` sur toutes les pages
- [ ] TypeScript partout
- [ ] Error handling configuré
