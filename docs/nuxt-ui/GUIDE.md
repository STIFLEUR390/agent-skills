# Guide d'utilisation — nuxt-ui

Composants UI et design system avec Nuxt UI.

---

## Quand l'utiliser

- Créer des interfaces avec Nuxt UI
- Configurer le dark mode
- Implémenter des tables, formulaires, modals

---

## Exemple 1 — Table de données

**Demander**：
```
Crée une table pour afficher les posts avec actions.
```

**Le skill génère**：

```vue
<script setup lang="ts">
const { data: posts } = await useFetch('/api/posts')

const columns = [
  { key: 'title', label: 'Titre' },
  { key: 'actions', label: 'Actions' },
]
</script>

<template>
  <UTable :columns="columns" :data="posts.data">
    <template #actions-data="{ row }">
      <UButton icon="i-heroicons-pencil" :to="`/posts/${row.id}/edit`" />
    </template>
  </UTable>
</template>
```

---

## Exemple 2 — Formulaire

**Demander**：
```
Crée un formulaire de création de post avec validation.
```

**Le skill génère**：

```vue
<UForm :state="form" @submit="submit">
  <UFormField label="Titre" name="title">
    <UInput v-model="form.title" />
  </UFormField>
  <UButton type="submit" label="Enregistrer" />
</UForm>
```

---

## Voir aussi

- `nuxt-core` — Fondamentaux Nuxt
- `laravel-nuxt` — API Laravel
