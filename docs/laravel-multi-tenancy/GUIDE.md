# Guide d'utilisation — laravel-multi-tenancy

SaaS multi-tenant avec Laravel.

---

## Quand l'utiliser

- Créer un SaaS multi-tenant
- Isoler les données par tenant
- Configurer les teams

---

## Exemple 1 — Tenant Scope

**Demander**：
```
Ajoute un scope pour filtrer les données par tenant.
```

**Le skill génère**：

```php
<?php

trait BelongsToTenant
{
    public static function bootBelongsToTenant(): void
    {
        static::addGlobalScope(new TenantScope);
    }
}

class Post extends Model
{
    use BelongsToTenant;
    // Seuls les posts du tenant courant sont retournés
}
```

---

## Voir aussi

- `laravel-core` — Fondamentaux
- `laravel-security` — Permissions par tenant
