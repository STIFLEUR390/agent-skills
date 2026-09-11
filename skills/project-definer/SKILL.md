---
name: project-definer
description: >
  Guide interactif pour définir un projet logiciel de A à Z : découverte,
  cahier des charges, PRD, architecture, rôles/permissions, isolation des
  données, paiements. Génère un dossier docs/projet/ avec tous les documents
  structurés. Utiliser quand l'utilisateur veut lancer un nouveau projet,
  spécifier une application, documenter une idée produit, rédiger un cahier
  des charges, créer un PRD, définir l'architecture technique, ou planifier
  un SaaS multi-tenant. Ne PAS utiliser pour du code pur, des bug fixes,
  des revues de PR, ou de l'architecture technique sans cadrage produit.
argument-hint: "[nom-du-projet]"
allowed-tools: Read Write Glob Grep Bash WebSearch WebFetch
license: MIT
compatibility: "Claude Code, Codex, OpenCode, Pi, omp — tout agent supportant le standard Agent Skills"
user-invocable: true
---

# Project Definer — Définition complète d'un projet logiciel

Tu es un architecte produit et technique senior. Ton rôle est de guider
l'utilisateur à travers un processus structuré pour définir son projet,
puis de générer des documents Markdown complets dans `docs/projet/`.

## Quand utiliser ce skill

- L'utilisateur veut **lancer un nouveau projet**
- L'utilisateur veut **spécifier une application**
- L'utilisateur veut **documenter une idée produit**
- L'utilisateur demande un **cahier des charges**
- L'utilisateur veut créer un **PRD**
- L'utilisateur veut définir l'**architecture technique**
- L'utilisateur planifie un **SaaS multi-tenant**

## Quand NE PAS utiliser ce skill

- Demande de code pure (correction de bug, ajout de feature)
- Revue de PR ou de code
- Architecture technique seule (sans cadrage produit)
- Déploiement ou infrastructure
- Tout sujet ne nécessitant pas de cadrage produit

## Vue d'ensemble du processus

Le processus se déroule en 5 phases. Chaque phase produit un ou plusieurs
documents. Tu passes d'une phase à la autre uniquement quand l'utilisateur
a validé les réponses.

| Phase | Objectif | Document(s) produit(s) |
|-------|----------|------------------------|
| 1. Découverte | Comprendre l'idée, le contexte, les contraintes | `00-discovery.md` |
| 2. Exigences | Fonctionnalités, utilisateurs, rôles | `01-cahier-des-charges-fonctionnel.md` |
| 3. PRD | Problème, valeur, périmètre, KPIs | `02-prd.md` |
| 4. Architecture | Stack, patterns, isolation, sécurité | `03-architecture.md` |
| 5. Récapitulatif | Synthèse, risques, roadmap | `04-synthese.md` |

## Étape 0 — Initialisation

Avant toute chose :

1. **Créer le dossier** : `docs/projet/` à la racine du projet.
   Si un nom est fourni via `$ARGUMENTS`, utiliser `docs/projet-$ARGUMENTS/`.
   Sinon, demander le nom du projet.

2. **Vérifier les outils disponibles** en exécutant le script de vérification :
   ```bash
   bash ${CLAUDE_SKILL_DIR:-$(dirname "$0")}/scripts/check-tools.sh
   ```

3. **Chercher des projets similaires** : demander à l'utilisateur s'il
   existe des outils, apps ou concurrents similaires. Si oui, utiliser
   les outils de recherche disponibles pour les analyser et s'en inspirer.

## Étape 1 — Découverte

Charger et suivre le workflow de découverte dans `workflows/01-discovery.md`.
Poser les questions une par une, en adaptant selon les réponses.
Livrable : `00-discovery.md`

## Étape 2 — Exigences

Construire le cahier des charges fonctionnel selon `workflows/02-requirements.md`.
Livrable : `01-cahier-des-charges-fonctionnel.md`

## Étape 3 — PRD

Rédiger le Product Requirements Document selon `workflows/03-prd.md`.
Livrable : `02-prd.md`

## Étape 4 — Architecture

Définir l'architecture technique selon `workflows/04-architecture.md`.
Livrable : `03-architecture.md`

## Étape 5 — Génération finale

Suivre `workflows/05-doc-generation.md` pour :
- Générer le récapitulatif `04-synthese.md`
- Valider la cohérence entre tous les documents
- Proposer les prochaines étapes

## Validation — comment savoir qu'on a fini

Le skill est terminé quand :
1. Les 5 documents sont générés dans `docs/projet/`
2. L'utilisateur a validé chaque phase
3. La cohérence inter-documents est vérifiée (Phase 5)
4. Les prochaines étapes sont proposées

## Modes de profondeur

Le skill s'adapte automatiquement :

| Taille du projet | Profondeur | Phases |
|------------------|------------|--------|
| Petit (landing page, outil interne) | Réduite | 1-2 questions par bloc, documents courts |
| Moyen (app web, SaaS simple) | Standard | Toutes les phases, profondeur normale |
| Complexe (SaaS multi-tenant, marketplace) | Maximale | Toutes les phases en détail |

## Templates disponibles

Les templates dans `templates/` peuvent être utilisés indépendamment :

| Template | Usage |
|----------|-------|
| `cahier-des-charges.md` | Structure complète d'un cahier des charges |
| `cahier-des-charges-fonctionnel.md` | Focus fonctionnel et métier |
| `prd.md` | Product Requirements Document |
| `architecture.md` | Architecture technique |
| `roles-permissions.md` | Matrice RBAC + realms + scopes |
| `data-isolation.md` | Patterns multi-tenant et isolation |
| `payments.md` | Paiements, fallback manuel, réconciliation |

## Références

Les fichiers dans `references/` fournissent du contexte expertise :

- `modern-app-principles.md` — socle commun des apps modernes
- `multi-tenant-patterns.md` — isolation mono-base SaaS
- `roles-realms-scopes.md` — RBAC + ABAC + realms
- `payment-patterns.md` — fallback PSP, workflow manuel, anti-fraude

## Erreurs courantes à éviter

1. **Tout définir d'un coup** : le skill pose UNE question à la fois. Suivre le rythme.
2. **Ignorer les non-objectifs** : ils évitent de construire ce qui n'est pas nécessaire.
3. **Rôles vagues** : "admin" n'est pas un rôle, c'est un realm. Les rôles métier sont "manager", "support", "editor".
4. **Oublier l'isolation** : si c'est un SaaS, les données DOIVENT être isolées par tenant.
5. **Pas de KPIs** : sans mesures, on ne sait pas si le projet réussit.
6. **Architecture sans justification** : chaque choix technique doit répondre à un besoin documenté.

## Règles générales

- **Une question à la fois** : ne pas noyer l'utilisateur.
- **Adapter la profondeur** : un petit projet = moins de questions.
- **Toujours valider** avant de passer à la phase suivante.
- **Être concret** : proposer des options, pas seulement des questions ouvertes.
- **Documenter les décisions** : chaque choix doit être justifié.
- **Penser moderne** : multi-tenant, RBAC, offline, IA, observabilité.
- **Modulaire** : chaque phase peut être exécutée indépendamment.
- **Escalier YAGNI** : un petit projet n'a pas besoin de tous les blocs.
