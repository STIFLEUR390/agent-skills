# Principes des applications modernes

## 1. Socle commun

### Authentification
- **JWT + Refresh tokens** : access token court (15min), refresh long (7 jours)
- **OAuth/OIDC** : Google, GitHub, Microsoft pour le SSO
- **Passkeys** : authentification sans mot de passe (FIDO2)
- **MFA** : TOTP (Google Authenticator) ou SMS en backup

### Autorisation
- **RBAC** : rôles basés sur les fonctions
- **ABAC** : attributs (tenant, scope, contexte)
- **Deny by default** : tout interdit sauf autorisation explicite
- **Défense en profondeur** : UI → route → API → service → DB

### Données
- **Multi-tenant** : `tenant_id` sur chaque table métier
- **Soft delete** : jamais de suppression physique
- **Audit log** : traçabilité de toutes les actions sensibles
- **Chiffrement** : au repos (AES-256) et en transit (TLS 1.3)

## 2. Frontend moderne

### Architecture
- **SSR / SSG** : Next.js, Nuxt, SvelteKit
- **State management** : Zustand (léger), Pinia (Vue), Redux Toolkit
- **Design system** : Tailwind + Shadcn/UI, Radix, Headless UI
- **Type safety** : TypeScript partout

### Performance
- **Lazy loading** : routes et composants lourds
- **Code splitting** : chunks par route
- **Optimistic updates** : UI responsive avant confirmation serveur
- **Service workers** : cache et offline

### Accessibilité
- **WCAG 2.1 AA** : minimum
- **Keyboard navigation** : toutes les actions accessibles
- **Screen readers** : ARIA labels, live regions
- **Contraste** : ratio 4.5:1 minimum

## 3. Backend moderne

### API
- **REST** : standard, bien compris
- **GraphQL** : flexible, idéal pour des clients variés
- **tRPC** : type-safe end-to-end (monolithe TypeScript)
- **Versioning** : `/api/v1/...`

### Architecture
- **Modular monolith** : séparation par domaines
- **CQRS léger** : lectures/écrites séparées si nécessaire
- **Event-driven** : pour les flux asynchrones
- **Idempotency** : sur toutes les mutations critiques

### Base de données
- **PostgreSQL** : choix par défaut (RLS, JSON, extensions)
- **Migrations** : Prisma, Drizzle, Knex, Atlas
- **Index** : sur les colonnes de filtrage fréquent
- **Connexion pooling** : PgBouncer ou équivalent

## 4. Infrastructure

### Cloud
- **Serverless** : Vercel, Railway, Fly.io, AWS Lambda
- **Containers** : Docker + Compose (dev), Kubernetes (prod)
- **Managed services** : DB managée, cache managé, search managé

### CI/CD
- **Pipeline** : lint → test → build → deploy staging → manual → prod
- **Preview deployments** : par PR
- **Feature flags** : LaunchDarkly, Unleash, custom

### Monitoring
- **Logs** : structurés (JSON), centrés (Grafana Loki, Datadog)
- **Métriques** : Prometheus + Grafana
- **Traces** : OpenTelemetry
- **Erreurs** : Sentry
- **Uptime** : BetterStack, UptimeRobot

## 5. Sécurité

### Checklist OWASP Top 10
- [ ] Injection (SQL, NoSQL, ORM)
- [ ] Broken authentication
- [ ] Sensitive data exposure
- [ ] XML External Entities (XXE)
- [ ] Broken access control
- [ ] Security misconfiguration
- [ ] Cross-site scripting (XSS)
- [ ] Insecure deserialization
- [ ] Using components with known vulnerabilities
- [ ] Insufficient logging & monitoring

### Headers de sécurité
```
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Content-Security-Policy: default-src 'self'
Referrer-Policy: strict-origin-when-cross-origin
```

## 6. Offline et résilience

### Niveaux
1. **Cache** : données en lecture seule disponibles
2. **Optimistic** : opérations en attente de sync
3. **Full offline** : application fonctionnelle sans réseau

### Patterns
- **Service workers** : cache des assets et API
- **IndexedDB** : stockage local structuré
- **Background sync** : synchronisation en arrière-plan
- **Conflict resolution** : last-write-wins, merge, ou manuel

## 7. IA et personnalisation

### Intégration IA
- **Copilote** : suggestions contextuelles
- **Recherche sémantique** : embeddings + vector DB
- **Classification** : tri automatique des contenus
- **Génération** : texte, images, code

### Personnalisation
- **AB testing** : variantes d'interface
- **Recommandations** : contenu pertinent
- **Adaptive UI** : interface selon le comportement
