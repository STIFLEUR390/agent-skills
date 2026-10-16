# Durcissement production Dokploy

Checklist issue du guide officiel
(https://docs.dokploy.com/docs/core/guides/production-hardening).
Implémentable en une après-midi, à revoir trimestriellement.

## 1. Hôte

- [ ] Ubuntu/Debian LTS + `unattended-upgrades`
- [ ] SSH : clés seulement, `PasswordAuthentication no`, `PermitRootLogin no`
      (tester une nouvelle connexion **avant** de fermer la session courante)
- [ ] Fail2Ban/CrowdSec jailé sur SSH
- [ ] Firewall : seuls 22 (ou port custom), 80, 443 ouverts. Port Dokploy UI
      (3000) **jamais** public → derrière Traefik sur un domaine ou VPN
      (Tailscale)
- [ ] **ufw-docker** installé : UFW seul ne protège PAS les ports publiés par
      Docker (iptables bypass)
- [ ] Utilisateur non-root quotidien dans le groupe `docker`

```bash
sudo apt install -y unattended-upgrades fail2ban ufw
sudo ufw default deny incoming && sudo ufw default allow outgoing
sudo ufw allow 22/tcp && sudo ufw allow 80/tcp && sudo ufw allow 443/tcp
sudo ufw enable
# ufw-docker : https://github.com/chaifeng/ufw-docker
```

## 2. Docker engine

- [ ] `/etc/docker/daemon.json` :

```json
{
  "live-restore": true,
  "userland-proxy": false,
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "3" }
}
```

- [ ] Jamais de socket Docker en TCP (2375/2376) — root non authentifié
- [ ] `security_opt: [no-new-privileges:true]` par service (compose/Advanced)
- [ ] Tags d'images **pinnés** en prod, jamais `:latest`
- [ ] Credentials registry dans Dokploy (pas de `docker login` en clair)

## 3. Dokploy

- [ ] 2FA/passkeys pour chaque membre du panel
- [ ] Rôles least-privilege (pas d'Admin par défaut)
- [ ] **Secrets Providers** (Vault, Infisical, AWS SM, Doppler…) plutôt que
      des valeurs brutes en env — valeurs jamais stockées en DB, rotation
      prise au prochain deploy
- [ ] Tokens API : un par intégration, avec expiration, régénérés au départ
      d'un membre
- [ ] Audit Logs (Enterprise) si besoin de traçabilité

## 4. Traefik / TLS

- [ ] HTTPS + redirect automatiques sur chaque domaine (Applications) ;
      pour Compose, ajouter le redirect explicitement via labels si nécessaire
- [ ] **HSTS** via middleware custom (Advanced → Traefik File System) :

```yaml
http:
  middlewares:
    secure-headers:
      headers:
        stsSeconds: 31536000
        stsIncludeSubdomains: true
        stsPreload: true
  routers:
    dokploy-app-router-websecure-1:
      middlewares:
        - secure-headers
      # ... reste du router déjà généré par Dokploy
```

- [ ] **Rate limiting** (idem, même fichier) :

```yaml
http:
  middlewares:
    rate-limit:
      rateLimit:
        average: 100
        burst: 50
```

- [ ] Dashboard Traefik non exposé publiquement
- [ ] **Isolated Deployments** activé par projet (Compose → Utilities)

## 5. Bases de données

- [ ] **Internal Credentials** uniquement ; External Credentials (= port
      publié) seulement si besoin réel, derrière firewall/VPN
- [ ] Backups S3 : chiffrés au repos (SSE-S3/SSE-KMS), credentials scopés
      au bucket. Dokploy ne chiffre pas l'archive elle-même
- [ ] **Test de restauration trimestriel** — un backup non restauré n'est pas
      un backup
- [ ] BDD en named volume si backup via Volume Backups (pas de bind mount)

## 6. Observabilité

- [ ] Logs shipposés hors de la machine (Docker log driver / syslog / shipper)
      — Monitoring cloud-only en self-hosted
- [ ] Alerting : échecs de déploiement + seuils serveur (notification
      provider Slack/email/webhook)
- [ ] Alertes sur anomalies d'auth (bans Fail2Ban, pics 401/403 Traefik)

## Mapping conformité (indicatif)

| Sujet | SOC 2 | ISO 27001:2022 |
|---|---|---|
| Hôte (patch, SSH, firewall) | CC6.1, CC6.6 | A.8.8, A.8.20 |
| Docker engine | CC6.1, CC6.8 | A.8.9, A.8.20 |
| Dokploy 2FA/SSO/RBAC | CC6.1–6.3 | A.5.15, A.8.5 |
| Secrets Providers | CC6.1, CC6.7 | A.8.24, A.8.12 |
| Traefik / TLS / HSTS | CC6.7 | A.8.24, A.8.26 |
| Isolation réseau | CC6.6 | A.8.20, A.8.22 |
| Backups & restauration | A1.2, A1.3 | A.8.13, A.5.29 |
| Logs & alerting | CC7.2, CC7.3 | A.8.15, A.5.24 |
