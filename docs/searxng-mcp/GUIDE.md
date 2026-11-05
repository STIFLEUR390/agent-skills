# SearXNG MCP — guide

Guide de référence pour `skills/searxng-mcp/SKILL.md`. Le SKILL.md suffit pour
un agent ; ce document garde les détails d'installation, le tableau complet des
paramètres et les cas limites d'exploitation.

## Installation

### Claude Code / Cursor / omp

```bash
claude mcp add searxng \
  --env SEARXNG_URL=https://searx.example.com \
  -- npx -y @aplix39/searxng-mcp
```

Configuration JSON équivalente :

```json
{
  "mcpServers": {
    "searxng": {
      "command": "npx",
      "args": ["-y", "@aplix39/searxng-mcp"],
      "env": {
        "SEARXNG_URL": "https://searx.example.com",
        "SEARXNG_TIMEOUT_MS": "30000"
      }
    }
  }
}
```

Sans `SEARXNG_URL`, le serveur interroge `http://localhost:8888`. Une instance
publique ne convient pas : la plupart refusent l'API JSON et répondent `403` ou
`429`. Héberge la tienne.

### Instance auto-hébergée

`settings.yml` doit contenir `json` dans `search.formats` :

```yaml
search:
  formats:
    - html
    - json
```

Sans cette ligne, chaque outil échoue en `403` avec un message explicite.

## Paramètres, outil par outil

Tous les outils acceptent `q` sauf `searxng_config` (`include_engines`) et
`searxng_extract_content` (`url`).

| Paramètre | Type | Bornes | Outils |
| --- | --- | --- | --- |
| `q` | string | — | search, news, images, videos, autocomplete |
| `limit` | number | 1–50 | search, news, images, videos |
| `pageno` | number | 1–50 | search |
| `language` | string | code ISO (`fr`, `en-US`) | search, news, images, videos, autocomplete |
| `time_range` | enum | `day`, `week`, `month`, `year` | search, news, videos |
| `safesearch` | number | 0, 1, 2 | search, images |
| `categories` | string[] | dépend de l'instance | search |
| `engines` | string[] | moteurs actifs | search |
| `include_domains` | string[] | — | search, news, images, videos |
| `exclude_domains` | string[] | — | search, news, images, videos |
| `include_engines` | boolean | — | config |
| `url` | string | http(s) | extract_content |
| `content_only` | boolean | — | extract_content |
| `selector` | string | sélecteur CSS | extract_content |
| `max_length` | number | 500–200000 | extract_content |
| `start_char` | number | ≥ 0 | extract_content |
| `headings_only` | boolean | — | extract_content |
| `include_header` / `include_footer` / `include_navigation` / `include_sidebar` / `include_comments` / `include_links` / `include_images` | boolean | — | extract_content |

### Extraction longue

Une page de documentation dépasse souvent `max_length` par défaut. Deux appels
plutôt qu'un `max_length: 200000` :

1. `headings_only: true` — la table des matières suffit pour choisir
2. `start_char` sur la section retenue, `max_length: 30000`

`content_only: false` conserve titres et listes de navigation ; c'est utile pour
une page de doc, inutile pour un article.

## Lecture des réponses

- `N of M` = position dans la page courante. `M` varie selon les moteurs qui
  ont répondu : ne l'utilise pas comme un total fiable.
- `(engines: …)` indique quels moteurs ont fourni le résultat. Un résultat
  venant d'un seul moteur est plus fragile qu'un résultat recoupé.
- `Note: some engines did not respond: …` = réponse partielle. Mentionne-le si
  l'utilisateur dépend de l'exhaustivité.
- Les images et vidéos renvoient une vignette et une URL de page source ; l'URL
  du média n'est pas toujours directement téléchargeable.

## Diagnostics

```bash
# l'instance répond-elle en JSON ?
curl -s -o /dev/null -w '%{http_code}\n' \
  "https://searx.example.com/search?q=test&format=json"

# quels moteurs sont actifs ?
curl -s "https://searx.example.com/config" | jq '.engines[] | select(.enabled) | .name'
```

- `403` → `json` absent de `search.formats`
- `418` → l'instance bloque les clients non navigateur (botdetection)
- `429` → limiteur (`limiter.toml`) ou instance publique saturée
- `200` en HTML mais `403` en JSON → même cause que `403`

## Alternatives

Ce skill décrit un serveur MCP précis. Pour une recherche sans MCP, l'API HTTP
de l'instance suffit (`/search?format=json`) ; pour une recherche qui exige un
rendu JavaScript, `SEARXNG_BROWSER_URL` fait passer la récupération par un
navigateur piloté en CDP.
