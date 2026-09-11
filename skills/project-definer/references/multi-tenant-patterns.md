# Patterns multi-tenant SaaS

## 1. Stratégies d'isolation

### Mono-base avec tenant_id
**Quand** : SaaS standard, coût optimisé, beaucoup de petits tenants

```
┌─────────────────────────────────────┐
│           Database                   │
│  ┌───────────────────────────────┐  │
│  │ orders                        │  │
│  │ tenant_id | id | data | ...   │  │
│  │ A         | 1  | ...         │  │
│  │ A         | 2  | ...         │  │
│  │ B         | 1  | ...         │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

**Avantages** : simple, économique, maintenance unique
**Inconvénients** : isolation logique (pas physique), performance partagée

### Schémas séparés
**Quand** : Réglementation modérée, tenants moyens

```
┌─────────────────────────────────────┐
│           Database                   │
│  ┌─────────────┐ ┌─────────────┐   │
│  │ tenant_a.*  │ │ tenant_b.*  │   │
│  │ orders      │ │ orders      │   │
│  │ users       │ │ users       │   │
│  └─────────────┘ └─────────────┘   │
└─────────────────────────────────────┘
```

**Avantages** : isolation forte, backup/restore par tenant
**Inconvénients** : complexité, migrations multiples

### Bases séparées
**Quand** : Enterprise, banking, HIPAA

```
┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│   DB Tenant │ │   DB Tenant │ │   DB Tenant │
│      A      │ │      B      │ │      C      │
│  ┌───────┐  │ │  ┌───────┐  │ │  ┌───────┐  │
│  │orders │  │ │  │orders │  │ │  │orders │  │
│  │users  │  │ │  │users  │  │ │  │users  │  │
│  └───────┘  │ │  └───────┘  │ │  └───────┘  │
└─────────────┘ └─────────────┘ └─────────────┘
```

**Avantages** : isolation maximale, scaling indépendant
**Inconvénients** : coûteux, maintenance élevée

## 2. Résolution du tenant

### JWT claim
```json
{
  "sub": "user-id",
  "tenant_id": "tenant-uuid",
  "realm": "client"
}
```

**Avantages** : simple, performant, stateless
**Inconvénients** : rotation du tenant nécessite nouveau token

### Sous-domaine
```
tenant-a.app.com → tenant_id = A
tenant-b.app.com → tenant_id = B
```

**Avantages** : clair, SEO-friendly
**Inconvénients** : wildcard SSL, DNS management

### Path prefix
```
app.com/org/tenant-a/orders
app.com/org/tenant-b/orders
```

**Avantages** : pas de DNS, simple
**Inconvénients** : moins propre, routing côté app

## 3. Clés primaires composites

### Pattern
```sql
-- Clé composite
PRIMARY KEY (tenant_id, id)

-- ou UUID avec tenant_id
id UUID DEFAULT gen_random_uuid(),
tenant_id UUID NOT NULL,
PRIMARY KEY (tenant_id, id)
```

### Avantages
- Garantit l'unicité par tenant
- Requêtes par tenant très performantes (clustered index)
- Compatible avec RLS

### Inconvénients
- JOINs plus complexes
- Références cross-tenant difficiles

## 4. Row-Level Security (RLS)

### PostgreSQL
```sql
-- Activation
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Politique de base
CREATE POLICY tenant_isolation ON orders
    USING (tenant_id = current_setting('app.tenant_id')::UUID);

-- Politique scope-aware
CREATE POLICY orders_policy ON orders
    FOR ALL
    USING (
        tenant_id = current_setting('app.tenant_id')::UUID
        AND (
            current_setting('app.scope') = 'tenant'
            OR (
                current_setting('app.scope') = 'self'
                AND user_id = current_setting('app.user_id')::UUID
            )
        )
    );
```

### Contexte de requête
```sql
-- Définir le contexte avant chaque requête
SET app.tenant_id = 'uuid-du-tenant';
SET app.user_id = 'uuid-de-l-utilisateur';
SET app.scope = 'self'; -- self | team | tenant | global
```

## 5. Entitlements et limites

### Modèle
```typescript
interface TenantEntitlements {
  tenantId: string;
  plan: 'free' | 'starter' | 'pro' | 'enterprise';
  limits: {
    users: number;
    storage: number; // bytes
    apiCalls: number; // per month
    projects: number;
  };
  features: {
    sso: boolean;
    auditLog: boolean;
    customDomain: boolean;
    priority: boolean;
  };
}
```

### Vérification
```typescript
function checkEntitlement(tenantId: string, feature: string) {
  const entitlements = cache.get(`entitlements:${tenantId}`);
  if (!entitlements.features[feature]) {
    throw new ForbiddenError(`Feature ${feature} not available on ${entitlements.plan}`);
  }
}
```

## 6. Billing et usage

### Métriques d'usage
```sql
CREATE TABLE usage_metrics (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    metric VARCHAR(100) NOT NULL, -- 'api_calls', 'storage', 'users'
    value BIGINT NOT NULL,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    UNIQUE(tenant_id, metric, period_start)
);
```

### Agrégation
```typescript
async function getUsage(tenantId: string, metric: string) {
  return db.usageMetrics.aggregate({
    where: {
      tenantId,
      metric,
      periodStart: { gte: startOfMonth() }
    },
    _sum: { value: true }
  });
}
```

## 7. Checklist multi-tenant

- [ ] Tenant ID sur TOUTES les tables métier
- [ ] Clés primaires composites ou index tenant_id
- [ ] RLS activé (PostgreSQL)
- [ ] Contexte de requête propagé (AsyncLocalStorage)
- [ ] Cache namespacé par tenant
- [ ] Storage préfixé par tenant
- [ ] Logs structurés avec tenant_id
- [ ] Entitlements par plan
- [ ] Usage tracking
- [ ] Tests d'isolation en CI
- [ ] Rate limiting par tenant
- [ ] Audit log par tenant
