# Phase 1 — Découverte

## Objectif
Comprendre l'idée, le contexte, les contraintes et les objectifs du projet.

## Instructions
Poser les questions **une par une**. Adapter la profondeur selon les réponses :
- Projet simple (landing page, petit outil interne) → raccourcir, fusionner des blocs
- Projet complexe (SaaS, marketplace, app mobile) → suivre chaque bloc complet

## Bloc A — Vision et problème

1. **Quel est le problème que ce projet résout ?** (en une phrase)
2. **Qui sont les utilisateurs cibles ?**
   - Particuliers / Consommateurs
   - Entreprises / Professionnels
   - Usage interne uniquement
3. **Quelle est la valeur unique** par rapport à l'existant ?
4. **Quel est le modèle économique ?**
   - Gratuit
   - Freemium
   - SaaS (abonnement)
   - Marketplace (commission)
   - Licence
   - Interne (pas de monétisation directe)
   - Autre : ___

## Bloc B — Périmètre

5. **Quelles sont les 3 fonctionnalités absolument indispensables (MVP) ?**
6. **Qu'est-ce qui est explicitement hors périmètre pour la V1 ?**
7. **Y a-t-il des contraintes de temps, de budget ou d'équipe ?**
   - Deadline impérative
   - Budget limité
   - Équipe solo / petite / moyenne

## Bloc C — Contexte technique

8. **Y a-t-il une stack imposée ?** (langage, framework, cloud)
9. **Y a-t-il des systèmes existants à intégrer ?** (ERP, CRM, API tierce)
10. **Quelles sont les contraintes réglementaires ?**
    - RGPD (Europe)
    - PCI DSS (paiements)
    - HIPAA (santé)
    - Localisation spécifique
    - Autre : ___

## Bloc D — Similarité et inspiration

11. **Existe-t-il des outils, apps ou concurrents similaires ?**
    - Si oui : lesquels ?
    - Qu'est-ce qui vous plait / ne plait pas chez eux ?
    - Version alternative (autre stack) ?
    - Version allégée / simplifiée ?
    - Version avec de nouvelles fonctionnalités ?

## Bloc E — Multi-utilisateurs et rôles

12. **L'application aura-t-elle plusieurs utilisateurs ?**
    - Si non → passer à la Phase 2
13. **Y aura-t-il plusieurs types d'utilisateurs ?**
    - Client / Utilisateur final
    - Staff / Employé
    - Admin / Super admin
    - Autre : ___
14. **Y aura-t-il plusieurs organisations / tenants ?** (SaaS multi-tenant)
15. **Les données doivent-elles être isolées** par utilisateur ou par tenant ?

## Bloc F — Paiements

16. **Y a-t-il des paiements ?**
    - Si non → passer à la Phase 2
    - PSP principal : Stripe / PayPal / Paystack / Autre
17. **Y a-t-il des pays où le PSP ne fonctionne pas ?**
    - Faut-il un fallback manuel (virement, mobile money, M-Pesa) ?

## Livrable
Générer `docs/projet/00-discovery.md` avec les réponses structurées par bloc.
Utiliser le template `templates/cahier-des-charges.md` comme structure de base.
