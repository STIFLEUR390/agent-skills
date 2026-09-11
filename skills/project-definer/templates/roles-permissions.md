# Matrice des rôles et permissions

## 1. Realms

| Realm | Description | Authentification | Audience JWT |
|-------|-------------|------------------|--------------|
| client | Utilisateur final | Inscription libre | `aud: client` |
| staff | Interne entreprise | Invitation | `aud: staff` |
| admin | Administrateur technique | Création manuelle | `aud: admin` |

## 2. Rôles

| Rôle | Realm | Description | Responsabilités |
|------|-------|-------------|-----------------|
| client | client | Utilisateur standard | Utiliser le service |
| manager | staff | Gestion des commandes | Valider, suivre |
| support | staff | Support client | Aider, résoudre |
| admin | admin | Administration complète | Tout configurer |

## 3. Permissions

### Format
`resource:action:scope`

### Actions
- `create` — Créer
- `read` — Lire
- `update` — Modifier
- `delete` — Supprimer
- `validate` — Valider
- `approve` — Approuver
- `reject` — Rejeter
- `refund` — Rembourser
- `export` — Exporter

### Matrice complète

| Permission | client | manager | support | admin |
|------------|:------:|:-------:|:-------:|:-----:|
| **order** | | | | |
| `order:read:self` | ✅ | ❌ | ✅ | ✅ |
| `order:read:all` | ❌ | ✅ | ✅ | ✅ |
| `order:create` | ✅ | ❌ | ❌ | ✅ |
| `order:update` | ❌ | ✅ | ❌ | ✅ |
| `order:validate` | ❌ | ✅ | ❌ | ✅ |
| `order:refund` | ❌ | ❌ | ✅ | ✅ |
| **user** | | | | |
| `user:read:self` | ✅ | ❌ | ❌ | ✅ |
| `user:read:all` | ❌ | ❌ | ✅ | ✅ |
| `user:create` | ❌ | ❌ | ❌ | ✅ |
| `user:update` | ❌ | ❌ | ✅ | ✅ |
| `user:delete` | ❌ | ❌ | ❌ | ✅ |
| **payment** | | | | |
| `payment:read:self` | ✅ | ❌ | ❌ | ✅ |
| `payment:read:all` | ❌ | ✅ | ✅ | ✅ |
| `payment:review` | ❌ | ✅ | ❌ | ✅ |
| `payment:approve` | ❌ | ❌ | ❌ | ✅ |
| **settings** | | | | |
| `settings:read` | ❌ | ❌ | ❌ | ✅ |
| `settings:write` | ❌ | ❌ | ❌ | ✅ |
| **report** | | | | |
| `report:read` | ❌ | ✅ | ✅ | ✅ |
| `report:export` | ❌ | ❌ | ❌ | ✅ |

## 4. Scopes

| Scope | Description | Exemple |
|-------|-------------|---------|
| `self` | Ses propres données | Lire ses commandes |
| `team` | Données de son équipe | Lister les commandes de l'équipe |
| `tenant` | Données de son organisation | Toutes les commandes de l'org |
| `global` | Toutes les données | Admin cross-tenant |

## 5. Règles de sécurité

1. **Deny by default** : tout est interdit sauf autorisation explicite
2. **Moindre privilège** : chaque rôle a le minimum nécessaire
3. **Défense en profondeur** : UI + route guard + API + service + DB
4. **Audit** : chaque action sensible est tracée
5. **Séparation des devoirs** : celui qui configure ≠ celui qui valide

## 6. Implémentation

### JWT Claims
```json
{
  "sub": "user-uuid",
  "tenant_id": "tenant-uuid",
  "realm": "client",
  "roles": ["client"],
  "permissions": ["order:read:self", "order:create"],
  "scope": "self"
}
```

### Middleware
```typescript
// Express / Fastify guard
const requirePermission = (permission: string) => {
  return async (req, res, next) => {
    const user = await getUser(req);
    if (!user.permissions.includes(permission)) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    next();
  };
};

// Usage
app.get('/orders', requirePermission('order:read:self'), listOrders);
```

### Row-Level Security
```sql
-- PostgreSQL RLS
CREATE POLICY user_orders ON orders
    FOR SELECT
    USING (
        tenant_id = current_setting('app.tenant_id')::UUID
        AND (
            current_setting('app.scope') = 'global'
            OR user_id = current_setting('app.user_id')::UUID
        )
    );
```
