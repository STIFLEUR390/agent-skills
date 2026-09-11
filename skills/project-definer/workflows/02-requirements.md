# Phase 2 — Exigences fonctionnelles

## Objectif
Définir les fonctionnalités, les utilisateurs, les rôles et les permissions.

## Prérequis
Phase 1 validée. Les blocs E et F donnent le contexte multi-utilisateurs.

## Instructions
Pour chaque domaine fonctionnel, identifier les fonctionnalités,
puis construire la matrice rôles × permissions.

## Étape 2.1 — Inventaire fonctionnel par domaine

Pour chaque domaine applicable, lister les fonctionnalités :

### Authentification & comptes
- [ ] Inscription (email, téléphone, SSO)
- [ ] Connexion (mot de passe, passkeys, MFA)
- [ ] Récupération de mot de passe
- [ ] Gestion du profil
- [ ] Suppression de compte (RGPD)

### Cœur métier
- [ ] Identifier les fonctionnalités principales
- [ ] Définir les flux utilisateur critiques
- [ ] État des entités (cycle de vie)

### Notifications
- [ ] Email transactionnel
- [ ] Push mobile
- [ ] In-app
- [ ] Webhooks vers systèmes tiers

### Recherche
- [ ] Recherche plein texte
- [ ] Filtres et tris
- [ ] Autocomplétion

### Administration
- [ ] Gestion des utilisateurs
- [ ] Gestion des contenus
- [ ] Paramètres globaux
- [ ] Dashboard / métriques

### Paiements (si applicable)
- [ ] Processus de paiement PSP
- [ ] Fallback manuel
- [ ] Facturation
- [ ] Remboursements
- [ ] Historique

### Collaboration
- [ ] Partage
- [ ] Commentaires
- [ ] Édition temps réel
- [ ] Notifications de collaboration

### Rapports & exports
- [ ] Dashboards
- [ ] Export CSV / Excel
- [ ] Export PDF
- [ ] Rapports programmés

## Étape 2.2 — Matrice rôles et permissions

Pour chaque rôle identifié, définir (utiliser `templates/roles-permissions.md`) :

### Realms

| Realm | Description | Authentification |
|-------|-------------|------------------|
| client | Utilisateur final | Inscription libre |
| staff | Interne entreprise | Invitation |
| admin | Administrateur technique | Création manuelle |

### Permissions

Format : `resource:action:scope`

Exemples de permissions :
- `order:read:self` — Lire ses propres commandes
- `order:read:all` — Lire toutes les commandes
- `order:validate` — Valider une commande
- `order:refund` — Rembourser une commande
- `user:read` — Lire les infos utilisateurs
- `user:delete` — Supprimer un utilisateur
- `payment:review` — Revoir un paiement
- `payment:approve` — Approuver un paiement
- `settings:write` — Modifier les paramètres

### Scopes

| Scope | Description |
|-------|-------------|
| `self` | Ses propres données uniquement |
| `team` | Données de son équipe |
| `tenant` | Données de son organisation |
| `global` | Toutes les données |

## Étape 2.3 — Isolation des données

Utiliser `templates/data-isolation.md` pour définir :

- **Niveau d'isolation** : par utilisateur, par tenant, par organisation
- **Mécanisme** : row-level security, filtrage applicatif, schémas séparés
- **Résolution du tenant** : JWT, session, path, sous-domaine, header

## Étape 2.4 — Visibilité des fonctionnalités

Classer chaque fonctionnalité :

| Fonctionnalité | Front office | Back office | Console admin |
|----------------|:------------:|:-----------:|:-------------:|
| ... | ✅/❌ | ✅/❌ | ✅/❌ |

## Livrable
Générer `docs/projet/01-cahier-des-charges-fonctionnel.md` avec :
- Tableau des fonctionnalités par domaine
- Matrice rôles × permissions complète
- Schéma d'isolation des données
- Répartition front/back/admin
