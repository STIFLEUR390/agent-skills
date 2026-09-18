---
name: nuxt-ui
description: >
  Composants UI et design system avec Nuxt UI. Tables, formulaires, modals,
  notifications, dark mode, responsive. Utiliser quand on crée des interfaces
  avec Nuxt UI, on configure le design system, ou on implémente des
  composants d'interface.
license: MIT
compatibility: "Claude Code, Codex, OpenCode, Pi, omp"
allowed-tools: Read Write Glob Grep Bash
user-invocable: true
---

# Nuxt UI — Composants et Design System

Tu es un expert Nuxt UI. Ton rôle est de guider la création d'interfaces
élégantes et accessibles avec Nuxt UI.

## Quand utiliser

- Créer des pages avec Nuxt UI
- Configurer le design system
- Implémenter des tables, formulaires, modals
- Ajouter le dark mode

## Installation

```bash
npx nuxi module add ui
# ou
npm install @nuxt/ui
```

## Configuration

```typescript
// nuxt.config.ts
export default defineNuxtConfig({
  modules: ['@nuxt/ui'],
  future: { compatibilityVersion: 4 },
})
```

## Table avec données API

```vue
<script setup lang="ts">
import type { TableColumn } from '@nuxt/ui'

const { data: posts, refresh } = await useFetch('/api/posts')

const columns: TableColumn[] = [
  { key: 'id', label: '#' },
  { key: 'title', label: 'Titre', sortable: true },
  { key: 'user.name', label: 'Auteur' },
  { key: 'is_published', label: 'Publié' },
  { key: 'created_at', label: 'Créé le', sortable: true },
  { key: 'actions', label: 'Actions' },
]

const selected = ref([])

const deletePost = async (id: number) => {
  await $fetch(`/api/posts/${id}`, { method: 'DELETE' })
  refresh()
}
</script>

<template>
  <UTable
    :columns="columns"
    :data="posts?.data"
    v-model="selected"
  >
    <template #is_published-data="{ row }">
      <UBadge
        :color="row.is_published ? 'success' : 'warning'"
        :label="row.is_published ? 'Publié' : 'Brouillon'"
      />
    </template>
    <template #actions-data="{ row }">
      <UButton
        icon="i-heroicons-pencil"
        size="xs"
        color="primary"
        variant="ghost"
        :to="`/posts/${row.id}/edit`"
      />
      <UButton
        icon="i-heroicons-trash"
        size="xs"
        color="error"
        variant="ghost"
        @click="deletePost(row.id)"
      />
    </template>
  </UTable>
</template>
```

## Formulaire

```vue
<script setup lang="ts">
const form = reactive({
  title: '',
  content: '',
  is_published: false,
})

const validate = (state: any) => {
  const errors = []
  if (!state.title) errors.push({ path: 'title', message: 'Titre requis' })
  if (!state.content) errors.push({ path: 'content', message: 'Contenu requis' })
  return errors
}

const submit = async () => {
  await $fetch('/api/posts', {
    method: 'POST',
    body: form,
  })
  navigateTo('/posts')
}
</script>

<template>
  <UForm :schema="validate" :state="form" @submit="submit">
    <UFormField label="Titre" name="title">
      <UInput v-model="form.title" placeholder="Titre du post" />
    </UFormField>

    <UFormField label="Contenu" name="content">
      <UTextarea v-model="form.content" :rows="10" />
    </UFormField>

    <UFormField label="Publié" name="is_published">
      <UToggle v-model="form.is_published" />
    </UFormField>

    <UButton type="submit" label="Enregistrer" />
  </UForm>
</template>
```

## Modal de confirmation

```vue
<script setup lang="ts">
const modal = useModal()

const confirmDelete = (id: number) => {
  modal.open({
    title: 'Supprimer le post',
    description: 'Êtes-vous sûr de vouloir supprimer ce post ?',
    confirmLabel: 'Supprimer',
    confirmColor: 'error',
    cancelLabel: 'Annuler',
    onConfirm: async () => {
      await $fetch(`/api/posts/${id}`, { method: 'DELETE' })
      refresh()
    },
  })
}
</script>
```

## Notifications

```vue
<script setup lang="ts">
const toast = useToast()

const submit = async () => {
  try {
    await $fetch('/api/posts', { method: 'POST', body: form })
    toast.add({
      title: 'Succès',
      description: 'Post créé avec succès',
      color: 'success',
    })
  } catch (e) {
    toast.add({
      title: 'Erreur',
      description: 'Impossible de créer le post',
      color: 'error',
    })
  }
}
</script>
```

## Dark mode

```vue
<script setup lang="ts">
const colorMode = useColorMode()

const toggle = () => {
  colorMode.preference = colorMode.value === 'dark' ? 'light' : 'dark'
}
</script>

<template>
  <UButton
    :icon="colorMode.value === 'dark' ? 'i-heroicons-sun' : 'i-heroicons-moon'"
    @click="toggle"
    color="gray"
    variant="ghost"
  />
</template>
```

## Command palette

```vue
<script setup lang="ts">
const commandPalette = ref()

const commands = [
  {
    id: 'posts',
    label: 'Posts',
    icon: 'i-heroicons-document-text',
    to: '/posts',
  },
  {
    id: 'users',
    label: 'Utilisateurs',
    icon: 'i-heroicons-users',
    to: '/users',
  },
]
</script>

<template>
  <UCommandPalette
    v-model:open="commandPalette"
    :groups="[{ id: 'nav', items: commands }]"
  />
</template>
```

## Bonnes pratiques

1. **Nuxt UI v3** — Dernière version pour Nuxt 4
2. **Auto-imports** — Composants U* auto-importés
3. **Dark mode** — `useColorMode()` natif
4. **Responsive** — `sm:`, `md:`, `lg:` breakpoints
5. **TypeScript** — Types pour les columns, forms, etc.
6. **Loading states** — `pending` avec UTable/UButton
7. **Error handling** — UToast pour les erreurs
8. **Accessibility** — Composants ARIA-ready
9. **Customization** — `app.config.ts` pour le theme
10. **Icones** — `i-heroicons-*` auto-importées

## Validation

- [ ] Nuxt UI installé et configuré
- [ ] Dark mode fonctionnel
- [ ] Tables avec colonnes typées
- [ ] Formulaires avec validation
- [ ] Modals pour les actions destructrices
- [ ] Notifications pour le feedback
