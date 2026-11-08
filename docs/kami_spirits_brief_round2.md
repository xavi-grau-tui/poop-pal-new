# The 120 spirits, round 2: simple, animated, small (brief for the designer, 2026-11-04)

Round 1 (`docs/mockups/spirits/round1/`, brief `docs/kami_spirits_brief.md`) gave us three strong
directions. The ideas were good, but most spirits were **far too detailed** for the space they have
on screen. Shrunk to their real size, the ornaments, patterns and trims turn into noise
(`docs/mockups/spirits/round2_brief/4_round1_too_detailed.png`). My first brief caused part of this:
it asked for "detailed" pixel art on an 80 px canvas, which was too big.

The **babies** were the favourites (`2_target_detail_babies.png`): one simple shape, a clear face,
one idea. **That level of simplicity is the rule for all 120 spirits**, adults and legends included.
Bigger stages get a new, bolder shape, not more detail.

Why it matters:
- **Cartoon animation.** We'll animate every spirit in code: squash-and-stretch breathing, blinks,
  bounces, wobbly ears, eating. That only looks good on soft, simple bodies.
- **Small versions.** Every spirit also appears as a **16 px ball** in the minigames
  (`3_ball_16px_8x.png`), and in other small places (stickers, Paper Sumo).
- **Merchandise.** It must work as a plush, a keychain or a sticker: a clear silhouette, a few
  flat colours, nothing thin that would snap off.
- **The screen.** The spirit gets a small room inside the hokora, the same size the old pals had.

## The format (hard limits)

- **The pixel:** the old pals' pixel, shown 1:1 in `1_canvas_56px_8x.png`. It is a bit bigger than
  the homes' pixel; that's intended (the spirits are the stars).
- **The canvas:** **56 x 56** pixels, transparent. The spirit stands centred, its lowest point on
  row 54 (the baseline).
- **Size by stage** (height in pixels):

| Stage | Height | Width max |
|---|---|---|
| baby | about 30 | 36 |
| kid | about 34 | 40 |
| adult | 38 to 48 | 52 |
| mutant (Tech, Cosmic) | 38 to 48 | 52 |
| legend | 44 to 52 | 54 |

## The detail budget

Every spirit is **body + face + a few features**. "Feature" means one extra element: ears, a flame,
a leaf, a horn, a tail, a mask, a charm, a hat, wings, a shell.

| Stage | Features (besides body and face) |
|---|---|
| baby | 1 |
| kid | 1 to 2 |
| adult | 2 to 3, and a new silhouette, not the kid scaled up |
| mutant | 2 to 3 |
| legend | up to 4 |

And for every spirit:
- **Colours:** 3 main colour areas plus 1 small accent, plus the dark plum outline and the eyes.
  Soft simple shading, 2 to 3 tones per colour, like the babies.
- **No** patterns, prints, trims, gold edging, embroidery, fur strands, feather detail, filigree or
  texture. Nothing thinner than 2 pixels, except the outline.
- **Outline:** 1 pixel, dark plum (#22101A), all round.
- **Face:** large and clear, on the main body (not hidden in a small head). Eyes at least 2 x 3 pixels
  and at least 3 pixels apart. The mouth area is kept free (it opens to eat). Faces can vary: sleepy,
  one big eye, a mask with eye holes, side-eye, grumpy. But each must read at once.
- **Body:** one soft, rounded main mass that can squash and stretch. No rigid armour or long robes
  covering it. Limbs are short stubs, or there are none (the old pals had none). At most 2 loose
  parts that can wobble (ears, a tail, a flame, a leaf).

## Three tests every spirit must pass

1. **Room test:** at 1x on the 56 canvas, you can tell what it is.
2. **Ball test:** it still reads as a 16 px ball: its main colour, its face and one top feature
   (ears, a leaf, a flame).
3. **Merch test:** its solid-black silhouette is recognisable, it has 4 colours or fewer, and nothing
   would snap off a plush.

## The realms and the evolutions

All slots are listed in **`docs/kami_spirits_tree.md`**. The ids and the tree stay; names and looks
are yours.

| Flavour fed | Realm | Palette and materials | Spirits in it |
|---|---|---|---|
| Sprouty | Mountain | moss, bark, stone, crow black | kodama, tengu, mushroom spirits, kappa |
| Sweet | Moon | indigo, cream, silver | moon rabbit, baku, mochi spirits |
| Savory | Fox | vermilion, gold, fried-tofu tan | kitsune, tanuki, festival-stall spirits |
| Spicy | Fire | ember red, soot, lantern paper | oni, lantern ghosts, raiju, the phoenix |
| Sour | River | blue-grey, rain, frog green | frogs, umbrellas, teru teru bozu, kappa |

Each realm has 24 spirits:
- **1 baby**
- **5 kids**: the baby fed each flavour. A kid shows a hint of the flavour it was fed, inside its
  realm's look.
- **15 adults**, 3 per kid, each by what it's fed:

| Branch | Fed | What the adult is |
|---|---|---|
| Pure | its realm's flavour | the realm at its clearest |
| Peak | the kid's own flavour again | the kid's own idea at its best |
| Chaos | any other flavour | a surprising, funny mix |
| Ultra | its realm's flavour (one kid per realm) | the realm's champion and the legend's parent |
| Bloom | a gentle mix (that same kid) | |
| Clash | a clashing mix (that same kid) | |

- **2 mutants**: Tech (any adult fed tech food: karakuri, robots) and Cosmic (fed cosmic food:
  from space).
- **1 legend**: the Ultra adult fed the realm's legendary food. Grand, but still simple.

**Lines:** a kid and its 3 adults keep one signature feature, so you can see the family.

**Silhouettes:** no body plan more than twice in one realm. Use a mix of round, tall, wide,
floating, four-legged and object-shaped.

## The three concepts (keep them, simplified)

With this budget, the concepts differ in **the idea**, not the decoration:
- **A. Hyakki Parade:** folklore yokai. A mask, a paper charm or an old object come alive, each as
  one bold shape.
- **B. Sofubi Gacha:** capsule-toy spirits. Chunky vinyl shapes, odd proportions, a little
  kimo-kawaii. Round 1's B was the closest to the target.
- **C. Offering Spirits:** born from what they're fed. The offering is the shape, the spirit is the
  face and the attitude.

## ImageGen: the master prompt (round 2)

Use the same prompt for every spirit of a concept; only `[SPIRIT]` changes. Generate each line (a kid
and its 3 adults) in one image so the family holds together. Make several tries and keep the
simplest.

```
A single original Japanese spirit character for a cute pixel-art pet game, [SPIRIT].
[CONCEPT LINE]
Simple chunky mascot design, like a plush toy or a capsule-toy keychain: one soft rounded main
body, a big simple face with large clear eyes, at most [N] small extra features, short stubby limbs
or none. Very few details: no patterns, no ornaments, no trims, no texture, no thin lines. Three
flat colours plus one small accent, soft simple shading, a dark outline. It must read clearly as a
tiny 32-pixel sprite.
Strict front view, centred, full body, calm idle pose, eyes open, mouth closed.
Plain flat light grey background, no ground, no shadow, no text.
```

- `[N]` is the stage's feature budget above.
- **A:** `A folklore yokai: one mask, paper charm or old object come alive, mischievous.`
- **B:** `A soft-vinyl capsule-toy spirit: chunky, odd proportions, a little cute-gross (kimo-kawaii).`
- **C:** `A spirit born from the offering it was fed: the food is its shape, the spirit is its face and attitude.`
- `[SPIRIT]` example: `a Fire-realm adult grown from a daruma kid; signature: one painted eye; colours: ember red, cream, soot; personality: stubborn, never falls over`

Then draw each spirit on the 56 grid yourself, at the budget. Don't just shrink the ImageGen picture:
simplify it.

## What to deliver

Folder: `docs/mockups/spirits/round2/concept_a/`, `concept_b/`, `concept_c/`. Each one has:
- `<id>.png`: the spirit, **56 x 56**, hard transparency
- `<id>_ball.png`: its ball, **24 x 24** (a 16 px ball with room for its top feature), like
  `textures/minigames/balls/`
- `names.csv`: `id, name_en, name_jp, body_type, signature, features, one_liner`
- `fire_sheet.png`, laid out as the tree:
  - the baby on top
  - the 5 kids in a row: Sprouty, Sweet, Savory, Spicy, Sour
  - each kid's adults in a column under it
  - the mutants and the legend on the last row
  - shown at 4x, with names
- `fire_sheet_1x.png`: the same at 1x, the real size
- `fire_balls.png`: all 24 balls
- `fire_silhouettes.png`: every spirit filled solid black
- `babies_px/`: the 5 babies with cartoon frames, each 56 x 56:
  - `idle`, `blink`, `happy` (squashed and wide), `eat` (mouth open), `sad`
  - layers: body, eyes, mouth, loose parts, with `pivots.txt`

## Order

1. All three concepts: the **5 babies** and the **Fire realm (24)**, with their balls. Then **wait
   for our feedback**.
2. The other four realms after that.

## Don't

- Don't install anything, and don't touch `textures/`, `scenes/`, `scripts/` or `data/`.
- Don't add detail to make a spirit look "finished". Simple is the goal.
- Don't overwrite `round1/`.
