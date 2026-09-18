---
name: sentry
description: >
  Sentry pour Laravel 13 et Nuxt.js : error tracking, logs structurés,
  distributed tracing, profiling, source maps, alertes. Compatible avec
  Sentry cloud ou self-hosted (Rustrak). Utiliser quand on configure Sentry,
  on debug des erreurs, on met en place du monitoring, ou on optimise le
  tracing entre frontend et backend.
license: MIT
compatibility: "Claude Code, Codex, OpenCode, Pi, omp"
allowed-tools: Read Write Glob Grep Bash
user-invocable: true
---

# Sentry — Monitoring Laravel + Nuxt

Tu es un expert Sentry pour Laravel et Nuxt. Ton rôle est de configurer
l'error tracking, les logs structurés, le distributed tracing, et le
monitoring entre le backend Laravel et le frontend Nuxt.

## Quand utiliser

- Configurer Sentry dans un projet Laravel ou Nuxt
- Debuguer des erreurs dans Sentry
- Mettre en place du distributed tracing
- Configurer les source maps pour les stack traces lisibles
- Ajouter des logs structurés vers Sentry
- Configurer des alertes

## Quand NE PAS utiliser

- Monitoring purement infrastructure (Prometheus, Grafana)
- APM non-Sentry (Datadog, New Relic)

## Architecture

```
Nuxt (Frontend)                 Laravel (Backend)
├── @sentry/nuxt                ├── sentry/sentry-laravel
├── Source maps → Sentry        ├── Logs → Sentry
├── Traces → Sentry             ├── Traces → Sentry
└── Replay (optionnel)          └── Profiling (optionnel)
         │                              │
         └────────── Sentry ────────────┘
                    (cloud ou Rustrak)
```

## 1. Laravel — Installation

```bash
composer require sentry/sentry-laravel
php artisan sentry:publish --dsn=https://<key>@o<orgId>.ingest.sentry.io/<projectId>
```

### bootstrap/app.php

```php
<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Sentry\Laravel\Integration;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware) {
        //
    })
    ->withExceptions(function (Exceptions $exceptions) {
        Integration::handles($exceptions);
    })
    ->create();
```

### .env

```ini
SENTRY_LARAVEL_DSN=https://<key>@o<orgId>.ingest.sentry.io/<projectId>
SENTRY_TRACES_SAMPLE_RATE=1.0
SENTRY_ENABLE_LOGS=true
SENTRY_LOG_LEVEL=warning
```

## 2. Laravel — Logs structurés

```ini
# .env
LOG_CHANNEL=stack
LOG_STACK=single,sentry_logs
SENTRY_ENABLE_LOGS=true
SENTRY_LOG_LEVEL=warning
```

### Usage

```php
use Illuminate\Support\Facades\Log;

// Log standard (va dans Sentry via le stack)
Log::info('Commande traitée', ['order_id' => $order->id]);

// Log directement vers Sentry
Log::channel('sentry_logs')->error('Échec paiement', [
    'user_id' => $user->id,
    'amount' => $amount,
]);
```

### Best practices logs

```php
// ✅ Wide event avec contexte
Log::info('Checkout complété', [
    'order_id' => $order->id,
    'user_id' => $user->id,
    'cart_value' => $cart->total,
    'payment_method' => 'stripe',
    'duration_ms' => $duration,
]);

// ❌ Scattered thin logs
Log::info('Début checkout');
Log::info('Validation panier');
Log::info('Paiement traité');
```

## 3. Laravel — Tracing

```ini
# .env
SENTRY_TRACES_SAMPLE_RATE=1.0  # 100% en dev, réduire en prod
```

### Distributed tracing vers Nuxt

```blade
{{-- resources/views/app.blade.php --}}
<head>
    {!! \Sentry\Laravel\Integration::sentryMeta() !!}
</head>
```

Cela injecte les meta tags `sentry-trace` et `baggage` pour connecter
le trace du backend au frontend.

### Custom instrumentation

```php
use Sentry\Tracing\SpanContext;

$parentSpan = \Sentry\SentrySdk::getCurrentHub()->getSpan();

if ($parentSpan !== null) {
    $context = SpanContext::make()
        ->setDescription('Processus commande')
        ->setOp('commerce.order');

    $span = $parentSpan->startChild($context);
    \Sentry\SentrySdk::getCurrentHub()->setSpan($span);

    // Votre logique...

    $span->finish();
    \Sentry\SentrySdk::getCurrentHub()->setSpan($parentSpan);
}
```

## 4. Laravel — Breadcrumbs

```php
use Sentry\Breadcrumb;

\Sentry\addBreadcrumb(
    category: 'auth',
    message: 'Utilisateur connecté',
    metadata: ['user_id' => $userId],
    level: Breadcrumb::LEVEL_INFO,
);
```

## 5. Laravel — Enrichir les erreurs

### User context

```php
// Middleware
\Sentry\configureScope(function (\Sentry\State\Scope $scope) use ($user): void {
    $scope->setUser([
        'id' => $user->id,
        'email' => $user->email,
    ]);
});
```

### Tags

```php
\Sentry\configureScope(function (\Sentry\State\Scope $scope): void {
    $scope->setTag('page.locale', 'fr-fr');
    $scope->setTag('feature', 'checkout');
});
```

## 6. Nuxt — Installation

```bash
npx nuxi@latest module add sentry
```

### nuxt.config.ts

```typescript
export default defineNuxtConfig({
  modules: ['@sentry/nuxt/module'],

  sentry: {
    dsn: 'https://<key>@o<orgId>.ingest.sentry.io/<projectId>',
    tracesSampleRate: 1.0,
    replaysSessionSampleRate: 0.1,
    replaysOnErrorSampleRate: 1.0,
  },
})
```

### Sentry client config

```typescript
// sentry.client.config.ts
import * as Sentry from "@sentry/nuxt";

Sentry.init({
  dsn: "https://<key>@o<orgId>.ingest.sentry.io/<projectId>",

  tracesSampleRate: 1.0,

  // Optionnel : Session Replay
  replaysSessionSampleRate: 0.1,
  replaysOnErrorSampleRate: 1.0,
});
```

### Sentry server config

```typescript
// sentry.server.config.ts
import * as Sentry from "@sentry/nuxt";

Sentry.init({
  dsn: "https://<key>@o<orgId>.ingest.sentry.io/<projectId>",
  tracesSampleRate: 1.0,
});
```

## 7. Nuxt — Source maps

```typescript
// nuxt.config.ts
export default defineNuxtConfig({
  sentry: {
    sourceMapsLoaderOptions: {
      // Supprimer les source maps après upload
      deleteSourcemapsAfterUpload: true,
    },
  },
})
```

Pour Rustrak (self-hosted), configurer le plugin Vite :

```typescript
// nuxt.config.ts
import { sentryVitePlugin } from "@sentry/vite-plugin";

export default defineNuxtConfig({
  vite: {
    plugins: [
      sentryVitePlugin({
        org: "anything",  // ignoré par Rustrak
        project: "my-project",  // doit matcher le slug Rustrak
        authToken: process.env.SENTRY_AUTH_TOKEN,
        url: process.env.SENTRY_URL,  // URL de Rustrak
        sourcemaps: {
          filesToDeleteAfterUpload: ["./**/*.map"],
        },
      }),
    ],
  },
})
```

## 8. Nuxt — Logs structurés

```typescript
// Dans un composable ou page
const { logger } = useSentryLogger();

logger.info("Utilisateur connecté", {
  userId: user.id,
  plan: user.plan,
});

logger.error("Paiement échoué", {
  orderId: order.id,
  reason: "card_declined",
});
```

## 9. Nuxt — Error handling

```typescript
// app.vue ou error.vue
<script setup lang="ts">
import * as Sentry from "@sentry/nuxt";

const error = useError();

if (error.value) {
  Sentry.captureException(error.value);
}
</script>
```

## 10. Rustrak (Self-hosted)

Si vous utilisez Rustrak au lieu de Sentry cloud :

### Laravel

```ini
SENTRY_LARAVEL_DSN=http://<key>@<rustrak-host>:8080/<projectId>
```

### Nuxt

```typescript
Sentry.init({
  dsn: "http://<key>@<rustrak-host>:8080/<projectId>",
  // Pas de tunnel nécessaire, Rustrak accepte les CORS
})
```

### Source maps vers Rustrak

```bash
# .env
SENTRY_AUTH_TOKEN=<token-rustrak>
SENTRY_URL=http://<rustrak-host>:8080
```

## 11. Features Rustrak

Rustrak est compatible avec les SDKs Sentry mais ne supporte pas :
- Performance monitoring (transactions, spans) — en dehors des erreurs
- Session Replay
- Release management
- Profiling

Pour ces features, utiliser Sentry cloud.

## Bonnes pratiques

1. **DSN dans .env** — Jamais en dur dans le code
2. **Sample rate** — 100% en dev, réduire en prod (0.1-0.5)
3. **Source maps** — Toujours upload pour les stack traces lisibles
4. **Distributed tracing** — Meta tags Laravel → Nuxt pour connecter les traces
5. **Logs structurés** — Wide events avec contexte, pas de thin logs
6. **User context** — Setter l'utilisateur pour le debugging
7. **Tags** — Filtrer par environment, feature, etc.
8. **Breadcrumbs** — Ajouter du contexte avant les erreurs
9. **before_send** — Filtrer les erreurs non pertinentes
10. **CORS** — Autoriser `sentry-trace` et `baggage` headers

## Checklist setup

### Laravel
- [ ] `sentry/sentry-laravel` installé
- [ ] DSN configuré dans `.env`
- [ ] Exceptions handler configuré (`Integration::handles()`)
- [ ] Logs channel `sentry_logs` configuré
- [ ] Tracing sample rate défini
- [ ] Meta tags pour distributed tracing

### Nuxt
- [ ] `@sentry/nuxt` installé
- [ ] Module ajouté à `nuxt.config.ts`
- [ ] Client + server config créés
- [ ] Source maps upload configurés
- [ ] Tracing sample rate défini
- [ ] CORS headers autorisés (si Laravel séparé)

## Cross-références

- `laravel-core` — Fondamentaux Laravel
- `laravel-security` — Sécurité
- `laravel-performance` — Performance
- `nuxt-core` — Fondamentaux Nuxt
- `laravel-nuxt` — API Laravel pour Nuxt
