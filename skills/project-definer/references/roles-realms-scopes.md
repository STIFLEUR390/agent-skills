# RBAC + ABAC + Realms + Scopes

## 1. Concepts

### RBAC (Role-Based Access Control)
Les permissions sont attachées aux rôles, les rôles aux utilisateurs.

```
User → hasRole → Role → hasPermission → Permission
```

### ABAC (Attribute-Based Access Control)
Les permissions dépendent d'attributs (tenant, contexte, ressource).

```
User(attribute) + Resource(attribute) + Context(attribute) → Decision
```

### Realms
Domaines d'authentification séparés. Chaque realm a :
- Son propre audience JWT
- Ses propres règles d'authentification
- Son propre pool d'utilisateurs

### Scopes
Niveau de visibilité des données :
- `self` : ses propres données
- `team` : données de son équipe
- `tenant` : données de son organisation
- `global` : toutes les données

## 2. Architecture des réalms

```
┌─────────────────────────────────────────────┐
│                  API Gateway                │
│  ┌─────────┐ ┌─────────┐ ┌──────────────┐  │
│  │ client  │ │  staff  │ │    admin     │  │
│  │  realm  │ │  realm  │ │    realm     │  │
│  └────┬────┘ └────┬────┘ └──────┬───────┘  │
│       │           │             │           │
│  ┌────▼────┐ ┌────▼────┐ ┌─────▼───────┐  │
│  │ client  │ │  staff  │ │   admin     │  │
│  │  JWT    │ │  JWT    │ │    JWT      │  │
│  │aud:cli  │ │aud:staff│ │aud:admin    │  │
│  └─────────┘ └─────────┘ └─────────────┘  │
└─────────────────────────────────────────────┘
```

### JWT par realm

```json
// Client
{
  "sub": "user-id",
  "realm": "client",
  "tenant_id": "tenant-uuid",
  "aud": "client",
  "permissions": ["order:read:self", "order:create"]
}

// Staff
{
  "sub": "staff-id",
  "realm": "staff",
  "tenant_id": "tenant-uuid",
  "aud": "staff",
  "permissions": ["order:read:all", "order:validate"]
}

// Admin
{
  "sub": "admin-id",
  "realm": "admin",
  "aud": "admin",
  "permissions": ["*"]  // ou liste complète
}
```

## 3. Matrice de permissions

### Format : `resource:action:scope`

| Permission | client | manager | support | admin |
|------------|:------:|:-------:|:-------:|:-----:|
| `order:read:self` | ✅ | ❌ | ✅ | ✅ |
| `order:read:all` | ❌ | ✅ | ✅ | ✅ |
| `order:create` | ✅ | ❌ | ❌ | ✅ |
| `order:update` | ❌ | ✅ | ❌ | ✅ |
| `order:validate` | ❌ | ✅ | ❌ | ✅ |
| `order:refund` | ❌ | ❌ | ✅ | ✅ |
| `user:read:self` | ✅ | ❌ | ❌ | ✅ |
| `user:read:all` | ❌ | ❌ | ✅ | ✅ |
| `user:create` | ❌ | ❌ | ❌ | ✅ |
| `user:delete` | ❌ | ❌ | ❌ | ✅ |
| `payment:read:self` | ✅ | ❌ | ❌ | ✅ |
| `payment:review` | ❌ | ✅ | ❌ | ✅ |
| `payment:approve` | ❌ | ❌ | ❌ | ✅ |
| `settings:read` | ❌ | ❌ | ❌ | ✅ |
| `settings:write` | ❌ | ❌ | ❌ | ✅ |

## 4. Défense en profondeur

### Couche 1 : UI
```tsx
// Composant conditionnel
{hasPermission('order:validate') && (
  <Button onClick={validateOrder}>Valider</Button>
)}
```

### Couche 2 : Route guard
```typescript
// Middleware route
router.get('/orders', requireRole('staff'), listOrders);
router.post('/orders/:id/validate', requirePermission('order:validate'), validateOrder);
```

### Couche 3 : API / Service
```typescript
// Service layer
async function validateOrder(orderId: string, user: User) {
  // Vérification explicite même si le guard est passé
  if (!user.permissions.includes('order:validate')) {
    throw new ForbiddenError();
  }
  // ...
}
```

### Couche 4 : Database (RLS)
```sql
-- RLS vérifie le scope
CREATE POLICY order_scope ON orders
    FOR SELECT
    USING (
        tenant_id = current_setting('app.tenant_id')::UUID
        AND (
            current_setting('app.scope') = 'tenant'
            OR user_id = current_setting('app.user_id')::UUID
        )
    );
```

## 5. Séparation des devoirs

### Principe
Celui qui configure ≠ celui qui valide ≠ celui qui exécute.

### Exemples

| Action | Configure | Valide | Exécute |
|--------|-----------|--------|---------|
| Paiement | Utilisateur | Manager | Système |
| Remboursement | Support | Admin | Système |
| Paramètres | Admin | — | — |
| Création user | Admin | — | Système |

## 6. Audit logging

```typescript
interface AuditLog {
  id: string;
  tenantId: string;
  userId: string;
  realm: string;
  action: string;
  resource: string;
  resourceId: string;
  changes: Record<string, { before: any; after: any }>;
  ip: string;
  userAgent: string;
  timestamp: Date;
}

// Middleware
function auditMiddleware(req, res, next) {
  const start = Date.now();
  res.on('finish', () => {
    if (isSensitiveAction(req.method, req.path)) {
      logAudit({
        tenantId: req.user.tenantId,
        userId: req.user.sub,
        realm: req.user.realm,
        action: req.method,
        resource: req.path,
        statusCode: res.statusCode,
        duration: Date.now() - start,
        ip: req.ip
      });
    }
  });
  next();
}
```

## 7. Checklist

- [ ] Realms définis (client, staff, admin)
- [ ] JWT audience par realm
- [ ] Matrice rôles × permissions documentée
- [ ] Scopes définis (self, team, tenant, global)
- [ ] Défense en profondeur (4 couches)
- [ ] Séparation des devoirs
- [ ] Audit log pour actions sensibles
- [ ] Tests d'autorisation en CI
