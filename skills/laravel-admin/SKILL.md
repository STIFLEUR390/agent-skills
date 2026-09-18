---
name: laravel-admin
description: >
  Panneaux admin avec Filament pour Laravel. Ressources, form builders, tables,
  widgets, thèmes. Utiliser quand on crée un panneau admin, on configure Filament,
  ou on customise l'interface admin.
license: MIT
compatibility: "Claude Code, Codex, OpenCode, Pi, omp"
allowed-tools: Read Write Glob Grep Bash
user-invocable: true
---

# Laravel Admin — Filament pour Laravel 13

Tu es un expert Filament pour Laravel. Ton rôle est de guider la création
de panneaux admin élégants et fonctionnels.

## Quand utiliser

- Créer un panneau admin
- Configurer Filament
- Créer des ressources CRUD
- Ajouter des widgets et dashboard

## Installation

```bash
composer require filament/filament:"^3.2" -W
php artisan filament:install --panels
```

## Resource

```php
<?php

namespace App\Filament\Resources;

use App\Filament\Resources\PostResource\Pages;
use App\Models\Post;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class PostResource extends Resource
{
    protected static ?string $model = Post::class;

    protected static ?string $navigationIcon = 'heroicon-o-document-text';

    protected static ?string $navigationGroup = 'Content';

    protected static ?int $navigationSort = 1;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Détails')
                    ->schema([
                        Forms\Components\TextInput::make('title')
                            ->required()
                            ->maxLength(255)
                            ->live(onBlur: true)
                            ->afterStateUpdated(fn ($operation, $state) =>
                                $form->getModel() instanceof Post &&
                                $operation === 'update' &&
                                ($form->data['slug'] ?? '') === '' &&
                                ($state !== null)
                                    ? $form->fill(['slug' => Str::slug($state)])
                                    : null
                            ),

                        Forms\Components\Slug::make('slug')
                            ->source('title')
                            ->unique(Post::class, 'slug', ignoreRecord: true),

                        Forms\Components\RichEditor::make('content')
                            ->required()
                            ->columnSpanFull(),
                    ]),

                Forms\Components\Section::make('Méta')
                    ->schema([
                        Forms\Components\Select::make('user_id')
                            ->relationship('user', 'name')
                            ->required()
                            ->searchable(),

                        Forms\Components\Toggle::make('is_published')
                            ->default(false),

                        Forms\Components\DateTimePicker::make('published_at'),
                    ])
                    ->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('id')
                    ->sortable(),

                Tables\Columns\TextColumn::make('title')
                    ->searchable()
                    ->sortable(),

                Tables\Columns\TextColumn::make('user.name')
                    ->sortable(),

                Tables\Columns\IconColumn::make('is_published')
                    ->boolean(),

                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('user')
                    ->relationship('user', 'name'),

                Tables\Filters\TernaryFilter::make('is_published'),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
                Tables\Actions\DeleteAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ]);
    }

    public static function getRelations(): array
    {
        return [
            'comments' => CommentRelationManager::class,
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListPosts::route('/'),
            'create' => Pages\CreatePost::route('/create'),
            'edit' => Pages\EditPost::route('/{record}/edit'),
        ];
    }
}
```

## Widget

```php
<?php

namespace App\Filament\Widgets;

use App\Models\Post;
use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class PostStatsWidget extends BaseWidget
{
    protected static ?int $sort = 1;

    protected function getStats(): array
    {
        return [
            Stat::make('Posts', Post::count())
                ->description('Total des articles')
                ->descriptionIcon('heroicon-m-document-text')
                ->color('success'),

            Stat::make('Publiés', Post::where('is_published', true)->count())
                ->description('Articles publiés')
                ->descriptionIcon('heroicon-m-check-circle')
                ->color('primary'),

            Stat::make('Brouillons', Post::where('is_published', false)->count())
                ->description('En attente')
                ->descriptionIcon('heroicon-m-pencil')
                ->color('warning'),
        ];
    }
}
```

## Chart Widget

```php
<?php

namespace App\Filament\Widgets;

use App\Models\Post;
use Filament\Widgets\ChartWidget;

class PostChartWidget extends ChartWidget
{
    protected static ?string $heading = 'Articles par mois';

    protected static ?int $sort = 2;

    protected function getData(): array
    {
        $data = Post::selectRaw('MONTH(created_at) as month, COUNT(*) as count')
            ->whereYear('created_at', now()->year)
            ->groupBy('month')
            ->pluck('count', 'month')
            ->toArray();

        return [
            'datasets' => [
                [
                    'label' => 'Articles',
                    'data' => array_values($data),
                ],
            ],
            'labels' => array_map(fn ($m) => now()->month($m)->format('M'), array_keys($data)),
        ];
    }

    protected function getType(): string
    {
        return 'bar';
    }
}
```

## Custom Page

```php
<?php

namespace App\Filament\Resources\PostResource\Pages;

use App\Filament\Resources\PostResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListPosts extends ListRecords
{
    protected static string $resource = PostResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make(),
        ];
    }
}
```

## Bonnes pratiques

1. **Filament v3** pour Laravel 12+
2. **Ressources** = CRUD automatisé
3. **Widgets** pour le dashboard
4. **Custom pages** pour les flux métier
5. **Groups** pour organiser la navigation
6. **Relations** avec RelationManagers
7. **Filtres** pour affiner les données
8. **Actions** pour les opérations bulk
9. **Validation** via Form Builder
10. **Permissions** via Policies

## Validation

- [ ] Ressources pour tous les modèles admin
- [ ] Widgets de stats
- [ ] Filtres configurés
- [ ] Actions bulk
- [ ] Relations gérées
- [ ] Permissions via Policies
