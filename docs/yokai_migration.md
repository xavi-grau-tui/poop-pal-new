# Yokai migration (branch `yokai-migration`)

The game moves from "poop pals in a gut" to **spirits in a little shrine**. The user, 2026-10-20:
the analog device stays the main hook; the spirit world gives it depth, if the pals are designed
well. Main keeps the gut until the user decides; everything here happens on this branch.

## What changes, in one line each

| Now | Spirit version |
| --- | --- |
| HaraTomo 便友 | **KamiTomo 神友 / カミトモ** (chosen; renamed everywhere 2026-10-26: logo, box, cases, back sticker, texts, app name; still to check stores and trademarks) |
| the gut around the pal | a small weathered wooden hokora (to be redrawn; the try-out art is a reference only) |
| food rains into the gut, it blinks | the whole food drops onto the sanbo (offering stand) and the spirit eats it in three bites, then blinks as before (BUILT: scripts/shrine.gd, offer_food) |
| drink waterfall | the drink's own picture pours into a small cup on the tray; the spirit draws its essence out in its type's colour (BUILT: offer_drink) |
| boost: glow and drips on the pal | a pixel-art plasma flame in the boost's colour round the spirit while the boost lasts (BUILT: scripts/boost_aura.gd) |
| flush (spins down, cling) | send-off: it rises out through the roof as a wisp, the bell rings |
| gut decor and gut colours | shrine decor: hanging things, pairs on the slab, wood and roof colours (below) |
| backgrounds | sky colour + drifting layer (cloud types, seasonal elements; below) |
| the pals | spirits first (below) |
| foods and drinks | mostly real offerings, plus a few "unusual" world foods (below) |
| minigames | kept as they are; a few worlds repainted (below) |

## The pals

### Direction

- **Spirits first.** Most pals become spirits: yokai, kami's messengers, animal spirits,
  tsukumogami (old objects come alive), weather and nature spirits. A food shape stays only
  where the user picks it as a favourite; those are restyled to the new rules, not redrawn
  from zero. Target: about **70% spirits, 30% kept food shapes**.
- **The babies stay** (Bud, Nib, Inari, Ember, Picklet): the little spirits every line starts from.
  Picklet keeps its original art.
- **The tree's structure stays**: 5 families x (1 baby, 5 kids, 15 adults, a tech and a cosmic
  mutant, 1 legend) = 120; which foods lead where stays; only looks, names and texts change.
  Each family is a realm:
  - **Green**: forest and mountain (kodama, tengu, kappa, yamabiko, mushroom spirits)
  - **Greasy**: fox and festival (the fox line, tanuki, tofu-kozo, festival-stall spirits)
  - **Spicy**: fire and oni (oni, lantern ghosts, hoozuki, raiju; the phoenix legend)
  - **Sour**: water and rain (teru teru bozu, amabie, ningyo, umibozu; the frog king)
  - **Sweet**: moon and night (the moon rabbit, baku, zashiki-warashi, Kaguya, Tsukuyomi)

### Look rules (the brief)

**Current visual reference (user-selected, 2026-10-23):**
[`docs/mockups/pal_brainstorm/current_spirit_style_reference.png`](mockups/pal_brainstorm/current_spirit_style_reference.png),
the second 15-spirit concept sheet. Use its pixel shading, dark stepped outlines,
varied compact silhouettes, expressive faces, and restrained folklore details as
the starting point for future spirit designs. The sheet sets the **style**, not
final approval of every depicted character. Keep the five existing baby identities;
main idle poses face forward and fit inside the shrine room. Continue evolving
the designs from this reference with the user.

1. **One signature feature per pal**, readable at a glance and at the ball's 16 px: a mask, a
   single big eye, a flame for hair, a paper charm on the forehead, a lantern body, a torii horn.
2. **Faces are a design choice**, not dots and a mouth by default: masks (fox, oni), glowing slit
   eyes, faceless shapes with only a mouth, a third eye, eyes on a tail or hands. Some calm dot
   faces stay (the babies), but no more than a quarter of a family.
3. **Bold silhouette, small palette**: 2-3 colours plus one accent; the shape reads before any
   detail. No body plan more than twice per family band (the check3.py rule stays).
4. **"Switched off" colours**: softer, slightly greyed palettes (the user liked the muted pal in
   the shrine try-out), so the pal sits in the shrine's dim wood without shouting. Accents may
   glow (wisps, eyes, charms).
5. **Spirit materials**: paper charms (ofuda), straw rope, lacquer, smoke and wisps (hitodama),
   bells, cracked porcelain, wood grain, paper lantern ribs.
6. **Same render quality and pixel scale** as the current pals (the palgen3 pipeline: paint big,
   shrink, double outline), so the games, the balls and the overlays keep working.
7. **Mischief over cute**: cheeky, curious, a little spooky; humour stays (odd offerings, funny
   reactions).

### Process

1. **Keepers**: the user marks favourites among the 120 current pals (food shapes to keep and
   restyle; spirits to keep as they are).
2. **Test sheet: Spicy** (fire and oni), the 24 pals of one family as concepts, with names and
   one-liners, rendered at game quality. The user judges it before anything else moves.
3. **Roll out** family by family, a sheet each, the user picking per pal.
4. **Into the game** with the existing pipeline: sets -> tools/design/evolution_data.py ->
   tools/art/pals_export.py (sprites, pal_faces.json) -> accessories.py, scarf.py, headphones.py
   -> pal_balls.py; then the things drawn from pals (Paper Sumo rivals, theme stickers, the pedia
   texts and hints).
5. Form ids: a renamed pal keeps its id, or the save loader maps old ids to new ones.

## Foods and drinks

Agreed 2026-10-26, replacing the earlier draft: the full list, the 14 new icons to draw and the
naming rule across countries are in **docs/kami_foods_and_drinks.md** (for the art designer).
Mostly East Asian offerings plus a few world foods as the odd offering; the menu has to fit any
home, not only the hokora. Same structure, each new food in the slot of the one it replaces.

## Minigames

Rules, levels and the suite look stay. Only dressing changes:
- Tilt Maze: The Gut -> a moss garden (same bouncy walls, drifting holes); Sewer -> a kappa's
  canal (same currents); the flush swirl exit -> a well or a little torii.
- Top Spin: Toilet Bowl -> an onsen tub (its whirlpool stays).
- Tummy Tunes: a new name (a taiko game?).
Framing: the device's games are the shrine's festival stalls (ennichi).

## Shrine decor and backgrounds (DECIDED with the user 2026-10-20; TO BUILD before the merge)

The gut's two collection menus become two shrine menus. Same system as now (slots that combine,
unlocked by the games' stars, the secrets, Lucky Pinch), new content.

**Shrine decor** (its own menu; was gut decor), three slots:
- **Hanging**: on the beam and the eaves, swinging with the tilt like the bell rope. Shimenawa with
  zigzag paper streamers (shide), paper lanterns, a glass wind chime (furin, a faint ring), a short
  noren curtain, fairy lights. The existing complements carry over where they fit (Shimenawa,
  Fairy Lights, Bunting, Pinwheels); the rest get a shrine version or retire.
- **Pairs on the slab**: one each side of the sanbo, always symmetric, built as 3D boxes like the
  sanbo (same depth order). Sakaki branches in white vases (the first one: the plant idea), small
  stone lanterns (toro), kitsune or komainu statues, candles, a tiny bonsai. (2026-10-21: a small
  stone lantern and a potted sakaki were drawn and tried in the game; kept as possibles, not shown:
  tools/art/shrine.py stone_lantern_layer / sakaki_layer, ORNAMENTS=1 writes them.)
- **Colours**: a palette swap of the wood and the roof (was the gut colours): weathered cedar (now),
  vermilion lacquer (like Inari shrines), black lacquer, white-washed wood, a moss roof, a green
  copper roof. Cheap: tools/art/shrine.py with another palette.

**Backgrounds** (a separate menu, as now), two slots:
- **Sky colour**: the sky's tint (peach, mint, teal, lilac...). Time of day is never an unlock: the
  real sun, moon and sky tint follow the clock, and every sky colour gets its own dawn, day, dusk
  and night look automatically (decide how strongly the tint darkens coloured skies).
- **Drifting layer**: what floats across the sky. Plain clouds are the default; the items are cloud
  types (a fox cloud, an onigiri cloud, a little dragon, a spirit-shaped cloud: drifting slowly, a
  thing to spot) and seasonal elements (cherry petals, summer fireflies, maple leaves, snow); the
  current ones (balloons, paper cranes, marbles...) carry over. A **Seasons** item, earned by owning
  the four seasonal ones, follows the real calendar by itself.

Later idea (kept): what you complete in the games could also show inside the shrine (an ema
plaque, a little top on a shelf, a paper sumo doll...).

## Late-game homes (the user, 2026-10-20: DEFINITELY to do, later; after decor and backgrounds)

The shrine stays the default home; late-game milestones unlock other homes the player can switch to
(a **Home** choice at the top of the Shrine decor menu; not a forced swap). Each home is built like
the shrine (3D box pieces in depth order, an offering spot, a pouring spot, a send-off exit), so a
new home is mostly new art; hanging things and pairs adapt per home (or each home has its own set);
backgrounds work with all of them.

- **Neon cyber shrine** (tech; first tech mutant): the hokora retro-futurized, LED strips on the
  eaves, a CRT screen for the mirror, cables for the bell rope, a vending-machine tray for the sanbo.
- **Capsule micro-apartment** (futuristic, the user's idea): a Tokyo capsule-hotel pod, a lamp, a
  mini fridge, posters; offerings come by a little delivery drone, the send-off out through a hatch.
- **Moon shrine** (cosmic; first cosmic mutant): on a floating rock in space, stars and the Earth
  behind; offerings drift down slowly in zero gravity.
- **Golden temple** (legend; the endgame): gold leaf, a status symbol.
- Later extras: a yatai ramen stall (the spirit cooks), an arcade cabinet (the device in the device),
  a tree hollow (forest spirits), a ruined night shrine (fireflies), a bathhouse.

Start with the moon shrine and the cyber shrine (they tie to foods already in the game).

## Lucky Pinch, guide cards

The bonus stays (the claw machine is a festival stall like the other games); in the shrine it is
announced by the bell rope ringing by itself and a glowing capsule (or an omikuji slip) landing on
the offering stand, BONUS! on the LCD, the Games button blinking. The guide cards' words follow the
migration ("pal" -> the new word). Details: docs/ideas_roadmap.md, "Tutorials for every game".

## Focus now (the user, 2026-10-20)

Stop adding components: the plan is long enough. Finish what's decided (shrine decor, backgrounds,
the spirits' art, texts) and polish: match the game's look more closely, refine the menu slides
(diapositives) and the device itself so they look better. New ideas go in this doc for later.

**Homogenize the whole app's look (the user, 2026-10-21: to do at some point, parked for now).**
The goal: the device, the buttons, the menu slides (and later everything) feel like the shrine,
softer, "less definition", the way they look when seen at a lower resolution. NOT recoloured:
the same colours and the same outlines, consistent everywhere. What the tests showed: blurring
screenshots only looks out of focus; recolouring outlines per colour made them inconsistent (the
user didn't want that); an effect on top of the art leaves rough edges. So do it at the source: the
art redrawn (or re-exported) at a coarser pixel size with a slight softening, the same for every
piece so the whole app matches. The spirits keep their black outline for now (a coloured outline
like the shrine's was tried on Picklet: maybe later).

## Order of work

1. Keepers (the user) -> 2. brief + Spicy test sheet -> 3. if it convinces: the name, the shrine
redrawn (with a ground patch, not floating), feeding as essence, the send-off -> 4. the other
families -> 5. foods and drinks art -> 6. minigame repaints, texts ("poop", "flush", "gut") -> 7.
merge to main when the user says so, and NOT before the shrine decor and the backgrounds work
fully in the shrine (the user, 2026-10-20).

## Notes

- Respect: yokai and made-up spirits are fine to play with; real named deities and real shrines
  are handled lightly, and the offering act stays sincere (the joke is the odd food, not the rite).
- The shrine is in the repo now: scripts/shrine.gd, tools/art/shrine.py -> textures/pet/shrine/,
  tools/audio/offering_sounds.py; the dev launcher's SHRINE start (always the sour baby, Picklet).
- **Keep the gut** (the user, 2026-10-20: the spirit shrine is the official direction, but the gut
  stays, out of affection): don't delete its code, art or sounds; every non-SHRINE start keeps it.
  Later it could come back as a hidden or unlockable "classic" skin.


## KamiTomo logo footprint (2026-10-26)

- Kept the approved Kami (`KAMI`) lettering and 神 glyph. The Latin row is 64 px high; moved the 友 glyph down 4 px to restore the original 6 px gap below the letters. Restored the original HaraTomo TOMO word and 友 glyph at their exact source-image coordinates, so the suffix and the full 526×128 footprint match the old logo. The scene uses the original logo transform. Shifted only the KAMI word 8 px right to make the i–T gap match the other letter gaps; the installed preview was approved by the user.
