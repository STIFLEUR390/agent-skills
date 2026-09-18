# Guide d'utilisation — sentry

Sentry pour Laravel 13 et Nuxt.js : error tracking, logs, tracing.

---

## Quand l'utiliser

- Configurer Sentry dans un projet Laravel ou Nuxt
- Debuguer des erreurs via Sentry
- Mettre en place du distributed tracing
- Ajouter des logs structurés

---

## Exemple 1 — Setup Laravel rapide

**Demander**：
```
Configure Sentry dans ce projet Laravel.
```

**Le skill fait**：
1. Installe `sentry/sentry-laravel`
2. Configure `bootstrap/app.php`
3. Ajoute le DSN dans `.env`
4. Configure les logs channel

---

## Exemple 2 — Setup Nuxt rapide

**Demander**：
```
Ajoute Sentry à ce projet Nuxt.
```

**Le skill fait**：
1. Installe `@sentry/nuxt`
2. Ajoute le module dans `nuxt.config.ts`
3. Crée les configs client/server
4. Configure les source maps

---

## Exemple 3 — Distributed tracing

**Demander**：
```
Connecte les traces entre Laravel et Nuxt.
```

**Le skill génère**：

Laravel (blade) :
```blade
<head>
    {!! \Sentry\Laravel\Integration::sentryMeta() !!}
</head>
```

Nuxt : auto avec `tracePropagationTargets`.

---

## Voir aussi

- `laravel-core` — Fondamentaux Laravel
- `laravel-nuxt` — API Laravel pour Nuxt
- `nuxt-core` — Fondamentaux Nuxt
