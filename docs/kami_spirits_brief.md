# The 120 spirits, round 1: three concepts (brief for the designer, 2026-11-04)

> Superseded by **`docs/kami_spirits_brief_round2.md`**. Round 1 was too detailed for the screen; its
> 80 px canvas and "detailed pixel art" were wrong. This brief is kept for the record.

KamiTomo's creatures: 120 spirits that live in the hokora, 24 per realm (1 baby, 5 kids, 15 adults,
2 mutants, 1 legend). Every slot is listed in **`docs/kami_spirits_tree.md`**: its realm, its stage,
what it grows from and the flavour that leads to it. The tree's structure is fixed; the looks, names
and personalities are what this round is for.

This round: **three different concepts, each a complete set of all 120**, so we can pick the
direction (or mix the best of them) before anything goes into the game.

## The goal

A cast that could become iconic, the way the best monster-collecting games are: every spirit
recognisable from its **silhouette alone**, a name you want to say out loud, something you'd want as
a keychain or a sticker. Japanese at heart (yokai, shrine life, festivals, today's Japanese
character culture) but **not the usual**: no generic kawaii blob with dot eyes, no copy of anything
that exists. Each realm should feel like its own world, and each line (a kid and its 3 adults)
like one family with a clear idea that grows.

## The three concepts

Keep the three clearly apart: same 120 slots, three different answers.

**A. Hyakki Parade (百鬼夜行): folklore yokai.** The night parade of a hundred demons, today.
Masks (kitsune, oni, hyottoko), ofuda paper charms, tsukumogami (old objects come alive: a paper
umbrella, a lantern, a sandal, a teapot), straw rope, lacquer, wisps (hitodama). Faces are a design
choice: a single eye, a mask, a faceless shape with only a mouth, eyes on a tail. Mischievous and a
little spooky, never gory. Starting point: `docs/mockups/pal_brainstorm/current_spirit_style_reference.png`
(the last style the user picked), pushed further.

**B. Sofubi Gacha (ソフビ / ガチャ): collectible toy spirits.** As if each spirit came out of a
capsule machine at a shrine festival: the chunky, simple forms of Japanese soft-vinyl toys,
odd proportions, a bit of **kimo-kawaii** (cute and gross at once: perfect for a game that began
with poop). Very few details, very strong shapes, big readable features, a signature pose. The
most "merch-ready" of the three.

**C. Offering Spirits (お供え): born from what they're fed.** Each spirit grows out of its offerings
and the shrine's things: foods, festival snacks, bento pieces, utensils, charms, coins and bells
come alive and take a spirit's form. The strongest link to the game's feeding: you can see what a
spirit ate in it, and the Chaos adults are wonderful strange mash-ups. Food shapes are welcome here,
but always as **spirits** (eyes, attitude, spirit materials, a little magic), never just "a food
with a face".

## Rules for all three

**1. Match the shrines.** The spirits live in front of the hokora homes and must look like they come
from the same world: the same pixel-art finish, the dark plum outline, the soft lit shading, the
calm "switched off" colours (slightly greyed, never neon), one accent that may glow (eyes, a flame,
a charm). References:
- `docs/mockups/hokora_homes/v8/all12_in_game_new_forest.png`: all 12 homes in the game
- `docs/mockups/hokora_homes/v8/forest_hokora/final/front.png`: the default home, 220 x 220
- `docs/mockups/hokora_decor/reference_pixel_density.png`: the pixel size to match

**2. Built to be animated by our scripts.** We'll add breathing, blinking, idle sways, eating and
reactions in code, so each design must allow it:
- a **strict front view**, facing us, centred, standing or floating calmly. The pose is neutral and
  close to symmetric (asymmetric details are fine). Eyes are open and the mouth is closed
- **one main body mass** that can squash and stretch for breathing
- **eyes clearly on the face**, not hidden by hair or a mask, so they can blink. An eyeless design
  says what "blinks" instead (a glow, a charm, a mouth)
- **loose parts attached at a clear joint**, not fused into the body or crossing the face: ears,
  tails, flames, wings, sleeves, ribbons, charms. These are what will sway
- feet (or the lowest point) on a **flat baseline**. No ground, no cast shadow, no glow halo, no
  background, no text (we add those in the game)

**3. Size.** At the homes' pixel size, each spirit fits an **80 x 80 art-pixel canvas** (the homes
are 220 x 220; the room inside a home is about 80 px wide). Size grows with the stage:
- babies about 40 px tall
- kids about 48 px
- adults 52 to 64 px
- mutants and legends up to 72 px

Designs must read at that size, so keep few, big shapes.

**4. A realm look, a line idea, and different silhouettes.**
- Each **realm** has its own palette and materials:
  - Mountain: moss, bark, stone, crow feathers
  - Moon: indigo, cream, silver, rabbit and mochi
  - Fox: vermilion, gold, fried tofu, festival stalls
  - Fire: ember red, soot, lantern paper, oni
  - River: blue-grey, rain, frogs, umbrellas
- Each **line** (a kid and its 3 adults) keeps one signature feature.
- Silhouettes must change between stages. The old set's big problem was "the previous one but
  bigger, or with a hat". An adult should be a new shape, not the kid scaled up.
- No body plan more than twice in one realm.
- The branches mean something:
  - **Pure**: the realm at its clearest
  - **Peak**: the kid's own idea at its best
  - **Chaos**: a surprising mix
  - **Ultra**: the realm's champion
  - **Tech**: mechanical (karakuri, robots)
  - **Cosmic**: from space
  - **Legend**: grand, but still fits the 72 px

**5. Original.** Inspired by Japan, copied from nothing: no characters, or close look-alikes, from
Pokémon, Yo-kai Watch, Ghibli, Sanrio, Digimon or Tamagotchi. Real named gods stay light and
respectful (the joke is the odd food, never the rite).

## ImageGen: the master prompt

Use one master prompt per concept, the same for all 120 spirits of that concept. Only the
`[SPIRIT]` part changes for each spirit. Keep the wording identical, so the set stays consistent.

```
Pixel art game sprite of a single original Japanese spirit creature, [SPIRIT].
[CONCEPT LINE]
Strict front view, facing the viewer, centred, full body, neutral calm idle pose, eyes open,
mouth closed, standing on a flat baseline. One clear main body, separate readable appendages
attached at clear joints, eyes clearly visible on the face.
Style: detailed 16-bit pixel art like a high-quality Japanese shrine game, crisp 1-pixel dark plum
outline (#22101A), soft lit shading from the top left, muted slightly greyed palette, one small
glowing accent. Bold simple silhouette readable at 64 pixels.
Plain flat light grey background, no ground, no shadow, no glow halo, no text, no frame.
```

The concept lines:
- **A**: `A folklore yokai from the night parade of a hundred demons: masks, paper charms, old objects come alive, mischievous and slightly spooky, never gory.`
- **B**: `A collectible soft-vinyl capsule toy spirit from a Japanese festival gacha machine: chunky simple forms, odd proportions, cute and a little gross (kimo-kawaii), very few details.`
- **C**: `A spirit born from shrine offerings and the foods it was fed, taking a living spirit form with eyes, attitude and a little magic, not just a food with a face.`

`[SPIRIT]` example (the Fire realm's Pure adult from the Daruma kid):
`a Fire-realm spirit, adult stage, grown from a round daruma kid; signature feature: one painted eye; colours: ember red, soot black, cream; personality: stubborn, never falls over`

**Workflow tip:** generate each **line in one image** (the kid and its 3 adults side by side) so
they stay one family, then cut them apart. Generate the baby, the mutants and the legend alongside
the realm's other spirits. Re-roll any spirit that breaks the rules (side view, cropped, merged
parts) instead of fixing it by hand.

## What to deliver

Folder: `docs/mockups/spirits/round1/concept_a/`, `concept_b/`, `concept_c/`. Each one has:
- `README.md`: the concept's name, a 3-line pitch, its palette per realm, and the exact master prompt
  used
- `<id>.png` for every spirit: the ImageGen study, square, the spirit alone. Use the ids from
  `kami_spirits_tree.md`
- `names.csv`: `id, name_en, name_jp, one_liner` (names fun in both languages)
- `<realm>_sheet.png` for each realm (mountain, moon, fox, fire, river), laid out as the tree:
  - the baby on top
  - the 5 kids in a row: Sprouty, Sweet, Savory, Spicy, Sour
  - each kid's 3 adults in a column under it (Pure or Ultra first)
  - the 2 mutants and the legend on the last row
  - names under each spirit
- `<realm>_silhouettes.png`: the same sheet with every spirit filled solid black (the silhouette
  test)
- `babies_px/`: **the animation proof**, the 5 babies on the real 80 x 80 pixel grid with hard
  transparency, as layers:
  - `<id>.png`: the whole spirit
  - `<id>_body.png`, `<id>_eyes_open.png`, `<id>_eyes_closed.png`, `<id>_mouth_open.png`
  - `<id>_part_<name>.png`: one per loose part
  - `<id>_pivots.txt`: each part's joint pixel (x, y)

## Order: one check-in halfway

1. First, for all three concepts: the **5 babies** (with `babies_px/`) and the **whole Fire realm**
   (24). Send them and **wait for our feedback**.
2. Then the other four realms, with the feedback applied.

## Don't

- Don't install anything, and don't touch `textures/`, `scenes/`, `scripts/` or `data/`.
- Don't rename or remove slots: the ids and the tree stay as they are.
- Don't change one concept to look like another. Three real directions are the point.
