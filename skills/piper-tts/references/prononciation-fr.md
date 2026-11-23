# Prononciation française — ce qu'espeak rate, et comment le corriger

Ce fichier est le dictionnaire de pièges du skill : ce qu'aucune règle
automatique ne peut deviner (homographes, noms propres, sigles), et la façon de
le corriger sans casser le reste. Les formes IPA sont celles de
`fr_FR-siwis-medium` (Piper 1.8.0), vérifiables avec
`scripts/piper-tts.py -l fr --check "texte"`.

## Lire l'IPA du modèle

| Symbole | Son | Exemple |
|---------|-----|---------|
| `a` | a antérieur | patte |
| `ɑ` | a postérieur | pâte, pas |
| `e` | é fermé | été |
| `ɛ` | è ouvert | père, fête |
| `i` `y` `u` | i, u (tu), ou | lit, lune, loup |
| `o` `ɔ` | o fermé, o ouvert | beau, botte |
| `ø` `œ` | eu fermé, eu ouvert | peu, peur |
| `ə` | e muet | le |
| `ɑ̃ ɔ̃ ɛ̃ œ̃` | voyelles nasales (tilde combiné) | an, on, in, un |
| `ʁ` | r français | rue |
| `ɥ` | u consonne | huit, lui |
| `ʃ ʒ ɲ ŋ` | ch, j, gn, ng | chat, jeu, agneau, camping |
| `ˈ ˌ` | accents toniques | devant la syllabe |

Le texte d'un bloc d'injection est pris **littéralement** : les symboles
n'ont pas besoin d'être parfaits, mais un symbole absent du modèle
(`phoneme_id_map`) est ignoré silencieusement. `--check` signale ces symboles.

## Graphies piégeuses

| Orthographe | Attendu | Ce que fait espeak seul | Correctif |
|-------------|---------|-------------------------|-----------|
| `cuillère`, `aiguille`, `orgueil`, `accueil` | `ɥ` après `g`/`qu` | `y` (ku-yère) | `[[kɥijˈɛʁ]]` en lexique |
| `fille`, `ville`, `mille` | `fij`, `vil`, `mil` | souvent juste | vérifier au `--check` |
| `famille`, `travail`, `ailleurs` | `ij`, `aj`, `ajœʁ` | juste en général | — |
| `pneu`, `œil`, `œuf`, `sœur` | `pnø`, `œj`, `œf`, `sœʁ` | dépend du caractère `œ` | écrire `oe` si le son sort mal |
| `poêle`, `moelle`, `tranquille` | `pwal`, `mwal`, `tʁɑ̃kil` | globalement juste | — |
| `gn` (`agneau`, `montagne`) | `ɲ` | parfois `gn` | `[[aɲˈo]]` |
| `ti` (`attention`, `nation`) | `sjɔ̃` | juste en général | — |
| `um` final (`parfum`, `brun`) | `œ̃` | parfois `um` | `[[paʁfˈœ̃]]` |
| `x` (`examen`, `soixante`, `deux`) | `ɡz`, `s`, muet | variable | `[[ɛɡzamˈɛ̃]]` |
| `s` intervocalique (`maison`) | `z` | juste | — |
| `ent` final (`ils parlent`) | muet | juste | — |
| `-er` final (`parler`) | `e` | juste | — |

## Homographes : le sens change le son

espeak n'analyse pas la syntaxe : il choisit une lecture et s'y tient. Pour un
homographe, écrire la forme qui lève l'ambiguïté, ou injecter l'IPA.

| Mot | Lecture 1 | Lecture 2 | Comment forcer |
|-----|-----------|-----------|----------------|
| `fils` | `fis` (enfant) | `fil` (brins) | 2ᵉ sens : écrire `fils de fil` n'aide pas → `[[fil]]` |
| `tous` | `tus` (pron.) | `tu` (adjectif) | `[[tu]] les jours` |
| `plus` | `ply` (comparatif) | `plys` / `ply` (négation) | `[[plys]]` pour « ne… plus » insistant |
| `os` | `ɔs` (sing.) | `o` (pluriel) | `[[o]]` pour « les os » |
| `est` | `ɛ` (verbe) | `ɛst` (vent d'est) | contexte suffit en général |
| `et` | `e` | — | juste |
| `gens` | `ʒɑ̃` | — | juste |
| `pays` | `pei` | — | vérifier |
| `cinq` | `sɛ̃k` | `sɛ̃` (devant consonne) | `[[sɛ̃k]]` pour insister |
| `sept` | `sɛt` | — | juste |
| `août` | `ut` | — | juste |
| `second` | `səɡɔ̃` | — | juste |
| `automne` | `otɔn` | — | juste |
| `femme` | `fam` | — | juste |
| `monsieur` | `məsjø` | — | juste |

## Nombres, dates, unités : ce que le script normalise

| Écriture | Devient |
|----------|---------|
| `2e`, `3e`, `10e`, `21e` | `2ème`, `3ème`… (lus « deuxième »…) |
| `1er`, `1re` | `premier`, `première` |
| `2nd`, `2nde` | `second`, `seconde` |
| `XXe`, `IIIe`, `XIV` | `20ème`, `3ème`, `14` (chiffres romains ≤ 100) |
| `01/02/2025`, `2025-02-01` | `premier février 2025` (sans article) |
| `10/12` | `10 décembre` |
| `3.14` | `3,14` (virgule décimale) |
| `5 €`, `12,50 €` | `cinq euros`, `douze euros cinquante` |
| `50 %` | `50 pour cent` |
| `1/2`, `1/4`, `3/4`, `1/3`, `2/3` | `un demi`, `un quart`, `trois quarts`, `un tiers`, `deux tiers` |
| `n° 5`, `N° 5`, `No 5` | `numéro 5` |
| `R&D` | `R et D` |

Ne sont **pas** normalisés : les plages (`18-25 ans` se lit « dix-huit vingt-cinq
ans »), les très grands nombres, les pourcentages négatifs, les unités rares.
Écrire la forme longue à la main dans ces cas.

Unités correctement lues sans correction : `km/h`, `kg`, `m²`, `m³`, `°C`, `min`,
`h`. Écrites à la main en français : `Mo`, `Go`, `To`, `Ko` (le lexique les
remplace par mégaoctets, gigaoctets…).

## Sigles et acronymes

espeak épelle les majuscules correctement en français (`SNCF`, `TGV`, `PDG`,
`RATP`, `CNIL`, `RGPD`, `PDF`, `API`, `GPS`, `SIDA`, `IBM`), et lit comme un mot
ce qui ressemble à un mot (`NATO`, `OTAN`, `UNESCO`).

| Sigle | Ce qui sort | Si ce n'est pas ce qu'on veut |
|-------|-------------|-------------------------------|
| `WC` | déjà corrigé en `vécés` par le lexique | — |
| `IA` | `i-a` (corrigé) | — |
| `UI`, `UX`, `GPU` | lettres (corrigés) | — |
| `IPv6` | `i pé vé sis` (corrigé) | — |
| `VLAN`, `SSD`, `CPU` | variable | `[[ve ɛl a ɛn]]` si besoin |
| `C++` | `cé plus plus` | — |
| `A+` | `a plus` | — |

## Vocabulaire technique : anglicismes déjà corrigés

Les entrées du lexique (`assets/lexicon-fr.json`) avec leur IPA mesuré :

| Mot | Prononciation |
|-----|---------------|
| week-end | `wikɛnd` |
| shopping | `ʃɔpiŋ` |
| camping | `kampiŋ` |
| parking | `paʁkiŋ` |
| streaming | `stʁimiŋ` |
| cloud | `klud` |
| token | `tɔkɛn` |
| fine-tuning | `fajn tjuniŋ` |
| workflow | `wœʁkflo` |
| pull request | `pul ʁikɛst` |
| open source | `ɔpɛn suʁs` |
| Bluetooth | `blytuθ` |
| LinkedIn | `linkɛdin` |
| WhatsApp | `watsap` |
| GitHub | `ɡitœb` |
| Linux | `linœks` |
| Python | `pitɔn` |
| Docker | `dɔkœʁ` |
| Kubernetes | `kubɛʁnɛtɛs` |
| JSON | `ʒizɔn` |
| nginx | `ɛndʒin ɛks` |
| build | `bild` |
| OpenAI | `ɔpɛn eaj` |
| ChatGPT | `ʃat ʒe pe te` |

Bien lus sans correction : smartphone, internet, dataset, commit, merge, deploy,
email (`courriel` est préféré), SQL, PHP, HTML, CSS, JavaScript, API, Wi-Fi,
ChatGPT (`ʃat ʒe pe te` est déjà dans le lexique), Claude, Mistral, Llama.

## Noms propres et marques

Ne jamais inventer un IPA pour un nom propre : le risque est de produire une
prononciation plausible mais fausse. Trois options, dans l'ordre :

1. vérifier ce que le modèle produit (`--check`), et s'en contenter si c'est
   acceptable ;
2. réécrire phonétiquement en français : `Boeing` → `Boing`, `McDonald` →
   `Mac Donalde`, `Uber` → `Oubère` ;
3. injecter l'IPA relevé à l'oreille : `[[ubˈɛʁ]]`.

Les marques qui contiennent des chiffres ou des majuscules collées (`iPhone`,
`3M`, `B2B`) sont les plus fragile : `B2B` sort en « bé deux bé », ce qui est
souvent le but.

## Mesurer, puis corriger

```bash
# 1. voir les phonèmes réels et les symboles absents du modèle
scripts/piper-tts.py -l fr --check "ma phrase piégeuse"

# 2. entendre le résultat
scripts/piper-tts.py -l fr -o /tmp/essai.wav "ma phrase piégeuse"
ffplay -nodisp -autoexit /tmp/essai.wav

# 3. après ajout au lexique, vérifier que rien n'a régressé
scripts/piper-tts.py --self-test
```
