# English pronunciation — what espeak gets wrong, and the fixes

The default English voice is `en_GB-alan-medium`, phonemised with espeak-ng
`en-gb-x-rp`. RP uses `ɒ` (lot), `ɑː` (father), `ɜː` (nurse), `ə` (comma), `ɐ`
for many final -er endings, and lexical stress is marked with `ˈ` before the
stressed syllable. Always confirm a symbol against the target voice:

```bash
scripts/piper-tts.py -l en --check "phrase you want to check"
```

## Homographs: the big failure mode

espeak does not parse syntax. It picks one reading per word and keeps it, so a
verb can come out with the noun's vowel (or the noun's stress). There is no
dictionary override — inject the IPA in a `[[ ]]` block, or rewrite the word.

| Word | Reading 1 | Reading 2 | Force it with |
|------|-----------|-----------|---------------|
| close | `kləʊs` adj | `kləʊz` verb | `[[klˈəʊz]] the door` |
| use | `juːs` noun | `juːz` verb | `[[jˈuːz]] it` |
| house | `haʊs` noun | `haʊz` verb | `[[hˈaʊz]] them` |
| lead | `liːd` verb/noun | `led` metal | `[[lˈed]] pipes` |
| read | `riːd` present | `red` past | `[[ɹˈed]] it yesterday` |
| live | `lɪv` verb | `laɪv` adj | usually right already |
| record | `ˈrekɔːd` noun | `rɪˈkɔːd` verb | `[[ɹɪkˈɔːd]] a video` |
| present | `ˈpreznt` noun/adj | `prɪˈzent` verb | `[[pɹɪzˈent]] the plan` |
| produce | `ˈprɒdjuːs` noun | `prəˈdjuːs` verb | `[[pɹədjˈuːs]]` |
| project | `ˈprɒdʒekt` noun | `prəˈdʒekt` verb | `[[pɹədʒˈekt]]` |
| object | `ˈɒbdʒɪkt` noun | `əbˈdʒekt` verb | `[[əbdʒˈekt]]` |
| subject | `ˈsʌbdʒɪkt` noun | `səbˈdʒekt` verb | `[[səbdʒˈekt]]` |
| contract | `ˈkɒntrækt` noun | `kənˈtrækt` verb | `[[kəntɹˈækt]]` |
| content | `ˈkɒntent` noun | `kənˈtent` adj | `[[kəntˈent]]` |
| minute | `ˈmɪnɪt` noun | `maɪˈnjuːt` adj | `[[maɪnjˈuːt]]` |
| wind | `wɪnd` noun | `waɪnd` verb | `[[wˈaɪnd]] the clock` |
| bow | `bəʊ` weapon | `baʊ` greeting | `[[bˈaʊ]]` |
| tear | `tɪə` crying | `teə` ripping | `[[tˈeə]] it up` |
| wound | `wuːnd` injury | `waʊnd` coiled | `[[wˈaʊnd]]` |
| row | `rəʊ` line | `raʊ` argument | `[[ɹˈaʊ]]` |
| bass | `beɪs` instrument | `bæs` fish | `[[bˈæs]]` |
| desert | `ˈdezət` noun | `dɪˈzɜːt` verb | `[[dɪzˈɜːt]]` |
| invalid | `ˈɪnvəlɪd` patient | `ɪnˈvælɪd` not valid | `[[ɪnvˈælɪd]]` |
| resume | `rɪˈzjuːm` continue | `ˈrezjumeɪ` CV | `[[ɹɪzjˈuːm]]` |
| polish | `ˈpɒlɪʃ` verb | `ˈpəʊlɪʃ` from Poland | `[[pˈɒlɪʃ]]` |

The same stress shift hits dozens of two-syllable noun/verb pairs (`increase`,
`import`, `export`, `permit`, `protest`, `survey`, `update`, `upgrade`,
`refund`, `discount`, `insult`, `impact`, `extract`, `escort`, `digest`,
`console`, `conflict`, `convert`, `insert`, `transfer`, `rebel`, `suspect`,
`torment`, `attribute`, `delegate`, `estimate`, `graduate`, `separate`,
`appropriate`, `advocate`, `alternate`). Verb forms are usually stressed on the
last syllable, nouns on the first: if a sentence sounds wrong on one of them,
inject the verb stress.

## Abbreviations and titles

| Input | espeak alone | After normalisation |
|-------|--------------|---------------------|
| `Ms. Smith` | m-ess Smith | `mɪz` Smith |
| `Mr.`, `Mrs.`, `Dr.` | correct | — |
| `Prof.` | "prof" | Professor |
| `No. 5` | "no five" | Number 5 |
| `e.g.`, `i.e.` | correct | — |
| `approx.`, `Dept.` | truncated | approximately, Department |

## Numbers, dates, money

| Input | Becomes |
|-------|---------|
| `10/12/2025` | `12th October 2025` |
| `2025-10-12` | `12th October 2025` |
| `1,000` | read correctly as "one thousand" |
| `3.5` | "three point five" |
| `£5`, `$5`, `5 €` | `5 pounds`, `5 dollars`, `5 euros` |
| `10%` | `10 percent` |
| `R&D` | `R and D` |
| `1st` … `4th`, `10:30` | correct |
| `Henry VIII`, `chapter IV` | `Henry 8`, `chapter 4` |

Dates use the British order (day first). For American output, edit the order in
`en_rules` — one line, in `scripts/piper-tts.py`.

## Words espeak genuinely mispronounces

| Word | Output | Fix |
|------|--------|-----|
| Linux | `lɪnʌks` | `[[lˈɪnəks]]` (in the lexicon) |
| LaTeX | `læteks` | `[[lˈeɪtɛk]]` |
| nginx | letter soup | `engine x` |
| Kubernetes | usually right (`kˌuːbənˈɛtiːz`) | — |
| Ubuntu | right | — |
| SQL | `ess-cue-ell` | fine, or `sequel` |

Proper nouns and brands follow the same rule as French: check first, respell
second, inject last. Never invent an IPA for a name you have not heard.

## Checking

```bash
scripts/piper-tts.py -l en --check "I [[ɹˈed]] the record deal"
scripts/piper-tts.py -l en -o /tmp/test.wav "Close the door, Ms. Smith."
ffplay -nodisp -autoexit /tmp/test.wav
```
