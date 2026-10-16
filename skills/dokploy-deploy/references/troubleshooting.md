# Dépannage Dokploy

## Domaines & Traefik

### Déploiement OK mais domaine inaccessible
1. **Mauvais port** : le Container Port du domaine doit matcher le port réel
   du service (Next.js 3000, Laravel 8000…). Changement de port de l'app =
   mise à jour du domaine.
2. **Onglet Advanced → Ports activé** : interfère avec le domaine. Désactiver
   sauf besoin d'accès IP:port direct.
3. **Let's Encrypt** : le DNS doit pointer vers le serveur **avant** la
   création du domaine. Sinon le cert n'est jamais généré → recréer le
   domaine ou redémarrer Traefik.
4. **App bindée en 127.0.0.1** : passer en `0.0.0.0` (Vite : `host: true`
   dans `server` ET `preview`, idem Astro/Nuxt) puis redeploy.

### Bad Gateway
Causes : port configuré faux, ou app en 127.0.0.1. Mêmes correctifs que ci-dessus.

### 404 sur service Compose / Template
- Applications (Nixpacks/Dockerfile) = Traefik **file provider** : pas de
  redeploy nécessaire après changement de domaine.
- Compose/Templates = **labels Traefik** : **redeploy obligatoire** après
  ajout/modification/suppression de domaine. C'est la cause n°1 des 404.

### Domaine mort alors que tout semble OK
Le **healthcheck** défaillant empêche le service de devenir healthy → jamais
routé. Options : corriger le healthcheck (port/chemin) ou le retirer.

### `use of closed network connection` dans les logs Traefik
Normal au redémarrage de Traefik, pas une erreur.

## Volumes & Mounts

### Fichiers montés vides après 2e déploiement
Le auto-deploy re-clone le repo dans `/code` et les anciens fichiers perdent
leur référence. **Solution** : Advanced → Mounts → File Mount avec le contenu
du fichier, référencé en `../files/<nom>` dans le compose. Ne jamais monter
`./` ou `./config/...` depuis le repo.

### Chemin absolu hôte
`- "/folder:/path"` ❌ → nettoyé pendant les déploiements. Utiliser
`../files/...` (bind) ou named volume.

### Docker Stack : déploiement "done" mais service absent
Swarm rejette les mounts invalides sans message d'erreur visible. Vérifier
**General → Swarm** section pour la vraie erreur.

## Réseau & DNS

- Services d'une même stack qui ne se parlent pas : réseau par défaut
  `dokploy-network` n'est ajouté qu'au service ciblé par un domaine →
  l'ajouter aux autres (`external: true`) ou activer **Isolated Deployments**.
- Un service bindé en 127.0.0.1 est injoignable depuis les autres containers :
  URL interne/`host.docker.internal` (avec `extra_hosts: host-gateway`) à la
  place.

## Builds

### Déploiement bloqué en "running" sans erreur
Presque toujours **RAM insuffisante pendant le build** (prerender, SSR,
bundles lourds) : le build n'échoue pas, il ne finit jamais. Solutions :
- Image pré-buildée (build local + registry) — voir methodes-deploiement.md
- Réduire le build (désactiver source maps, allonger pas le prerender)
- memoryLimit Dokploy : format parfois rejeté (`"3gb"` → "invalid memory
  value") — laisser null si le format échoue

### Nixpacks : `Node.js 18.x has reached End-Of-Life and has been removed`
`NODE_VERSION` est ignoré. Fix : `NIXPACKS_NODE_VERSION = "22"` dans
`nixpacks.toml` `[variables]` (ou `engines.node` / `.nvmrc`). Diagnostic :
`nixpacks plan . | grep nixPkgs`.

### `Cloning Repo ...: ✅` puis échec
Le ✅ s'affiche **avant** le clone réel dans les logs. Ne pas en conclure que
le clone a réussi.

### Push registry coupé ("use of closed network connection")
Connexion longue instable : scinder les grosses couches d'image (< 20 Mo,
COPY sans recouvrement) avant de pousser.

### Mauvais contenu servi malgré push OK
`:latest` périmé qui traîne dans le registry. Comparer
`docker inspect --format '{{.Config.Cmd}}'` de l'image locale et de celle
du conteneur. Toujours tagger immuablement en prod.

## Dokploy instance

- UI injoignable / services core cassés : voir
  https://docs.dokploy.com/docs/core/troubleshooting/instance
- Logs/monitoring vides sur remote servers : voir
  https://docs.dokploy.com/docs/core/troubleshooting/logs-monitoring
- Docker Swarm init / DNS build failures / pools d'adresses :
  https://docs.dokploy.com/docs/core/troubleshooting/networking

## Ordre de diagnostic recommandé

1. Statut déploiement + logs du **build** (erreur visible ?)
2. Logs du **service** (démarrage, exception, port)
3. Port réel vs Container Port du domaine
4. `curl -sI` sur le domaine (code, cert)
5. Healthcheck (onglet Swarm) : unhealthy = service non routé
6. Volumes/mounts si données manquantes
