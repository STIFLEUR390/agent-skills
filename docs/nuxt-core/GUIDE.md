# Guide d'utilisation — nuxt-core

Fondamentaux Nuxt.js v4.

---

## Quand l'utiliser

- Créer des pages Nuxt
- Configurer le routing
- Implémenter le data fetching
- Créer des composables

---

## Exemple 1 — Page avec data fetching

**Demander**：
```
Crée une page /posts qui liste les posts depuis l'API Laravel.
```

**Le skill génère**：

```vue
<script setup lang="ts">
definePageMeta({ title: 'Posts' })

const { data: posts, pending, error } = await useFetch('/api/posts')
</script>

<template>
  <div>
    <h1>Posts</h1>
    <div v-if="pending">Chargement...</div>
    <div v-else-if="error">Erreur</div>
    <ul v-else>
      <li v-for="post in posts.data" :key="post.id">
        <NuxtLink :to="`/posts/${post.id}`">{{ post.title }}</NuxtLink>
      </li>
    </ul>
  </div>
</template>
```

---

## Exemple 2 — Composable réutilisable

**Demander**：
```
Crée un composable usePosts pour gérer les posts.
```

**Le skill génère**：

```typescript
export const usePosts = () => {
  const { data, refresh, pending } = await useFetch('/api/posts')

  const create = async (form: CreatePostInput) => {
    await $fetch('/api/posts', { method: 'POST', body: form })
    refresh()
  }

  return { posts: data, refresh, pending, create }
}
```

---

## Voir aussi

- `laravel-nuxt` — API Laravel pour Nuxt
- `nuxt-ui` — Composants UI
