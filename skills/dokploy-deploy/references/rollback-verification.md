# Rollback et vérifications Dokploy

Deux mécanismes de rollback complémentaires. Les configurer **avant** le
premier incident, pas pendant.

## 1. Rollback automatique (Docker Swarm, healthcheck)

Se déclenche uniquement quand le **nouveau** déploiement échoue ses health
checks → retour automatique à la version précédente.

### Prérequis
- Une route de santé dans l'app (`/health` → 200).
- `curl` disponible **dans le container** (Alpine ne l'a pas par défaut →
  `apk add --no-cache curl` dans le Dockerfile, ou utiliser un healthcheck
  qui ne dépend pas de curl).

### Configuration (Advanced → Cluster Settings → Swarm Settings)

**Health Check** (adapt le port/chemin) :

```json
{
  "Test": ["CMD", "curl", "-f", "http://localhost:3000/health"],
  "Interval": 30000000000,
  "Timeout": 10000000000,
  "StartPeriod": 30000000000,
  "Retries": 3
}
```

**Update Config** :

```json
{
  "Parallelism": 1,
  "Delay": 10000000000,
  "FailureAction": "rollback",
  "Order": "start-first"
}
```

`start-first` = le nouveau conteneur démarre avant l'arrêt de l'ancien →
zéro downtime si le healthcheck est sain.

### Limites
- Ne rollback que sur **échec de healthcheck**, pas sur "mauvaise version
  mais app vivante".
- Ne revient qu'à la version **immédiatement précédente**.
- Healthcheck défaillant (mauvais port/chemin) = service considéré unhealthy
  → domaine qui ne répond jamais. Dans ce cas : réparer le healthcheck ou le
  retirer.

## 2. Rollback registry (manuel, vers n'importe quelle version)

Chaque déploiement pousse son image dans le registry configuré et Dokploy
associe chaque enregistrement de déploiement à son tag → bouton **Rollback**
sur chaque déploiement de l'historique.

### Prérequis
- Registry configuré dans Dokploy (Docker Hub, GHCR, custom) + credentials.

### Activation
1. Application → **Deployments** → **Rollback Settings**
2. Activer **Rollback**, choisir le registry, **Save**

### Exécution
1. Deployments → choisir la version → **Rollback** → confirmer
2. Patienter (téléchargement de l'image) : le conteneur n'apparaît pas
   immédiatement dans l'onglet Logs.

### API
```bash
curl -X POST "https://dokploy.example.com/api/rollback.rollback" \
  -H "Content-Type: application/json" -H "x-api-key: <token>" \
  -d '{"rollbackId": "<id>"}'
```

## 3. Comparatif

| | Swarm (auto) | Registry (manuel) |
|---|---|---|
| Déclencheur | Échec healthcheck au deploy | Clic humain / API |
| Cible | Version précédente seule | N'importe quelle version |
| Dépend de | Route /health + curl dans l'image | Registry configuré |
| Usage | Filet de sécurité auto | Retour arrière ciblé |

**Recommandation prod : activer les deux.**

## 4. Vérification post-déploiement (checklist)

### Immédiat
- [ ] Statut du déploiement : `done`, pas `running` persistant
- [ ] Logs du service : démarrage propre, pas d'erreur en boucle
- [ ] Onglet Monitoring : CPU/mémoire stables (pas d'OOM en approche)

### Accessibilité
- [ ] `curl -sI https://domaine.tld/` → 200/30x
- [ ] Certificat HTTPS valide (`curl -sI` sans `-k`, pas d'erreur SSL)
- [ ] Redirect HTTP→HTTPS fonctionnel
- [ ] Si changement de domaine récent sur compose : **redeploy fait**

### Fonctionnel
- [ ] Route de santé OK (`/health` ou équivalent)
- [ ] Flux critique testé (login, paiement, API principale)
- [ ] Variables d'env prises en compte (vérifier via un endpoint qui les
      consomme — un site peut afficher 200 avec des variables non injectées)

### Réversibilité
- [ ] Bouton **Rollback** visible sur le déploiement (registry actif)
- [ ] Healthcheck Swarm configuré si zéro downtime attendu
- [ ] Nom de tag d'image connu pour revenir en arrière (images pré-buildées)

### Exemple de vérification curl complète
```bash
DOMAIN=monapp.example.com
curl -sI "https://$DOMAIN/" | head -5          # 200/30x + headers
curl -s "https://$DOMAIN/health"               # corps santé
curl -sv "https://$DOMAIN/" -o /dev/null 2>&1 | grep -E 'subject|expire'  # cert
```

## 5. Nettoyage historique

L'historique garde ~10 déploiements. Les déploiements anciens bloqués en
`running`/`cancelled` se purgent via l'API `compose.clearDeployments` /
`application.clearDeployments` (action destructive → preview/dry-run d'abord).
