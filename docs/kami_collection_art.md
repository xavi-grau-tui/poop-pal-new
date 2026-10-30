# KamiTomo collection: art list for the hokora's progression

Every piece a player collects in the hokora version of the game, what still needs drawing, the
files the game expects, and how important each one is. Made 2026-10-30 with the progression design
(docs/progression.md, sections 4b and 5b). The data behind it is `scripts/hokora_catalog.gd`.

The food and drink icons have their own list: docs/kami_foods_and_drinks.md.

## How it works in the game

- **Drop-in files.** Every piece already exists in the game as data. When its PNG lands in the
  folder below with the right name, the game shows it by itself (no code needed). Until then a
  hanging or shelf piece shows nothing and its menu card says "Art soon"; a lantern shows the red
  one recoloured.
- **Folders.** Home pieces and their icons: `textures/pet/shrine_new/decor/` and
  `textures/pet/shrine_new/decor/icons/`. Sky sprites: `textures/pet/shrine_new/sky/`.
- **Names.** Lowercase, the piece's id from the tables below (`hang_furin-1.png`,
  `shelf_goldfish.png`, `icons/lantern_goldfish.png`).
- **Painting big is fine.** As with RC Prix: paint at 4x on the guide and we put it on the game's
  pixel grid with our converter. Say which you did.
- **Guides:** `docs/mockups/hokora_decor/` has the canvases with the places marked
  (`guide_hanging.png`, `guide_shelf.png`, `guide_lantern_2x.png`), the hokora as it looks today
  (`reference_default.png`) and the colour presets in the game by day and night
  (`reference_colours_day.png`, `reference_colours_night.png`).

## Style rules (all pieces)

- Match the forest hokora (`textures/pet/shrine_new/front.png`): its chunky pixel (one art pixel is
  about 6 px on the 925 px canvas), its pale, slightly greyed "switched off" palette, the dark plum
  outline (#200010) and the light from the top left. Accents may glow (lanterns, wisps, fireflies).
- Festival-prize charm, not shop clip art: each game is a festival stall at the shrine, so its
  pieces look like that stall's prizes (goldfish, glass beads, pennants, origami, koma tops).
- Pieces must read at phone size, at a glance: one clear shape each, few details.
- Keep the spirit's room clear: nothing may cover the middle of the opening where the spirit sits
  (the red box on `guide_hanging.png`).
- Avoid the rising-sun motif, real deities' names or faces, sake, and anything that mocks the
  offering rite (same rules as the food list).

## The formats

| Kind | Canvas | Frames | Notes |
|------|--------|--------|-------|
| Lanterns | 108 x 176 px, like `lantern.png` | 1 | Hook at the top middle (red circle on `guide_lantern_2x.png`); the game swings it from there and adds the candle glow. The left lantern is the same picture. |
| Hanging | 925 x 925 px, the canvas of `front.png` | 2: `<id>-1.png`, `<id>-2.png` | Transparent except the piece. Draw it on the front beam inside the blue box on `guide_hanging.png`, between the two lanterns. Frame 2 = a small sway (it alternates every 0.65 s). |
| Shelf pairs | 925 x 924 px, the canvas of `slab.png` | 1: `<id>.png` | Both pieces in one picture, standing on the slab in the two green boxes of `guide_shelf.png`, their feet on the green line (y 698). They stand in front of the hokora's pillars. A pair can differ (komainu: one mouth open, one closed). |
| Icons | 96 x 96 px | 1: `icons/<id>.png` | The menu card's picture: the piece alone, centred, filling the square. 32 x 32 pixel art also works (the game scales it 3x). |
| Sky sprites | tiny, 1 px = 1 art pixel | 1-4 variants: `<kind>_0.png`, `_1`... | The game scales them 6x and animates them (falling, fluttering, wandering). |

---

## P1: needed first (the merge gate: the hokora's decor and backgrounds must work)

These are the pieces a new player meets in the first hours.

| # | Slot | id (file) | Piece | Comes from | Notes for the art |
|---|------|-----------|-------|------------|-------------------|
| 1 | Lantern | `lantern_goldfish` | Goldfish Lanterns | Splash Hoops, 5 stars (minute ~3: the first piece anyone gets) | Kingyo-chochin: a paper lantern shaped like a red and white goldfish, fins and tail; glows warm orange |
| 2 | Hanging | `hang_furin` | Wind Chimes | Splash Hoops, 15 stars | 2-3 glass furin bells with paper strips and a little goldfish painted on the glass |
| 3 | Hanging | `hang_beads` | Glass Beads | Tilt Maze, 15 stars | A string of big glass marbles / beads swagged along the beam (the marble maze's stall) |
| 4 | Hanging | `hang_pennants` | Racing Pennants | RC Prix, 15 stars | A string of small triangle pennants, chequered and coloured (festival style, not a car brand) |
| 5 | Hanging | `hang_shimenawa` | Shimenawa | Paper Sumo, 15 stars | The twisted straw rope with zigzag white paper shide: the shrine rope and the yokozuna's |
| 6 | Hanging | `hang_pinwheels` | Pinwheels | Top Spin, 15 stars | Two or three kazaguruma paper pinwheels tied along the beam (frame 2: turned a little) |
| 7 | Shelf | `shelf_goldfish` | Goldfish Bowls | Splash Hoops, 60 stars | Two round glass bowls, a goldfish in each, water line and a highlight |
| 8 | Shelf | `shelf_sakaki` | Sakaki Vases | 20 spirits found | The classic offering: green sakaki branches in two white porcelain vases |
| 9 | Sky | `petals_0..2` | Cherry Petals | Paper Sumo 2-6 | 2-3 petal sprites, about 3 x 3 art pixels, pale pink |
| 10 | Sky | `maple_0..2` | Maple Leaves | Paper Sumo 3-6 | 2-3 leaves about 5 x 4, red, orange, yellow |
| 11 | Sky | `fireflies_0..1` | Fireflies | Paper Sumo 5-6 | A glow dot 3 x 3 (yellow-green) and a smaller one |
| 12 | Sky | `snow_0..2` | Snow | Paper Sumo 6-6 | Flakes of 1 to 3 art pixels |
| 13 | Icons | `icons/<id>` | for 1-8 | | |

## P2: the rest of the games' prizes

| # | Slot | id (file) | Piece | Comes from | Notes for the art |
|---|------|-----------|-------|------------|-------------------|
| 14 | Lantern | `lantern_festival` | Festival Lanterns | Top Spin 3-6 | Red and white chochin with a painted crest (a koma top, not a family mon) |
| 15 | Lantern | `lantern_jellyfish` | Jellyfish Lanterns | Splash Hoops 6-6 (the Deep Sea) | Glowing lilac jellyfish shapes with trailing tentacles |
| 16 | Lantern | `lantern_moon` | Moon Rabbit Lanterns | Paper Sumo 4-6 (the Moon Base) | Round pale lanterns with a rabbit pounding mochi painted on |
| 17 | Hanging | `hang_shells` | Shell Chimes | Splash Hoops 2-6 | Strings of small shells and a starfish that clink |
| 18 | Hanging | `hang_teru` | Teru-teru Bozu | Splash Hoops 5-6 (the Storm) | 3 little white cloth rain charms with drawn faces |
| 19 | Hanging | `hang_glow` | Glow Spores | Tilt Maze 3-8 (the moss garden) | Hanging moss with glowing spore bulbs (kodama lights) |
| 20 | Hanging | `hang_cogs` | Cog Garland | Tilt Maze 5-6 (the Factory) | Old brass cogs and keys on a cord: a tsukumogami joke (old things alive) |
| 21 | Hanging | `hang_koinobori` | Carp Streamers | RC Prix 5-6 (the Reef) | Two or three small koinobori carp windsocks |
| 22 | Shelf | `shelf_puzzle` | Puzzle Boxes | Tilt Maze, 60 stars | Two Hakone marquetry puzzle boxes (himitsu-bako), geometric wood inlay |
| 23 | Shelf | `shelf_ema` | Ema Plaques | RC Prix, 60 stars | Two small wooden ema racks, little cars, boats and planes painted on the plaques |
| 24 | Shelf | `shelf_origami` | Origami Cranes | Paper Sumo, 60 stars | Two folded paper cranes on little stands |
| 25 | Shelf | `shelf_koma` | Koma Tops | Top Spin, 60 stars | Two painted wooden spinning tops on small stands |
| 26 | Shelf | `shelf_kappa` | Kappa Statues | Tilt Maze 4-6 (the kappa's canal) | Two little stone kappa statues, a cucumber offered to one |
| 27 | Sky | `sky_fish_0..1` | Sky Goldfish | Splash Hoops 3-6 | A goldfish about 6 x 5, swimming (frame 2: tail flick) |
| 28 | Sky | `sky_lanterns_0` | Sky Lanterns | Splash Hoops 4-6 | A small warm paper lantern rising, about 4 x 5 |
| 29 | Sky | `fireworks_0..3` | Fireworks | RC Prix 4-6 (night only) | Spark sprites 2 x 2 in four colours (the game makes the bursts) |
| 30 | Sky | `dragon_0` | Cloud Dragon | Top Spin 6-6 (the Dragon Festival) | A long dragon made of cloud, about 120 x 30 art pixels, crossing the sky now and then. Needs art to appear at all |
| 31 | Icons | `icons/<id>` | for 14-26 | | |

## P3: late game, Lucky Pinch, RC Prix 2177 and the Shop's stall

| # | Slot | id (file) | Piece | Comes from | Notes for the art |
|---|------|-----------|-------|------------|-------------------|
| 32 | Lantern | `lantern_hozuki` | Hozuki Lanterns | 30 spirits | Glowing orange ground-cherry pods (the Fire realm's lantern plant) |
| 33 | Lantern | `lantern_fox` | Fox-fire Lanterns | 70 spirits | Kitsune-bi: pale blue spirit flames inside white lanterns |
| 34 | Lantern | `lantern_gold` | Gold Lanterns | 100 spirits | Gold-leaf lanterns, the prestige pair |
| 35 | Lantern | `lantern_daruma` | Daruma Lanterns | Lucky Pinch | Round red lanterns with a daruma face |
| 36 | Lantern | `lantern_neon` | Neon Lanterns | RC Prix 2177, 5 stars | Lantern shapes made of neon tube, magenta / cyan (for the future cyber home too) |
| 37 | Lantern | `lantern_white`, `lantern_indigo` | White / Indigo Lanterns | The Shop (20) | Optional: plain chochin in white or indigo (today a recolour) |
| 38 | Hanging | `hang_cranes` | Thousand Cranes | 40 spirits | Senbazuru: strings of many small coloured paper cranes |
| 39 | Hanging | `hang_led` | LED Strip | RC Prix 2177, 15 stars | A string of small LEDs along the beam, cyber colours |
| 40 | Hanging | `hang_bunting` | Festival Flags | Lucky Pinch | Small tenugui-style flags, festival colours |
| 41 | Hanging | `hang_noren` | Noren Curtain | The Shop (25) | A short split noren across the top of the opening (keep it above the spirit) |
| 42 | Hanging | `hang_fairy` | Fairy Lights | The Shop (25) | Warm string lights swagged along the beam |
| 43 | Shelf | `shelf_kitsune` | Fox Statues | 50 spirits | A pair of kitsune statues with red bibs, one holding a key, one a jewel |
| 44 | Shelf | `shelf_komainu` | Komainu | 80 spirits | The lion-dog pair, one mouth open, one closed |
| 45 | Shelf | `shelf_tsukimi` | Moon-viewing Set | 110 spirits | Tsukimi dango on a stand and susuki grass in a vase |
| 46 | Shelf | `shelf_maneki` | Maneki-neko | Lucky Pinch | Two beckoning cats (one left paw, one right paw) |
| 47 | Shelf | `shelf_neon_cat` | Neon Lucky Cats | RC Prix 2177, 60 stars | Maneki-neko in glowing neon colours |
| 48 | Shelf | `shelf_candles` | Candles | The Shop (15) | Two white candles in holders with small flames |
| 49 | Shelf | `shelf_stone` | Stone Lanterns | The Shop (30) | Two small toro stone lanterns |
| 50 | Shelf | `shelf_bonsai` | Bonsai | The Shop (30) | Two tiny bonsai in shallow pots |
| 51 | Sky | `wisps_0..1` | Spirit Wisps | 60 spirits | Hitodama: a pale blue flame with a tail, about 4 x 6 |
| 52 | Icons | `icons/<id>` | for 32-50 | | |

## Needs no art (made in the game)

- **Colours (wood and roof):** Weathered Cedar, Moss, Vermilion, Black Lacquer, Copper Roof, Moon
  White, Sakura Wood, White-washed, Indigo, Gold Leaf. A shader recolours the wood, the roof's
  terracotta and the moss separately (the stone base keeps its colour). See
  `reference_colours_day.png` / `_night.png`. If you'd like a better colour for any of them, send
  three colours per material (dark, middle, light) and we tune the preset.
- **Skies:** Shrine Pink, Lagoon, Mint, Peach, Teal, Summer Blue, Golden Hour, Aurora, Neon Dusk, Red
  Moon, Lilac, Amber, Silver, Sakura: each is a day, a dusk and a night colour. Suggestions welcome.
- **Cloud layers already drawn** (shared with the gut version): Clouds, Marbles, Balloons, Paper
  Cranes, Spinning Tops, Bubbles, Starfield.

## Planned items (not in the game yet; add them when their art exists)

These need art before they can go in, because the game can't fake them.

**Dress-ups.** Each one is fitted to every spirit by our scripts (`tools/art/hats.py`), so
please draw one clear design (front view, about 40 x 30 art pixels at the spirits' scale) plus a
32 x 32 icon. Best done once the spirits' final designs are chosen.

| id | Dress-up | Planned source |
|----|----------|----------------|
| `kitsune_mask` | A fox festival mask worn on the side of the head | Tomopedia, 30 spirits |
| `ofuda` | A paper charm stuck on the forehead | Tilt Maze secret (a later world) |
| `sugegasa` | A conical straw hat | Paper Sumo secret |
| `kanzashi` | A flower hairpin | Lucky Pinch |
| `suzu_collar` | A red cord with a little bell | Splash Hoops secret |
| `oni_horns` | Two small oni horns on a band | Top Spin secret |
| `cyber_visor` | A neon visor | RC Prix 2177, 30 stars |
| `taiko_band` | A taiko drummer's headband | Tomo Tunes, 30 stars |

**Cases** (the device's shell: front, back and button frames, built from Melon Soda's layers by
`tools/art/cases_games.py`; the designer gives the colour set and the print).

| id | Case | Planned source |
|----|------|----------------|
| `torii` | Torii: vermilion lacquer with a thin gold rim | 250 stars in all |
| `matsuri` | Matsuri: indigo with a print of small lanterns | 500 stars in all |
| `goldleaf` | Gold Leaf | every star (972) |
| `turbo` | Turbo: neon racing stripes | RC Prix 2177, 6-9 |
| `washi` | Washi: paper texture print | The Shop, 40 |
| `seigaiha` | Seigaiha: the blue wave pattern | The Shop, 40 |
| `taiko` | Taiko: drum skin and studs | Tomo Tunes, 6-9 |
| `classic` | The smooth realistic skin (the user's idea: `textures/console/back_realistic.png` and matching front buttons) | to decide |

**Stickers** (for the cases: 276 x 144 sticker + 184 x 96 book version, like the current ones in
`textures/cases/stickers/`). A new SHRINE page in the sticker book needs its tab drawn on
`textures/cases/book/book.png` (a 7th tab). Themes: omamori, ema, daruma, maneki-neko, torii,
kitsune mask, furin, ramune bottle, konpeito, taiyaki, koinobori, hanabi. They'll be the small
secrets' prizes (each world's 3rd level). Also RC Prix 2177's gold rocket (150 stars) and Tomo
Tunes' gold drum.

## Counts

- Home pieces to draw: 11 lanterns, 15 hanging, 15 shelf pairs = 41 pictures, plus 41 icons.
- Sky sprites: 8 kinds (petals, maple, fireflies, snow, sky fish, sky lanterns, fireworks, wisps)
  and the cloud dragon.
- Planned: 8 dress-ups, 8 cases, 14 stickers and a sticker-book tab.
