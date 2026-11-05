---
name: searxng-mcp
description: >
  Rechercher sur le web, lire les actualités, trouver images et vidéos, et
  extraire le texte lisible d'une page via le serveur MCP `@aplix39/searxng-mcp`
  branché sur une instance SearXNG. Utiliser quand un agent a besoin de sources
  web actuelles, d'une page complète à citer, ou d'un moteur de recherche sans
  clé d'API. Inclut les quotas d'arguments par outil, le contrat de sortie en
  texte, et les erreurs fréquentes (403 format=json, 429 rate limit, moteurs
  muets). Ne PAS utiliser pour des recherches sur des données privées ou pour
  scraper un site qui interdit la lecture automatisée.
license: MIT
compatibility: "Claude Code, Codex, OpenCode, Pi, omp"
allowed-tools: Read Write Glob Grep Bash
user-invocable: true
---

# SearXNG MCP — recherche web pour agent

Tu disposes d'un serveur MCP qui expose une instance SearXNG : sept outils, une
connexion, aucun secret à gérer côté modèle. Ce skill explique comment les
appeler dans le bon ordre, ce que chaque outil exige, et comment lire ce qu'il
renvoie.

## Quand utiliser ce skill

- L'utilisateur demande une information récente, un chiffre, une version, une date
- Il faut citer des sources avec URL, ou vérifier une affirmation
- Il faut lire une page entière (documentation, article, changelog) et en
  extraire le texte lisible
- Il faut des images ou vidéos pour illustrer, ou élargir une requête trop
  étroite avec l'autocomplétion
- L'agent reçoit une erreur `403`, `429` ou un nom de moteur rejeté

## Quand NE PAS utiliser ce skill

- Données privées, internes, ou derrière une authentification : passe par l'outil
  du produit concerné
- Le site interdit la lecture automatisée (robots, paywall) : ne contourne pas,
  demande à l'utilisateur
- Écrire, publier, envoyer quoi que ce soit : ce serveur ne fait que lire
- Calculs, refactorisations, exécution de code : aucun rapport

## Prérequis

`SEARXNG_URL` pointe une instance dont `search.formats` contient `json`. Sans
`json`, l'instance répond `403` et aucun outil ne fonctionne. Vérifier avec
`searxng_config` avant de conclure à une panne.

```bash
claude mcp add searxng \
  --env SEARXNG_URL=https://searx.example.com \
  -- npx -y @aplix39/searxng-mcp
```

Node 18+. Autres variables : `SEARXNG_TIMEOUT_MS` (défaut 30000),
`SEARXNG_BROWSER_URL` (CDP optionnel pour les pages qui exigent JavaScript).

## Les sept outils

| Outil | À quoi il sert | Arguments utiles |
| --- | --- | --- |
| `searxng_search` | Recherche générale multi-moteurs | `q`, `categories`, `engines`, `language`, `pageno`, `time_range`, `safesearch`, `limit`, `include_domains`, `exclude_domains` |
| `searxng_search_news` | Actualité, avec dates de publication | `q`, `language`, `time_range`, `limit`, `include_domains`, `exclude_domains` |
| `searxng_search_images` | Images + vignette | `q`, `language`, `safesearch`, `limit`, `include_domains`, `exclude_domains` |
| `searxng_search_videos` | Vidéos + vignette + page source | `q`, `language`, `time_range`, `limit`, `include_domains`, `exclude_domains` |
| `searxng_autocomplete` | Élargir une requête trop étroite | `q`, `language` |
| `searxng_config` | Instance : URL, langue, catégories, moteurs actifs | `include_engines` |
| `searxng_extract_content` | Texte lisible d'une page | `url`, `content_only`, `selector`, `max_length`, `start_char`, `headings_only`, `include_*` |

`limit` va de 1 à 50, `pageno` de 1 à 50, `time_range` vaut `day`, `week`,
`month` ou `year`, `safesearch` vaut `0`, `1` ou `2`. Les filtres de domaine
s'appliquent après la réponse de l'instance : ils ne peuvent pas être contournés
par un moteur, et ne réduisent pas le coût de la requête.

## Ordre d'appel

1. **Chercher large** : `searxng_search` avec `limit: 5` et un `time_range`
   seulement si la question porte sur du récent.
2. **Lire la meilleure page** : `searxng_extract_content` sur l'URL la plus
   prometteuse, avec `max_length: 40000`. C'est là que se trouvent les faits
   citables, pas dans les extraits.
3. **Croiser** : une deuxième recherche avec `include_domains` sur les sources
   qui font autorité pour le sujet.
4. **Élargir** : si moins de trois résultats pertinents, `searxng_autocomplete`
   puis relancer avec une formulation voisine.

Chaque appel coûte un aller-retour vers l'instance : ne boucle pas. Deux
recherches et une extraction suffisent pour répondre à la plupart des questions.

## Contrat de sortie

Les outils renvoient du **texte Markdown**, pas du JSON :

```
# Search results ("query")
N of M results

## Results

1. Titre
   https://…
   Extrait de 300 caractères…
   (engines: google cse | category: general | published: 2026-10-31)

Note: some engines did not respond: brave (Suspended: too many requests)
```

- `N of M` indique la page courante ; pour la suite, `pageno: 2` plutôt qu'un
  `limit` plus grand.
- La ligne `Note:` nomme les moteurs muets : la réponse est partielle, dis-le
  quand ça compte.
- Les champs absents (score, `parsed_url`, HTML brut) sont retirés exprès : ne
  les demande pas, ils ne reviendront pas.

## Erreurs fréquentes

| Symptôme | Cause | Correctif |
| --- | --- | --- |
| `403` sur tous les outils | `json` absent de `search.formats` | Activer `json` côté instance, redémarrer |
| `429 Too Many Requests` | Limiteur de l'instance ou instance publique | Espacer, baisser `limit`, ou passer sur son instance |
| Nom de moteur rejeté | Moteur désactivé sur cette instance | `searxng_config` pour lister les moteurs actifs |
| Extraction vide | Page rendue en JavaScript, ou redirection | `SEARXNG_BROWSER_URL`, ou lire la page de destination |
| Résultats hors sujet | Requête trop longue ou `time_range` trop court | Raccourcir, retirer `time_range`, `include_domains` |

## Validation

Avant de conclure qu'une recherche a échoué :

- `searxng_config` répond → l'instance est joignable, le problème est la requête
- Un `429` n'est pas une panne : réessaie après un délai, ou réduis la cadence
- Un résultat vide sur une instance publique est fréquent : reformule une fois,
  puis dis à l'utilisateur que l'instance n'a rien renvoyé
- Toute affirmation factuelle doit venir d'une URL effectivement ouverte par
  `searxng_extract_content`, pas d'un extrait de résultat
