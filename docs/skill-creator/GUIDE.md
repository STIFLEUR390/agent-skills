# Guide d'utilisation — skill-creator

Créer des skills agents multi-plateformes conformes au standard [Agent Skills](https://agentskills.io).

---

## Installation

Le skill est déjà installé. Vérifiez :

| Agent | Commande |
|-------|----------|
| Claude Code | `/skill-creator` dans le menu `/` |
| Codex | `$skill-creator` |
| OpenCode | `/skill-creator` |
| Pi | `/skill:skill-creator` |
| omp | `/skill:skill-creator` |

---

## Quand l'utiliser

- "Crée un skill pour..."
- "J'ai des instructions que je répète toujours, transforme ça en skill"
- "Ajoute un skill au repo agent-skills"
- "Comment créer un skill ?"
- "Documente ce workflow en skill"

---

## Exemple 1 — Créer un skill minimal

**Demander** :
```
Crée un skill qui formate mon code au commit.
```

**Le skill guide** :

1. **Scope** : Un skill = un job → "formatte le code au commit"
2. **Nom** : `commit-formatter` (minuscules, tirets)
3. **Description** : "Formate le code avant le commit. Utiliser quand l'utilisateur fait un commit."
4. **Structure** : SKILL.md seul (workflow court)

**Résultat** :
```markdown
---
name: commit-formatter
description: >
  Formate le code avant le commit en suivant les conventions du projet.
  Utiliser quand l'utilisateur veut commit du code ou demande un formatage automatique.
license: MIT
compatibility: "Claude Code, Codex, OpenCode, Pi, omp"
user-invocable: true
---

# Commit Formatter

## Quand utiliser
- L'utilisateur veut commit du code
- Le code n'est pas encore formaté

## Quand NE PAS utiliser
- L'utilisateur veut juste voir le diff
- Le code est déjà formaté

## Étapes
1. Lister les fichiers modifiés (`git diff --name-only`)
2. Formater chaque fichier selon les règles du projet
3. Stage les fichiers formatés
4. Créer le commit avec le message fourni

## Validation
- Le code est formaté avant le commit
- Aucun fichier non-stagé ne reste
```

---

## Exemple 2 — Créer un skill standard avec templates

**Demander** :
```
Crée un skill pour créer des migrations de base de données.
Il doit avoir un template de migration et un workflow en 3 phases.
```

**Le skill guide** :

1. **Scope** : Créer des migrations DB
2. **Templates** : Un template de migration SQL
3. **Workflow** : 3 phases (analyse, rédaction, validation)

**Résultat** :
```
skills/db-migrator/
├── SKILL.md
├── templates/
│   └── migration.sql
└── references/
    └── naming-conventions.md
```

**SKILL.md** :
```markdown
---
name: db-migrator
description: >
  Créer des migrations de base de données sûres et réversibles.
  Utiliser quand l'utilisateur veut ajouter/modifier une table, un index,
  ou une contrainte. Ne PAS utiliser pour des requêtes SELECT ou du seeding.
license: MIT
compatibility: "Claude Code, Codex, OpenCode, Pi, omp"
user-invocable: true
---

# DB Migrator

## Quand utiliser
- Ajout/modification/suppression de table
- Ajout/modification d'index
- Ajout/modification de contrainte
- Changement de type de colonne

## Quand NE PAS utiliser
- Requêtes SELECT (pas une migration)
- Seeding de données
- Modifications qui cassent le backward compatibility sans version majeure

## Processus

| Phase | Objectif | Livrable |
|-------|----------|----------|
| 1. Analyse | Comprendre le changement demandé | Plan de migration |
| 2. Rédaction | Écrire le SQL | Fichier de migration |
| 3. Validation | Vérifier la sécurité | Checklist passée |

## Phase 1 — Analyse

1. Lire le schéma actuel (`schema.sql` ou equivalent)
2. Identifier les tables affectées
3. Vérifier les dépendances (FK, vues, triggers)
4. Proposer le plan à l'utilisateur

## Phase 2 — Rédaction

Utiliser le template `templates/migration.sql`.

Règles :
- Toujours `UP` + `DOWN` (réversible)
- Pas de `DROP TABLE` sans confirmation
- Index concurrent si possible
- Timestamp dans le nom du fichier

## Phase 3 — Validation

- [ ] Le DOWN fonctionne (rollback testé)
- [ ] Pas de perte de données
- [ ] Index ajoutés pour les FK
- [ ] Le schéma résultant est cohérent

## Templates

Voir `templates/migration.sql` pour le format standard.
```

---

## Exemple 3 — Créer un skill complet avec expertise métier

**Demander** :
```
Crée un skill pour review du code Go. Il doit couvrir la sécurité,
la performance, les patterns Go, et avoir des références pour
chaque pattern.
```

**Le skill guide** :

1. **Scope** : Review Go avec expertise sécurité + perf
2. **References** : Docs par pattern
3. **Structure** : Complet avec templates

**Résultat** :
```
skills/go-reviewer/
├── SKILL.md
├── templates/
│   ├── review-checklist.md
│   └── findings.md
└── references/
    ├── security-patterns.md
    ├── performance-patterns.md
    ├── concurrency-patterns.md
    └── error-handling.md
```

---

## Exemple 4 — Transformer des instructions existantes en skill

**Demander** :
```
Je répète toujours ces instructions dans mes PRs :
- Vérifier les tests
- Lancer le linter
- Update le README si besoin
- Pas de console.log en prod
Transforme ça en skill.
```

**Le skill guide** transforme la liste en skill structuré :

```markdown
---
name: pr-checklist
description: >
  Checklist de pré-PR. Utiliser quand l'utilisateur va créer ou mettre
  à jour une Pull Request.
license: MIT
user-invocable: true
---

# PR Checklist

## Quand utiliser
- Création de PR
- Mise à jour de PR
- Demande de review

## Checklist

### Avant de pousser
1. [ ] Tests passent (`make test` ou équivalent)
2. [ ] Linter passe (`make lint`)
3. [ ] Pas de `console.log` / `fmt.Println` de debug
4. [ ] Pas de secrets ou credentials en dur

### Dans la PR
5. [ ] README mis à jour si changement d'API/usage
6. [ ] Description de PR complète
7. [ ] Screenshots si UI changée
8. [ ] BREAKING CHANGE documenté si applicable

## Validation
Toutes les cases cochées = PR prête.
```

---

## Exemple 5 — Ajouter un skill au repo agent-skills

**Demander** :
```
Ajoute ce skill au repo et push.
```

**Le skill guide** le workflow complet :

```bash
# 1. Créer le skill dans le repo
mkdir -p ~/Projects/skill-manager/skills/mon-skill

# 2. Écrire SKILL.md
cat > ~/Projects/skill-manager/skills/mon-skill/SKILL.md << 'EOF'
---
name: mon-skill
description: ...
---
# Mon Skill
...
EOF

# 3. Valider
bash ~/Projects/skill-manager/skills/skill-creator/scripts/validate.sh \
  ~/Projects/skill-manager/skills/mon-skill

# 4. Déployer localement
bash ~/Projects/skill-manager/skills/skill-creator/scripts/deploy.sh mon-skill \
  ~/Projects/skill-manager/skills

# 5. Push
cd ~/Projects/skill-manager
git add -A
git commit -m "feat: add mon-skill"
git push
```

---

## Exemple 6 — Valider un skill existant

**Demander** :
```
Valide mon skill project-definer.
```

**Résultat** :
```
🔍 Validation de 'skills/project-definer'...

✅ name: project-definer
✅ name correspond au dossier
✅ description: 180 caractères
✅ 111 lignes (< 500)
✅ Section 'Quand utiliser' présente
✅ Section 'Validation' présente
✅ Section exclusions présente

📁 Vérification des références...
  ✅ workflows/01-discovery.md
  ✅ templates/architecture.md
  ✅ references/multi-tenant-patterns.md

📜 Scripts...
  ✅ check-tools.sh (exécutable)

═══════════════════════════════════
✅ Skill valide (0 avertissements)
```

---

## Bonnes pratiques rappelées

### Description = routing rule

| Mauvais | Bon |
|---------|-----|
| "Aide avec les skills" | "Crée un nouveau skill agent. Utiliser quand l'utilisateur veut créer un skill ou transformer des instructions en skill." |
| "Review du code" | "Revue de code pour correctness et sécurité. Utiliser quand l'utilisateur demande une review de PR ou de diff." |
| "Déploie" | "Déploie l'app sur Vercel. Utiliser quand l'utilisateur veut pousser en production. Ne PAS pour du staging." |

### Un skill = un job

| Mauvais | Bon |
|---------|-----|
| `fullstack-helper` (tout fait) | `api-reviewer` + `db-migrator` + `deployer` (un par job) |

### Progressive disclosure

| Niveau | Taille | Contenu |
|--------|--------|---------|
| SKILL.md | < 500 lignes | Instructions essentielles |
| references/ | Au besoin | Détails, exemples, patterns |
| scripts/ | Si nécessaire | Automatisation déterministe |

---

## Templates disponibles

Le skill fournit 3 templates de SKILL.md dans `templates/` :

| Template | Usage | Quand l'utiliser |
|----------|-------|------------------|
| `skill-minimal.md` | SKILL.md seul | Workflow court, pas de référence |
| `skill-standard.md` | + workflows/templates | Processus en étapes |
| `skill-complet.md` | + expertise métier | Skill avec knowledge base |

---

## Scripts

### validate.sh

Vérifie la conformité d'un skill :

```bash
bash skills/skill-creator/scripts/validate.sh skills/<name>
```

Vérifie :
- Frontmatter valide (name, description)
- Name = nom du dossier
- Description < 1024 chars
- Body < 500 lignes
- Sections recommandées
- Fichiers référencés existent
- Scripts exécutables

### deploy.sh

Déploie un skill vers tous les agents :

```bash
bash skills/skill-creator/scripts/deploy.sh <name> [source-dir]
```

Déploie vers :
- `~/.claude/skills/`
- `~/.agents/skills/`
- `~/.config/opencode/skills/`
- `~/.pi/agent/skills/`
- `~/.omp/agent/skills/`

---

## Références

| Fichier | Contenu |
|---------|---------|
| `references/best-practices.md` | Bonnes pratiques complètes (description, structure, nommage, sécurité) |
| `references/agent-compatibility.md` | Compatibilité multi-agents, frontmatter par agent, invocation |
