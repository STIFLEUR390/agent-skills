---
name: dokploy-deploy
description: >
  Déployer des projets en production sur Dokploy : docker-compose, Dockerfile,
  connexion GitHub, domaines/Traefik, volumes, variables d'environnement,
  rollback (Swarm + registry) et vérifications post-déploiement. Utiliser quand
  l'utilisateur déploie, configure, diagnostique ou fait un rollback d'une
  application sur Dokploy (dokploy.applix.fr ou instance auto-héritée). Inclut les
  erreurs fréquentes (Bad Gateway, 404 domaine, mounts perdus, build trop
  gourmand). Ne PAS utiliser pour administrer l'instance Dokploy elle-même
  (upgrade, users, settings) ni pour d'autres plateformes de déploiement.
license: MIT
compatibility: "Claude Code, Codex, OpenCode, Pi, omp"
allowed-tools: Read Write Glob Grep Bash
user-invocable: true
---

# Dokploy Deploy — Déploiement production sur Dokploy

Tu es un expert en déploiement production sur **Dokploy** (PaaS auto-hérité,
Docker Swarm + Traefik). Ton rôle : configurer et déployer des projets de
façon fiable, avec rollback possible et vérifications systématiques.

## Quand utiliser ce skill

- Déployer un nouveau projet (compose, Dockerfile, image pré-buildée)
- Brancher un repo GitHub avec auto-deploy / watch paths
- Configurer domaines, HTTPS, variables, volumes sur Dokploy
- Diagnostiquer un déploiement échoué ou un site inaccessible
- Mettre en place ou exécuter un rollback
- Durcir une config pour la production (voir `references/production-hardening.md`)

## Quand NE PAS utiliser ce skill

- Administrer l'instance Dokploy (upgrade, membres, settings, registres) hors
  périmètre d'un déploiement
- Déployer hors Dokploy (Vercel, Railway, Forge, VPS nu)
- Problème Docker/Traefik sans rapport avec Dokploy

## Règles d'or (retenues de production)

1. **Ordre imposable : DNS d'abord, domaine Dokploy ensuite.** Créer le domaine
   avant que le A record ne pointe vers le serveur = cert Let's Encrypt jamais
   généré (il faut recréer le domaine ou redémarrer Traefik).
2. **L'app doit écouter sur `0.0.0.0`, jamais `127.0.0.1`** (Vite/Astro/Nuxt
   en dev écoutent en localhost → Bad Gateway garanti).
3. **`ports:` en dur = conflits.** En compose, utiliser `expose:` (ou `ports: - 3000`
   sans mapping) et laisser Traefik/router faire le routing.
4. **Les variables de l'UI ne sont PAS injectées automatiquement** dans les
   containers : elles sont écrites dans un `.env` à côté du compose. Il faut
   `env_file: - .env` ou `environment: - VAR=${VAR}` dans le compose.
5. **Le dossier repo est ré-cloné à chaque auto-deploy** : monter un fichier du
   repo (`./config:...`) fonctionne au 1er déploiement puis devient vide.
   Passer par les File Mounts (Advanced → Mounts) référencés en `../files/...`.
6. **Build trop gourmand (> ~2 Go RAM, prerender/SSR lourd) = build bloqué
   indéfiniment en "running" sans erreur.** Solution : builder en local,
   pousser l'image sur un registry, déployer en image pré-buildée.
7. **Images slim/alpine par défaut.** Base images `alpine` ou `*-slim`
   (`node:22-alpine`, `python:3.12-slim`, `php:8.4-fpm-alpine`…) pour réduire
   la taille des images sur le serveur. Passer à la version complète (debian,
   `node:22`…) uniquement si nécessaire : dépendances système lourdes,
   glibc requis, outils absents de l'variant minimal. Penser à ajouter les
   binaires manquants en alpine (`apk add --no-cache curl`, etc.).
8. **Rollback = healthcheck d'abord, registry ensuite.** Sans healthcheck,
   aucun rollback automatique possible ; sans registry configuré, pas de
   rollback manuel vers n'importe quelle version.

## Vue d'ensemble — choisir la méthode

| Situation | Méthode | Où configurer |
|---|---|---|
| Projet multi-services (app + BDD + worker) | **Docker Compose** | Onglet Compose, fichier du repo ou éditeur |
| App unique, build rapide (Dockerfile) | **Application → Dockerfile** | General → Provider: Dockerfile |
| App Node/Python simple sans Dockerfile | **Application → Nixpacks** | General → Provider: Nixpacks |
| Build lourd (>2 Go RAM, prerender, long) | **Image pré-buildée** (build local + registry) | General → Provider: Docker Registry |
| Haute dispo, replicas, multi-nœuds | **Docker Stack** (pas de `build:` !) | Onglet Stack + images registry |

Détail complet : [`references/methodes-deploiement.md`](references/methodes-deploiement.md).

## Workflow de déploiement

### Étape 1 — Prérequis

- [ ] Repo GitHub existant, branche maître identifiée (`main`/`master`)
- [ ] **DNS : enregistrement A du domaine pointé vers l'IP du serveur** (avant toute création de domaine)
- [ ] Port du service connu (Next/Nuxt : 3000, Laravel/Octane : 8000/…, static : 80 via serveur)
- [ ] `.dockerignore` présent (pas de `.env*`, pas de `node_modules`)
- [ ] Bases d'images **slim/alpine** sauf nécessité contraire (règle d'or 7)

### Étape 2 — Créer le projet et brancher GitHub

1. Project → Create Project → Create Application (ou Compose).
2. Onglet General → **GitHub App** : sélectionner owner/repo, **branche**, build path
   (racine ou sous-dossier pour un monorepo).
3. **Auto Deploy** : activer. Pour GitHub c'est automatique à chaque push sur la
   branche configurée. Pour GitLab/Bitbucket/Gitea : copier le Webhook URL depuis
   les logs de déploiement et l'ajouter dans les settings du repo.
4. **Watch Paths** (optionnel) : ne redéployer que si certains chemins changent
   (ex. `["apps/api/**"]` en monorepo). Fonctionne out-of-the-box avec GitHub.
5. Piège : branche configurée ≠ branche poussée → erreur `Branch Not Match`.

### Étape 3 — Configurer le build

**Dockerfile** : Dockerfile à la racine du repo (ou build path), sinon
préciser le chemin. Vérifier que le service écoute sur `0.0.0.0`. Bases
**slim/alpine** par défaut (règle d'or 7).

**Nixpacks** : forcer la version de Node via `NIXPACKS_NODE_VERSION` (dans
`nixpacks.toml` `[variables]` ou l'onglet Environment). `NODE_VERSION` seul
est ignoré → build sur nodejs_18 retiré de nixpkgs = échec. Diagnostic local :
`nixpacks plan . | grep nixPkgs`.

**Image pré-buildée** (quand le build VPS dépasse la RAM) :
```bash
docker build -t USER/app:v1 .
docker push USER/app:v1        # tag immuable, jamais :latest
```
Puis Provider: Docker Registry dans Dokploy, tag explicite. Vérifier le digest
après pull (un `:latest` périmé qui traîne dans le registry sert du vieux contenu).

### Étape 4 — Variables d'environnement

- Onglet Environment : format `.env` (`KEY=value`). Multiline : entourer de
  doubles quotes `'"-----BEGIN KEY-----..."'`.
- **Injecter** via `env_file: - .env` (tout) ou `environment: - VAR=${VAR}` (ciblé)
  dans le compose. Pour une Application (non-compose), l'injection est automatique.
- Aucun secret dans le repo ; valeurs prod uniquement dans Dokploy.
- Si un endpoint LLM/API est joignable depuis les containers, utiliser l'URL
  directe ; un service bindé en 127.0.0.1 sur le VPS est injoignable depuis
  les containers (utiliser `host.docker.internal` + `extra_hosts: host-gateway`).

### Étape 5 — Domaines

1. Onglet Domains → Add Domain : Host, **Container Port** = port réel du service,
   HTTPS activé, certificat `letsencrypt`.
2. Pour compose, **préférer le Domains natif** (UI) : Dokploy injecte les labels
   Traefik automatiquement. Alternative manuelle : labels Traefik + réseau
   `dokploy-network` (voir template).
3. **Toute modification de domaine sur un service Compose/Template exige un
   redeploy** (labels lus au démarrage). Les Applications (file provider)
   n'ont pas besoin de redeploy.
4. Ne pas utiliser l'onglet Advanced → Ports sauf besoin d'accès IP:port
   direct (cela interfère avec le domaine).
5. Pour les apps derrière Path stripping : Path + Internal Path + Strip Path.

### Étape 6 — Volumes et fichiers

| Besoin | Solution | Anti-pattern |
|---|---|---|
| Donnée persistante (BDD, uploads) | **Named volume** `monvol:/var/lib/…` | chemin absolu hôte ❌ |
| Backup automatisé S3 | Named volume obligatoire (Volume Backups) | bind mount ❌ |
| Config/fichier du repo | **File Mount** (Advanced → Mounts) → `../files/x` | `./config:...` ❌ (vide après re-deploy) |
| Persistance simple, accès fichier | Bind mount `../files/...` | `/folder:/path` absolu ❌ (nettoyé) |

Structure interne : `/application-name/code` + `/application-name/files`.

### Étape 7 — Rollback et santé

À faire **avant** le premier déploiement prod, pas après l'incident :
1. Route `/health` (ou équivalent) retournant 200.
2. Health Check + Update Config (`FailureAction: rollback`, `Order: start-first`)
   dans Advanced → Swarm Settings.
3. Rollback Settings → activer le rollback registry (nécessite un registry
   configuré) pour pouvoir revenir à **n'importe quelle** version.

Détails, JSON exacts et procédure : [`references/rollback-verification.md`](references/rollback-verification.md).

### Étape 8 — Vérification post-déploiement

Checklist complète dans [`references/rollback-verification.md`](references/rollback-verification.md).
En résumé :
- [ ] Déploiement en `done` (pas `running` éternel = build qui bloque)
- [ ] Logs du service : pas d'erreur au démarrage
- [ ] `curl -sI https://domaine.tld/` → 200/30x, certificat valide
- [ ] Pages critiques testées (login, API health, flux principal)
- [ ] Rollback testé ou au moins disponible (bouton Rollback visible)

## Erreurs courantes (top)

| Symptom | Cause racine | Fix |
|---|---|---|
| Bad Gateway | App sur 127.0.0.1 ou mauvais port | `0.0.0.0`, port correct, redeploy |
| 404 domaine (compose) | Labels non appliqués | **Redeploy** après changement de domaine |
| Cert HTTPS absent | DNS non pointé avant création domaine | Recréer domaine / restart Traefik |
| Build "running" sans fin | RAM insuffisante (prerender, build lourd) | Image pré-buildée en local |
| Fichiers montés vides | Repo re-cloné à chaque deploy | File Mounts via `../files/` |
| `nodejs_18` EOL (Nixpacks) | `NODE_VERSION` ignoré | `NIXPACKS_NODE_VERSION` |
| Domaine KO après bonne infra | Healthcheck défaillant bloque le service | Réparer ou retirer le healthcheck |
| Stack: mounts invalides invisibles | Swarm refuse le service sans erreur visible | Onglet General Swarm → vrai message d'erreur |

Pièges complets et diagnostics : [`references/troubleshooting.md`](references/troubleshooting.md).

## Durcissement production

Hôtes, Docker daemon, Traefik (HSTS, rate-limit), BDD (credentials internes,
backups S3 chiffrés, tests de restauration) : checklist dans
[`references/production-hardening.md`](references/production-hardening.md).

## Validation — comment savoir qu'on a fini

- [ ] Push sur la branche configurée déclenche un déploiement automatique
- [ ] Site joignable en HTTPS, redirect HTTP→HTTPS actif
- [ ] Variables lisibles par l'app (endpoint de santé qui les consomme OK)
- [ ] Données persistantes en named volume, backup configuré si BDD
- [ ] Rollback possible (healthcheck + registry activé)
- [ ] Post-deploy checklist passée

## Règles générales

- Tag d'image **immuable** en prod, jamais `:latest`.
- Ne jamais exposer un port host sauf besoin réel ; Traefik route tout.
- Une seule source de vérité pour le routing : UI Domains (compose) ou
  Traefik File System (Applications). Ne pas mélanger labels manuels + UI.
- Annuler les déploiements en file (bouton cancel) quand on push beaucoup ;
  les déploiements en cours ne sont pas annulables.
- MCP `dokploy` disponible (si installé) : API programmatique
  (`application.deploy`, `rollback.rollback`, `project.all`) avec `x-api-key`.
  Webhook et API documentés dans `references/methodes-deploiement.md`.

## Doc officielle

- https://docs.dokploy.com/docs/core/docker-compose
- https://docs.dokploy.com/docs/core/domains
- https://docs.dokploy.com/docs/core/applications/rollbacks
- https://docs.dokploy.com/docs/core/guides/production-hardening
- https://docs.dokploy.com/docs/core/troubleshooting
