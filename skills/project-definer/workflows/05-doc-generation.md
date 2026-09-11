# Phase 5 — Génération des documents

## Objectif
Assembler tous les documents, valider la cohérence, et proposer les prochaines étapes.

## Prérequis
Phases 1 à 4 validées.

## Instructions

### 5.1 — Valider la cohérence

Vérifier que tous les documents sont cohérents entre eux :
- Le périmètre du PRD correspond aux exigences fonctionnelles
- L'architecture couvre toutes les fonctionnalités listées
- Les rôles/permissions correspondent aux fonctionnalités
- L'isolation des données est cohérente avec la stratégie multi-tenant
- Les paiements (si applicable) sont couverts par l'architecture

Signaler toute incohérence et demander à l'utilisateur de trancher.

### 5.2 — Générer le récapitulatif (`04-synthese.md`)

```markdown
# Synthèse du projet — [Nom du projet]

## Résumé
[2-3 phrases sur le projet]

## Documents générés
| Document | Description |
|----------|-------------|
| 00-discovery.md | Découverte et contexte |
| 01-cahier-des-charges-fonctionnel.md | Exigences fonctionnelles |
| 02-prd.md | Product Requirements Document |
| 03-architecture.md | Architecture technique |

## Décisions clés
1. [Décision 1] — [Justification]
2. [Décision 2] — [Justification]

## Risques identifiés
| Risque | Impact | Mitigation |
|--------|--------|------------|
| ... | ... | ... |

## Outils disponibles
[Liste des outils vérifiés et leur statut]

## Prochaines étapes
1. [Étape 1]
2. [Étape 2]
3. [Étape 3]
```

### 5.3 — Générer les fichiers

Écrire tous les fichiers dans `docs/projet/` :
- `00-discovery.md`
- `01-cahier-des-charges-fonctionnel.md`
- `02-prd.md`
- `03-architecture.md`
- `04-synthese.md`

### 5.4 — Proposer les prochaines étapes

Selon la nature du projet, suggérer :
- **Création de projet Kaneo** (si disponible)
- **Initialisation du repo** (git init, README, .gitignore)
- **Maquettage** (Figma, wireframes)
- **Sprint planning** (si méthodologie agile)
- **Prototype technique** (spike sur un point critique)

### 5.5 — Résumé final

Présenter à l'utilisateur :
1. La liste des fichiers générés
2. Les décisions clés retenues
3. Les prochaines étapes recommandées
4. La possibilité de ré-exécuter une phase spécifique
