# Guide d'utilisation — project-definer

Skill de définition complète d'un projet logiciel, de la découverte à l'architecture.

---

## Installation

Le skill est déjà installé. Vérifiez avec :

| Agent | Commande de vérification |
|-------|--------------------------|
| Claude Code | `/project-definer` dans le menu `/` |
| Codex | `$project-definer` ou mention dans `AGENTS.md` |
| OpenCode | `/project-definer` |
| Pi | `/skill:project-definer` |
| omp | `/skill:project-definer` |

Si le skill n'apparaît pas, relancez une session ou faites `/reload-plugins` (omp).

---

## Quand l'utiliser

Le skill s'active quand vous demandez de **définir, spécifier ou documenter un projet** :

- "Je veux créer une application de X"
- "Lance un nouveau projet"
- "J'ai une idée pour un SaaS de Y, documente-la"
- "Spécifie cette application pour moi"
- "Rédige le cahier des charges de mon projet"

**Ne pas l'utiliser pour** : du code pur, des bug fixes, des revues de PR, de l'architecture technique seule (sans cadrage produit).

---

## Le processus en 5 phases

Le skill guide un interview structuré. Chaque phase produit un document dans `docs/projet/`.

```
Phase 1          Phase 2          Phase 3          Phase 4          Phase 5
Découverte  ──→  Exigences  ──→  PRD        ──→  Architecture ──→  Synthèse
                Fonctionnel                        Technique
```

| Phase | Document produit | Durée estimée |
|-------|-----------------|---------------|
| 1. Découverte | `00-discovery.md` | 5-15 min |
| 2. Exigences | `01-cahier-des-charges-fonctionnel.md` | 10-20 min |
| 3. PRD | `02-prd.md` | 5-10 min |
| 4. Architecture | `03-architecture.md` | 10-20 min |
| 5. Synthèse | `04-synthese.md` | 2-5 min |

**Total** : 30-70 minutes selon la complexité du projet.

---

## Démarrage

### Depuis un projet existant

```
project-definer mon-app
```

ou simplement :

```
Lance project-definer pour mon projet "mon-app"
```

### Depuis zéro

```
J'ai une idée pour une application qui [décrire le problème]. Lance project-definer.
```

Le skill crée automatiquement `docs/projet/` et commence l'interview.

---

## Phase 1 — Découverte

Le skill pose des questions par blocs. Répondez une par une.

### Bloc A — Vision
- Quel problème résout le projet ?
- Qui sont les utilisateurs ?
- Quelle est la valeur unique ?
- Quel modèle économique ?

### Bloc B — Périmètre
- Les 3 fonctionnalités MVP indispensables
- Ce qui est hors périmètre V1
- Contraintes (temps, budget, équipe)

### Bloc C — Technique
- Stack imposée ?
- Systèmes à intégrer ?
- Contraintes réglementaires ?

### Bloc D — Concurrence
- Outils similaires existants ?
- Ce qui plaît / ne plaît pas chez eux ?

### Bloc E — Multi-utilisateurs
- Plusieurs types d'utilisateurs ?
- SaaS multi-tenant ?
- Isolation des données ?

### Bloc F — Paiements
- PSP principal ?
- Fallback manuel nécessaire ?

**Conseil** : les blocs E et F peuvent être ignorés pour un petit projet ou un outil interne.

---

## Phase 2 — Exigences fonctionnelles

Le skill construit avec vous :
1. L'inventaire des fonctionnalités par domaine
2. La matrice rôles × permissions
3. Le schéma d'isolation des données
4. La répartition front / back office / admin

### Conseils
- Soyez **précis** sur les fonctionnalités : "L'utilisateur peut filtrer les commandes par date et statut" > "Recherche de commandes"
- **Priorisez** : P0 = MVP, P1 = shortly after, P2 = plus tard
- Pour les rôles, pensez **realms** : client (externe), staff (interne), admin (technique)

---

## Phase 3 — PRD

Le skill rédige le Product Requirements Document avec :
- Résumé exécutif
- Problème et contexte
- Objectifs mesurables (KPIs)
- Fonctionnalités et non-fonctionnalités
- Risques et dépendances

### Conseils
- Les **KPIs** doivent être mesurables : "Réduire le temps de traitement de 50%" > "Améliorer l'efficacité"
- Les **non-objectifs** sont aussi importants que les objectifs : ils évitent la dérive de périmètre

---

## Phase 4 — Architecture

Le skill définit :
- La stack technique complète
- L'architecture applicative
- La stratégie multi-tenant
- Le workflow de paiement (si applicable)
- Le modèle de données

### Conseils
- **Justifiez** chaque choix : "PostgreSQL car RLS natif pour l'isolation multi-tenant" > "PostgreSQL"
- Pour le multi-tenant, le **mono-base avec tenant_id** est le bon choix par défaut (coût, complexité)
- Les **diagrammes Mermaid** sont générés dans le document pour une visualisation claire

---

## Phase 5 — Synthèse

Le skill :
1. Valide la cohérence entre tous les documents
2. Génère le récapitulatif `04-synthese.md`
3. Propose les prochaines étapes

---

## Templates et références

Chaque phase s'appuie sur des fichiers dans le skill :

### Templates (structures pré-remplies)

| Template | Contenu |
|----------|---------|
| `cahier-des-charges.md` | Structure complète d'un cahier des charges |
| `cahier-des-charges-fonctionnel.md` | Focus fonctionnel et métier |
| `prd.md` | Product Requirements Document |
| `architecture.md` | Architecture technique avec code et Mermaid |
| `roles-permissions.md` | Matrice RBAC + realms + scopes |
| `data-isolation.md` | Patterns multi-tenant et isolation |
| `payments.md` | Paiements, fallback, réconciliation |

### Références (knowledge base)

| Référence | Sujet |
|-----------|-------|
| `modern-app-principles.md` | Socle commun des apps modernes |
| `multi-tenant-patterns.md` | 3 stratégies d'isolation SaaS |
| `roles-realms-scopes.md` | RBAC + ABAC + défense en profondeur |
| `payment-patterns.md` | Fallback PSP, workflow manuel, anti-fraude |

### Utilisation hors du skill

Les templates et références sont utilisables indépendamment. Par exemple, pour créer rapidement une matrice de permissions sans lancer tout le processus :

```
Charge le template roles-permissions.md et adapte-le pour mon projet avec les rôles : client, admin, editor
```

---

## Projets simples vs complexes

Le skill s'adapte automatiquement.

### Petit projet (landing page, outil interne, script)
- Phase 1 : 3-5 questions globales
- Phase 2 : fonctionnalités essentielles uniquement
- Phase 3 : PRD allégé
- Phase 4 : stack simple, pas de multi-tenant
- Phase 5 : récap court

### Projet moyen (app web, SaaS simple)
- Toutes les phases avec profondeur standard
- Multi-tenant optionnel
- Paiements si pertinent

### Projet complexe (SaaS multi-tenant, marketplace, app mobile)
- Toutes les phases en profondeur
- Multi-tenant obligatoire
- RBAC + realms complet
- Paiements avec fallback
- Isolation des données documentée
- Anti-fraude et réconciliation

---

## Erreurs courantes à éviter

1. **Tout définir d'un coup** : le skill pose UNE question à la fois. Suivez le rythme.
2. **Ignorer les non-objectifs** : ils évitent de construire ce qui n'est pas nécessaire.
3. **Rôles vagues** : "admin" n'est pas un rôle, c'est un realm. Les rôles métier sont "manager", "support", "editor".
4. **Oublier l'isolation** : si c'est un SaaS, les données DOIVENT être isolées par tenant.
5. **Pas de KPIs** : sans mesures, on ne sait pas si le projet réussit.
6. **Architecture sans justification** : chaque choix technique doit répondre à un besoin documenté.

---

## Après le skill

Une fois les documents générés dans `docs/projet/`, les prochaines étapes typiques sont :

1. **Initialiser le repo** : `git init`, README, .gitignore
2. **Maquettage** : wireframes, Figma
3. **Sprint planning** : découper en tâches (Kaneo, Linear, GitHub Issues)
4. **Prototype technique** : spike sur le point critique
5. **Re-exécuter une phase** : si un choix change, relancer uniquement la phase concernée

---

## Exemple de session complète

```
Utilisateur : Lance project-definer pour une app de livraison de repas en Côte d'Ivoire

Skill : Quel est le problème que ce projet résout ?

Utilisateur : Les restaurants locaux n'ont pas de moyen simple de proposer la livraison.
             Les clients doivent appeler, c'est lent et peu fiable.

Skill : Qui sont les utilisateurs cibles ?

Utilisateur : Les clients particuliers, les restaurants partenaires, et les livreurs.

[... l'interview continue phase par phase ...]

Skill : Tous les documents sont générés dans docs/projet/. Voici la synthèse :
  - 00-discovery.md : contexte et vision
  - 01-cahier-des-charges-fonctionnel.md : 47 fonctionnalités, 4 rôles
  - 02-prd.md : MVP en 6 semaines, KPIs définis
  - 03-architecture.md : Next.js + PostgreSQL + Paystack + Mobile Money
  - 04-synthese.md : récap et prochaines étapes
```

---

## Emplacements du skill

| Agent | Chemin |
|-------|--------|
| Claude Code | `~/.claude/skills/project-definer/` |
| Codex | `~/.agents/skills/project-definer/` |
| OpenCode | `~/.config/opencode/skills/project-definer/` |
| Pi | `~/.pi/agent/skills/project-definer/` |
| omp | `~/.omp/agent/skills/project-definer/` |

Pour Codex, ajouter dans `AGENTS.md` :
```markdown
## Skills disponibles
- `~/.agents/skills/project-definer/SKILL.md` : Guide interactif de définition de projet.
```
