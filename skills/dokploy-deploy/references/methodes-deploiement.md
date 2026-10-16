# Méthodes de déploiement Dokploy

Dokploy expose 4 familles de déploiement. Bien choisir dès le départ évite
les migrations douloureuses.

## 1. Applications (service unique)

Une Application = un service/conteneur. Providers de build :

| Provider | Quand | Notes |
|---|---|---|
| **Dockerfile** | Le repo a un Dockerfile | Chemin build configurable (monorepo) |
| **Nixpacks** | Node/Python/Go sans Dockerfile | Version Node via `NIXPACKS_NODE_VERSION` (jamais `NODE_VERSION`) |
| **Buildpacks** | Mêmes cas que Nixpacks | Alternative less used |
| **Docker Registry** | Build local + push, ou image tierce | Solution des builds trop gourmands pour le VPS |
| **Dockerfile + Deploy (compose interne)** | Compose perso autour d'une app | Cas avancés |

**Bases d'images** : toujours privilégier une variante **slim/alpine**
(`node:22-alpine`, `python:3.12-slim`, `php:8.4-fpm-alpine`, `postgres:16-alpine`…)
pour réduire la taille des images stockées sur le serveur. Passer à la version
complète (debian, `node:22`…) **uniquement si nécessaire** : dépendances
système lourdes, glibc requis, outils absents de l'variant minimal (alpine :
penser à `apk add --no-cache <outil>` pour curl, bash, etc.).

Options clés (onglet General) :
- **Branch** : doit correspondre à la branche poussée (sinon `Branch Not Match`)
- **Build Path** : sous-dossier du repo (monorepos)
- **Auto Deploy** : GitHub = zéro config ; GitLab/Bitbucket/Gitea = ajouter le
  Webhook URL (visible dans les logs de déploiement) dans les settings du repo
- **Watch Paths** : ne redeployer que sur certains chemins
  (`["apps/api/**"]`). GitHub : out-of-the-box ; autres providers : auto-deploy
  requis au préalable.

Advanced :
- **Cluster Settings** : replicas + registry cible
- **Swarm Settings** : Health Check + Update Config (voir rollback-verification.md)
- **Resources** : CPU/mémoire
- **Volumes** : Volumes (named), Binds, File Mounts
- **Traefik File System** : config routing par fichier (Applications uniquement)

## 2. Docker Compose

Le fichier `docker-compose.yml` vit dans le repo (ou l'éditeur Dokploy).
Structure interne :

```
/application-name/
  /code   ← clone du repo (nettoyé à chaque deploy)
  /files  ← File Mounts + bind mounts cibles
```

### Environnement

Les variables saisies dans l'UI sont écrites dans un `.env` à côté du compose,
**pas injectées** dans les containers. Deux choix :

```yaml
services:
  app:
    env_file:
      - .env        # tout injecter
    environment:
      - DATABASE_URL=${DATABASE_URL}   # ou ciblé
```

### Domaines

Depuis v0.7.0, **méthode recommandée** : onglet Domains de l'application
Compose. Dokploy injecte les labels Traefik et le réseau automatiquement au
déploiement (bouton **Preview Compose** pour voir le rendu final).

⚠️ **Toute modification de domaine nécessite un redeploy** (labels lus au
démarrage du conteneur) — contrairement aux Applications qui utilisent le
Traefik file provider.

Alternative manuelle (contrôle total) :

```yaml
services:
  frontend:
    expose:
      - 3000                      # expose, pas ports
    networks:
      - dokploy-network
    labels:
      - traefik.enable=true
      - traefik.http.routers.frontend-app.rule=Host(`frontend.example.com`)
      - traefik.http.routers.frontend-app.entrypoints=web
      - traefik.http.services.frontend-app.loadbalancer.server.port=3000

networks:
  dokploy-network:
    external: true
```

Sans Isolated Deployments, seul le service sélectionné dans le domaine rejoint
`dokploy-network` — l'ajouter manuellement aux autres services si inter-services
nécessaires.

### Ports : expose vs ports

```yaml
ports:
  - 3000:3000    ❌ conflits, expose le port sur l'hôte, interfère avec les domaines
  - 3000         ✅ équivalent expose pour Compose
expose:
  - 3000         ✅ (Docker Stack : c'est la seule bonne syntaxe)
```

Avec **Docker Stack**, les ports sont exposés automatiquement : utiliser
`expose`, ne jamais mettre `ports`.

### Commande custom (Advanced → Command)

Remplace **intégralement** la commande par défaut (affichée dans l'UI),
elle commence toujours par `docker`. Exemple :
`compose -p <app> -f <compose-path> up -d --build --remove-orphans --force-recreate`
→ exécutée `docker compose ...`.

### Volumes

```yaml
volumes:
  - "../files/my-config:/etc/app/config"   ✅ bind via File Mounts
  - mondata:/var/lib/app                   ✅ named volume (backup S3 possible)
  - "/folder:/path"                        ❌ chemin absolu hôte, nettoyé
  - "./config:/etc/app"                    ❌ du repo = vidé après re-clone
```

- **Named volumes** : obligatoires pour les Database/Volume Backups S3.
- **Fichiers du repo** (configs, scripts) : copier leur contenu dans
  Advanced → Mounts (File Mount) et référencer en `../files/...`. Le repo est
  re-cloné à chaque auto-deploy → un mount direct depuis le repo fonctionne
  au 1er déploiement puis est vide.
- **Isolated Deployments** (Compose → Utilities) : un réseau par stack, plus
  besoin de toucher à `dokploy-network`, isolation entre projets.

## 3. Docker Stack (Swarm)

- Pas de `build:` — uniquement des images de registry (build à part).
- Labels Traefik sous `deploy.labels`.
- Registry privé : ajouter `--with-registry-auth` à la commande custom,
  sinon les nœuds worker échouent au pull (`no such image`,
  `docker authentication failed`).
- Mounts invalides : Swarm refuse le service **sans erreur visible** dans le
  déploiement (qui affiche "done") → vérifier l'onglet General → Swarm.

## 4. Dockerfile seul vs image pré-buildée — critère de choix

Build **sur le VPS** convient si le build tient en < ~2 Go RAM et quelques
minutes (typiquement API/node modeste). Au-delà (prerender Nuxt/Docus, builds
front lourds), le VPS swappe et le build reste "running" indéfiniment sans
jamais échouer → **builder en local** :

```bash
docker build -t USER/app:v1 .
docker push USER/app:v1
```

Puis Provider: Docker Registry, tag `v1` (immuable). Pièges : vérifier le
digest de l'image poussée (un vieux `:latest` peut traîner sur le compte) ;
scinder les grosses couches (< 20 Mo) si le push est coupé
("use of closed network connection").

## 5. Déclencheurs alternatifs (hors push GitHub)

### Webhook
1. Onglet General → activer Auto Deploy.
2. Copier le **Webhook URL** (visible dans les logs de déploiement / Deployments).
3. Le coller dans les webhooks du repo (GitHub, GitLab, Bitbucket, Gitea) ou
   DockerHub (Applications seulement ; le tag poussé doit matcher le tag Dokploy).

### API
```bash
# Lister les applications
curl -X GET "https://dokploy.example.com/api/project.all" \
  -H "accept: application/json" -H "x-api-key: <token>"

# Déclencher un déploiement
curl -X POST "https://dokploy.example.com/api/application.deploy" \
  -H "Content-Type: application/json" -H "x-api-key: <token>" \
  -d '{"applicationId": "<id>"}'

# Rollback
curl -X POST "https://dokploy.example.com/api/rollback.rollback" \
  -H "Content-Type: application/json" -H "x-api-key: <token>" \
  -d '{"rollbackId": "<id>"}'
```

Token créé dans les settings du profil. Utile pour CI/CD externes et scripts.
Le serveur MCP `dokploy` (@dokploy/mcp) expose la même API en outils MCP.

## 6. Preview Deployments

Les Applications supportent des previews de déploiement (onglet Preview) :
environnement de test avant promotion en production. À utiliser pour valider
une branche avant merge.

## Déploiements — bonnes pratiques

- Max 10 déploiements visibles ; l'historique plus ancien se purge.
- Les déploiements **en file** sont annulables (push en rafale), ceux **en
  cours** ne le sont pas.
- Le log `Cloning Repo ...: ✅` s'affiche **avant** le clone réel : ce ✅ ne
  prouve rien, le clone suit.
- Un déploiement qui reste "running" sans erreur = quasi toujours un build
  qui dépasse la RAM, pas un bug Dokploy.
