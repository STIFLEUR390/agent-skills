# Guide d'utilisation — laravel-admin

Panneaux admin avec Filament.

---

## Quand l'utiliser

- Créer un panneau admin
- Configurer Filament
- Créer des ressources CRUD

---

## Exemple 1 — Ressource CRUD

**Demander**：
```
Crée une ressource Filament pour gérer les posts.
```

**Le skill génère**：

```php
<?php

class PostResource extends Resource
{
    protected static ?string $model = Post::class;

    public static function form(Form $form): Form
    {
        return $form->schema([
            TextInput::make('title')->required(),
            RichEditor::make('content')->required(),
            Toggle::make('is_published'),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table->columns([
            TextColumn::make('title')->searchable(),
            IconColumn::make('is_published')->boolean(),
        ]);
    }
}
```

---

## Voir aussi

- `laravel-core` — Fondamentaux
- `laravel-security` — Permissions admin
