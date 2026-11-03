---
name: Prose Humanize
description: Rewrite READMEs, documentation, and landing-page copy so it reads like a specific person wrote it rather than a model. Use when drafting or reviewing prose for GitHub, docs sites, or marketing pages, or when the user says text sounds like AI, sounds generic, or feels hamfisted.
---

# Prose Humanize

Fix AI-sounding prose. The problem is almost never vocabulary. It is that the
text has no specifics in it and is built out of rhetorical shapes that only
exist to fill space.

## Order of operations

Work in this order. Each step makes the next one smaller, and step 1 alone
fixes most drafts.

### 1. Delete

Cut, without replacement:

- Recaps. "In summary", "In conclusion", "Overall", "Ultimately" — and the
  whole paragraph under them. The reader was there.
- Sign-offs. "We hope this helps", "Happy coding", "Together, let's build".
- Throat-clearing. "In today's fast-paced landscape", "When it comes to",
  "It's important to note that", "It's worth mentioning".
- Boosterism sections. "Why X?", "Awards and recognition", "Future outlook",
  "Despite these challenges". If the product is good, the features say so.
- Any sentence that restates the previous one in a grander register.
- The last sentence of a paragraph that begins with "This" and summarizes.

### 2. Replace abstraction with a number or a name

This is the step a model can do badly and a human must do. Every claim that
could be measured gets measured, and every vague actor gets named.

| Abstract | Concrete |
|---|---|
| "significantly faster" | "40% faster on cold starts (bench/cold.js)" |
| "experts recommend" | the actual person, or delete the claim |
| "robust error handling" | "retries 3 times with jittered backoff, then surfaces the original error" |
| "scales horizontally" | "add replicas; no shared state outside Postgres" |
| "a comprehensive solution" | the two things it actually does |

If you do not know the number, write `TODO: number` and say so. Do not
substitute an adjective.

### 3. Fix the rhetoric

These are the shapes that read as machine-written. Each has a plain
replacement.

**Negative parallelism.** "It's not just a cache, it's a platform."
"Not only X but Y." "No config, no setup, just code." State what it is.
One sentence, one claim.

**Copula inflation.** "serves as", "stands as", "acts as", "functions as",
"represents" → "is". "boasts", "features", "offers", "maintains" → "has" or the
concrete verb. Architectural writing earns "provides". A README rarely does.

**Participial tails.** Any sentence ending in `, highlighting...`,
`, underscoring...`, `, ensuring...`, `, reflecting...`, `, fostering...`,
`, showcasing...`. The clause after the comma is always the same move: it
asserts significance without adding information. Delete it. If the point
matters, give it its own sentence with a fact in it.

**Importance puffery.** "crucial", "pivotal", "vital", "essential", "key" in
front of a noun. If it were crucial you would not need to say so. Delete the
adjective and see if the sentence still has weight.

**The tricolon reflex.** Three adjectives, three parallel verbs, three
examples, every time. Vary the count. Two is fine. Four is fine. Three every
single time is a signature.

**Rule-of-three headings and bullet parallelism.** Not every list needs five
items, and not every item needs an em-dash gloss.

**Colon reveals.** "The best part: it's fast." "Here's the thing:". Say the
thing.

**Weasel attribution.** "Industry reports suggest", "observers have noted",
"studies show". Name the study or drop the sentence.

### 4. Vary the rhythm

Sentence length is the most reliable structural signal, and it is the one a
human notices without being able to name. Model prose clusters at 15–25 words
with low variance. Human technical prose swings hard.

Read the draft and find three consecutive sentences of similar length. Make one
four words. Let one run long with a subordinate clause. Then check the
paragraph openings — if four paragraphs start with a clause, cut two.

Also: a short sentence after a long one is the single most human-looking move
available. Do not overuse it into a gimmick.

### 5. Vocabulary, last and least

Only after the above. The usual suspects: delve, tapestry, testament, robust,
seamless, leverage, comprehensive, intricate, meticulous, crucial, pivotal,
vibrant, landscape, journey, realm, unlock, empower, elevate, foster, garner,
underscore, showcase, boast, nestled, groundbreaking.

Fix them by deleting the word, not by swapping in a synonym. "Robust" is
usually "it retries" written as an adjective.

Two words worth keeping: `is` and `has`. They are not weak. Inflated
substitutes are.

## Verify

Run the linter. It catches what you will miss, and it does not drift.

```bash
vale README.md
```

Expect false positives, especially on literal uses ("the cache does not survive
a restart" is not a mortality metaphor). A rule that misfires on your domain
should be disabled in `.vale.ini`, not worked around in the prose.

Aim for zero on a clean document. Do not aim for zero on a document about
caching, cascades, or mortality without tuning.

Then read the result aloud. Anywhere you run out of breath or hear a rhythm
you would not say, cut.

## Do not

- Add typos, slang, or "honestly," "look," or "so," to simulate a person. That
  reads as a different costume, and worse.
- Randomize word choice to defeat a detector. The point is that the text is
  better, not that a classifier scores it lower.
- Add hedges to seem humble. "I think", "arguably", "it could be said" all
  weaken a claim you should either make or drop.
- Inflate a rewrite with new facts you cannot source. If a claim needs a
  number, mark it and ask.
- Rewrite into a house voice. Match the author's existing register, or the
  surrounding documents'.

## What good looks like

Machine:

> FastCache is a lightweight, robust, and highly performant caching library
> designed to seamlessly integrate with your existing infrastructure. It serves
> as a testament to the power of modern software engineering.

Human:

> An in-memory cache for Node with TTL eviction and a 40MB default cap. It
> speaks the same API as `node-cache`, so swapping it in is a one-line change.

The difference is not the adjectives. The second one says what it is, what
platform it runs on, what its default limit is, and what swapping costs you.
