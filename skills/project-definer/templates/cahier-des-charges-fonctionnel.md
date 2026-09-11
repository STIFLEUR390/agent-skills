# Cahier des Charges Fonctionnel — [Nom du projet]

## 1. Inventaire fonctionnel

### Authentification & comptes

| ID | Fonctionnalité | Priorité | Description |
|----|----------------|----------|-------------|
| AUTH-01 | Inscription email | P0 | Création de compte par email + mot de passe |
| AUTH-02 | Connexion | P0 | Authentification par email + mot de passe |
| AUTH-03 | Mot de passe oublié | P0 | Réinitialisation par email |
| AUTH-04 | SSO / OAuth | P1 | Connexion via Google, GitHub, etc. |
| AUTH-05 | Passkeys | P2 | Authentification sans mot de passe |
| AUTH-06 | MFA | P1 | Double authentification (TOTP, SMS) |
| AUTH-07 | Suppression compte | P0 | Droit à l'oubli RGPD |

### Profil utilisateur

| ID | Fonctionnalité | Priorité | Description |
|----|----------------|----------|-------------|
| PROF-01 | Voir profil | P0 | Afficher les informations du compte |
| PROF-02 | Modifier profil | P0 | Éditer nom, email, avatar |
| PROF-03 | Préférences | P1 | Notifications, langue, thème |

### Cœur métier

| ID | Fonctionnalité | Priorité | Description |
|----|----------------|----------|-------------|
| CORE-01 | ... | P0 | ... |
| CORE-02 | ... | P0 | ... |
| CORE-03 | ... | P1 | ... |

### Notifications

| ID | Fonctionnalité | Priorité | Description |
|----|----------------|----------|-------------|
| NOTIF-01 | Email transactionnel | P0 | Bienvenue, confirmation, alerte |
| NOTIF-02 | Push notification | P1 | Notifications navigateur/mobile |
| NOTIF-03 | In-app | P1 | Notifications dans l'application |

### Administration

| ID | Fonctionnalité | Priorité | Description |
|----|----------------|----------|-------------|
| ADMIN-01 | Dashboard | P0 | Vue d'ensemble des métriques |
| ADMIN-02 | Gestion utilisateurs | P0 | CRUD utilisateurs |
| ADMIN-03 | Paramètres | P0 | Configuration globale |

### Paiements (si applicable)

| ID | Fonctionnalité | Priorité | Description |
|----|----------------|----------|-------------|
| PAY-01 | Paiement PSP | P0 | Intégration Stripe/PayPal/... |
| PAY-02 | Fallback manuel | P1 | Virement, mobile money |
| PAY-03 | Historique | P0 | Liste des transactions |
| PAY-04 | Remboursement | P1 | Processus de remboursement |

## 2. Matrice rôles × permissions

### Realms

| Realm | Description | Audience JWT |
|-------|-------------|--------------|
| client | Utilisateur final | `aud: client` |
| staff | Interne entreprise | `aud: staff` |
| admin | Administrateur technique | `aud: admin` |

### Rôles

| Rôle | Realm | Description |
|------|-------|-------------|
| client | client | Utilisateur standard |
| manager | staff | Gestion des commandes |
| support | staff | Support client |
| admin | admin | Administration complète |

### Permissions

| Permission | client | manager | support | admin |
|------------|:------:|:-------:|:-------:|:-----:|
| `order:read:self` | ✅ | ❌ | ✅ | ✅ |
| `order:read:all` | ❌ | ✅ | ✅ | ✅ |
| `order:validate` | ❌ | ✅ | ❌ | ✅ |
| `order:refund` | ❌ | ❌ | ✅ | ✅ |
| `user:read` | ❌ | ❌ | ✅ | ✅ |
| `user:delete` | ❌ | ❌ | ❌ | ✅ |
| `payment:review` | ❌ | ✅ | ❌ | ✅ |
| `payment:approve` | ❌ | ❌ | ❌ | ✅ |
| `settings:write` | ❌ | ❌ | ❌ | ✅ |

### Scopes

| Scope | Description |
|-------|-------------|
| `self` | Ses propres données uniquement |
| `team` | Données de son équipe |
| `tenant` | Données de son organisation |
| `global` | Toutes les données |

## 3. Visibilité des fonctionnalités

| Fonctionnalité | Front office | Back office | Console admin |
|----------------|:------------:|:-----------:|:-------------:|
| Inscription/Connexion | ✅ | ❌ | ❌ |
| Profil utilisateur | ✅ | ❌ | ❌ |
| Cœur métier | ✅ | ✅ | ❌ |
| Gestion utilisateurs | ❌ | ✅ | ✅ |
| Paramètres globaux | ❌ | ❌ | ✅ |
| Dashboard métriques | ❌ | ✅ | ✅ |
| Paiements | ✅ | ✅ | ✅ |

## 4. Flux utilisateur critiques

### Flux 1 : [Nom du flux]
```
Utilisateur → [Étape 1] → [Étape 2] → [Étape 3] → Résultat
```

### Flux 2 : [Nom du flux]
```
Utilisateur → [Étape 1] → [Étape 2] → [Étape 3] → Résultat
```
