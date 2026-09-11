# Phase 4 — Architecture technique

## Objectif
Définir la stack, les patterns et les choix techniques.

## Prérequis
Phases 1, 2 et 3 validées.

## Étape 4.1 — Stack technique

### Frontend
- **Framework** : React / Vue / Svelte / Next.js / Nuxt / Autre
- **Langage** : TypeScript / JavaScript
- **State management** : Zustand / Pinia / Redux / Context
- **Design system** : Tailwind / Shadcn / Material / Custom
- **Mobile** : React Native / Flutter / PWA / Natif
- **Desktop** : Electron / Tauri / Natif

### Backend
- **Langage** : TypeScript / Go / Rust / Python / PHP
- **Framework** : Express / Fastify / NestJS / Laravel / FastAPI / Autre
- **API** : REST / GraphQL / tRPC / gRPC
- **Auth** : JWT / Sessions / OAuth/OIDC

### Base de données
- **Principale** : PostgreSQL / MySQL / MongoDB / SQLite
- **Cache** : Redis / Memcached / In-memory
- **Recherche** : Elasticsearch / Meilisearch / Typesense / pg_trgm
- **File** : Redis Streams / RabbitMQ / Kafka / BullMQ

### Infrastructure
- **Cloud** : AWS / GCP / Azure / Vercel / Railway / Fly.io
- **Conteneurs** : Docker / Kubernetes / Compose
- **CI/CD** : GitHub Actions / GitLab CI / CircleCI
- **Monitoring** : Sentry / Grafana / Datadog / Uptime Robot

## Étape 4.2 — Architecture applicative

### Pattern
- [ ] Monolithe modulaire
- [ ] Microservices
- [ ] Serverless
- [ ] Modular monolith (modulaire avec séparation nette)

### Communication
- [ ] Synchrone (HTTP, gRPC)
- [ ] Asynchrone (queues, événements)
- [ ] Événementiel (event sourcing, CQRS)

## Étape 4.3 — Multi-tenant et isolation

Utiliser `references/multi-tenant-patterns.md` et `templates/data-isolation.md`.

### Stratégie d'isolation
- [ ] Mono-base avec `tenant_id` sur chaque table
- [ ] Schémas séparés par tenant
- [ ] Bases séparées par tenant

### Résolution du tenant
- [ ] JWT claim `tenant_id`
- [ ] Sous-domaine (`tenant.app.com`)
- [ ] Header personnalisé
- [ ] Path prefix (`/org/:tenantId/...`)

### Sécurité inter-tenant
- Row-Level Security (RLS) PostgreSQL
- Filtre applicatif dans le service layer
- Clés primaires composites `(tenant_id, id)`
- Tests de fuite inter-tenants en CI

## Étape 4.4 — Sécurité

### Chiffrement
- [ ] TLS en transit (HTTPS)
- [ ] Chiffrement au repos (BDD, S3)
- [ ] Chiffrement côté client (si applicable)

### Gestion des secrets
- [ ] Variables d'environnement
- [ ] KMS cloud
- [ ] Vault (HashiCorp, AWS Secrets Manager)

### Protection
- [ ] Rate limiting (par tenant, par user, global)
- [ ] Protection CSRF / XSS / SQL injection
- [ ] Audit log pour actions sensibles
- [ ] Input validation côté serveur

## Étape 4.5 — Paiements (si applicable)

Utiliser `templates/payments.md` et `references/payment-patterns.md`.

### PSP
- **Principal** : Stripe / PayPal / Paystack / Flutterwave
- **Fallback** : virement / mobile money / autre
- **Pays** : cartographie PSP vs fallback

### Workflow
```
Paiement reçu → pending → review → paid / rejected
                      ↓
                auto-approved (si seuil bas)
```

### Anti-fraude
- [ ] Velocity checks (nombre de transactions)
- [ ] Montant seuil
- [ ] Blacklist / whitelist
- [ ] Séparation des devoirs (celui qui paie ≠ celui qui valide)

### Réconciliation
- [ ] Import de relevés PSP
- [ ] Matching automatique
- [ ] Alertes sur écarts

## Étape 4.6 — Modèle de données

Définir les entités principales :

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Tenant     │────<│    User     │────<│    Order    │
└─────────────┘     └─────────────┘     └─────────────┘
                           │
                           │
                    ┌─────────────┐
                    │   Payment   │
                    └─────────────┘
```

Pour chaque entité, définir :
- Champs principaux
- Relations
- Index
- Contraintes

## Livrable
Générer `docs/projet/03-architecture.md` avec :
- Schéma d'architecture (Mermaid si possible)
- Stack détaillée avec justifications
- Modèle de données (entités principales)
- Flux d'authentification et d'autorisation
- Stratégie multi-tenant
- Workflow de paiement (si applicable)
