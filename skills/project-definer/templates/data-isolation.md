# Isolation des données — Multi-tenant

## 1. Stratégie d'isolation

### Options

| Stratégie | Isolation | Complexité | Coût | Usage |
|-----------|-----------|------------|------|-------|
| **Mono-base + tenant_id** | Logique | Faible | Économique | SaaS standard |
| **Schémas séparés** | Forte | Moyenne | Modéré | Réglementation stricte |
| **Bases séparées** | Maximale | Élevée | Élevé | Enterprise / Banking |

### Recommandation
[Choisir une stratégie et justifier]

## 2. Résolution du tenant

### Mécanismes

| Mécanisme | Description | Sécurité |
|-----------|-------------|----------|
| JWT claim `tenant_id` | Inclus dans le token | Haute |
| Sous-domaine | `tenant.app.com` | Moyenne |
| Header | `X-Tenant-ID` | Faible (modifiable) |
| Path | `/org/:tenantId/...` | Moyenne |
| Session | Stocké côté serveur | Haute |

### Recommandation
[Choisir un mécanisme et justifier]

## 3. Implémentation mono-base

### Modèle de données

```sql
-- Clé primaire composite
CREATE TABLE tenants (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    email VARCHAR(255) NOT NULL,
    name VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(tenant_id, email)
);

CREATE TABLE orders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    user_id UUID NOT NULL REFERENCES users(id, tenant_id),
    amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour performance
CREATE INDEX idx_users_tenant ON users(tenant_id);
CREATE INDEX idx_orders_tenant ON orders(tenant_id);
CREATE INDEX idx_orders_user ON orders(tenant_id, user_id);
```

### Row-Level Security (PostgreSQL)

```sql
-- Activer RLS sur toutes les tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Politique pour users
CREATE POLICY users_tenant_isolation ON users
    USING (tenant_id = current_setting('app.tenant_id')::UUID);

-- Politique pour orders
CREATE POLICY orders_tenant_isolation ON orders
    USING (tenant_id = current_setting('app.tenant_id')::UUID);

-- Politique scope-based (self vs all)
CREATE POLICY orders_scope_policy ON orders
    FOR SELECT
    USING (
        tenant_id = current_setting('app.tenant_id')::UUID
        AND (
            current_setting('app.scope') = 'tenant'
            OR user_id = current_setting('app.user_id')::UUID
        )
    );
```

### Contexte de requête

```typescript
// AsyncLocalStorage pour propager le contexte tenant
import { AsyncLocalStorage } from 'async_hooks';

interface RequestContext {
  tenantId: string;
  userId: string;
  realm: 'client' | 'staff' | 'admin';
  scope: 'self' | 'team' | 'tenant' | 'global';
}

const requestContext = new AsyncLocalStorage<RequestContext>();

// Middleware
function tenantMiddleware(req, res, next) {
  const tenantId = req.user?.tenant_id;
  const userId = req.user?.sub;
  const realm = req.user?.realm;
  const scope = req.user?.scope;

  requestContext.run({ tenantId, userId, realm, scope }, () => {
    // Injecter dans les requêtes SQL
    req.db.query(`SET app.tenant_id = '${tenantId}'`);
    req.db.query(`SET app.user_id = '${userId}'`);
    req.db.query(`SET app.scope = '${scope}'`);
    next();
  });
}
```

## 4. Ressources périphériques

| Ressource | Isolation | Mécanisme |
|-----------|-----------|-----------|
| **S3 / Storage** | Préfixe path | `s3://bucket/{tenant_id}/...` |
| **Cache (Redis)** | Namespace | `tenant:{tenant_id}:key` |
| **Queue** | Header metadata | `tenant_id` dans le payload |
| **Recherche** | Index filtré | Champ `tenant_id` indexé |
| **Logs** | Contexte structuré | `tenant_id` dans chaque log |

### Exemple Redis

```typescript
// Namespace par tenant
function tenantKey(key: string): string {
  const ctx = requestContext.getStore();
  return `tenant:${ctx.tenantId}:${key}`;
}

// Usage
await redis.set(tenantKey('user:123'), userData);
await redis.get(tenantKey('user:123'));
```

## 5. Tests d'isolation

### Tests inter-tenants

```typescript
describe('Tenant isolation', () => {
  it('should not leak data across tenants', async () => {
    // Créer des données pour tenant A
    const tenantA = await createTenant('A');
    const orderA = await createOrder(tenantA.id, { amount: 100 });

    // Créer des données pour tenant B
    const tenantB = await createTenant('B');
    const orderB = await createOrder(tenantB.id, { amount: 200 });

    // Tenant A ne doit PAS voir les commandes de tenant B
    const ctxA = { tenantId: tenantA.id, scope: 'tenant' };
    const ordersA = await listOrders(ctxA);
    expect(ordersA).toHaveLength(1);
    expect(ordersA[0].id).toBe(orderA.id);

    // Tenant B ne doit PAS voir les commandes de tenant A
    const ctxB = { tenantId: tenantB.id, scope: 'tenant' };
    const ordersB = await listOrders(ctxB);
    expect(ordersB).toHaveLength(1);
    expect(ordersB[0].id).toBe(orderB.id);
  });
});
```

### Tests de fuite en CI

```yaml
# GitHub Actions
- name: Test tenant isolation
  run: |
    psql $DATABASE_URL -f tests/sql/tenant-isolation-tests.sql
```

```sql
-- tests/sql/tenant-isolation-tests.sql
DO $$
DECLARE
    tenant_a UUID;
    tenant_b UUID;
    order_a UUID;
BEGIN
    -- Setup
    INSERT INTO tenants (id, name) VALUES (gen_random_uuid(), 'A') RETURNING id INTO tenant_a;
    INSERT INTO tenants (id, name) VALUES (gen_random_uuid(), 'B') RETURNING id INTO tenant_b;

    -- Create order for tenant A
    INSERT INTO orders (id, tenant_id, amount) VALUES (gen_random_uuid(), tenant_a, 100) RETURNING id INTO order_a;

    -- Verify RLS blocks cross-tenant reads
    PERFORM set_config('app.tenant_id', tenant_b::text, true);

    IF EXISTS (SELECT 1 FROM orders WHERE id = order_a) THEN
        RAISE EXCEPTION 'TENANT ISOLATION BREACH: Tenant B can read Tenant A data';
    END IF;

    -- Cleanup
    DELETE FROM orders WHERE tenant_id IN (tenant_a, tenant_b);
    DELETE FROM tenants WHERE id IN (tenant_a, tenant_b);
END $$;
```

## 6. Checklist de sécurité

- [ ] `tenant_id` sur TOUTES les tables métier
- [ ] Clés primaires composites `(tenant_id, id)`
- [ ] RLS activé sur toutes les tables
- [ ] Index tenant_id sur toutes les requêtes fréquentes
- [ ] Middleware contexte propagé
- [ ] Tests d'isolation en CI
- [ ] Audit log avec tenant_id
- [ ] Cache namespacé par tenant
- [ ] Storage préfixé par tenant
- [ ] Logs avec tenant_id structuré
