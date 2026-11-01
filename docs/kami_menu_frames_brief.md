# Menu slides: brief for the designer (v2, 2026-10-31)

The user: redo the WHOLE menu slide ("diapositive") in the hokora's style (paper or thin wood, the
hokora's pixel size), keeping only the window's background (its colour / pattern), the logos, the
item pictures and the texts / counters. v1 (only the outer frame) was too narrow.

Today's pieces (all used by every menu): `textures/menus/diapositive1/2/3.png` (the slide, 402 x 394,
shown ~2.07x), `diapositive1_ring.png` (its inner border, over the food menu's shutter: we rebuild it,
`tools/art/frame_ring.py`), `gametoplabel.png` (the logo plate, 288 x 170), `gamebottomlabel.png` (the
stats plate, 288 x 81), `foodmenulabel.png` / `foodmenulabel_food.png` (the list card, 400 x 122),
`foodtag.png` (the tag, 107 x 51), `circle*.png` / `dot1.png` (page dots), `textures/buttons/logoforward.png`
(the >> hint); code-drawn: the legend chip (menu_legend.gd), the NEW badge, the price box, the kind
tags (collection_menu.gd StyleBoxFlat). Sizes below are on-screen sizes / ~8.3 px (a hokora pixel on
a 1080-wide screen), so the designer draws at 1x and we fit them; the layout stays. Old files stay
for a rollback. References: `docs/mockups/menu_frames/` (redraw_map.png first).

The message, ready to send:

```
MENU SLIDES – the whole menu slide in the hokora's style

Every menu is a "slide" (a rounded mount with a window, and plates inside it: the game's logo
plate, its stats, the list cards...). We want the WHOLE slide redrawn so it belongs with the
hokora: the same pixel size, and the look of PAPER (washi) or THIN WOOD (a light veneer).

KEEP (don't redraw): the window's background (its colour or pattern), the logos, the item
pictures, the texts and the counters. Everything else is new.

References in docs/mockups/menu_frames/:
- redraw_map.png – START HERE: red numbers = redraw, green K = keep
- current_games_menu.png, current_decor_menu.png, current_food_menu.png, current_hub_menu.png
- current_frames.png, frame_template.png – the slide frame today and what must stay where
And the style: docs/mockups/hokora_homes/v5_brief/v5_style_reference.png

WHAT TO REDRAW (sizes in art pixels; draw them at exactly this size, 1 pixel = 1 art pixel,
plus an 8x preview; we fit them to the screen)
1. The slide frame: the mount and the window's border, 100 x 98. Three tints like today (cream,
   yellow, tan). The window keeps its place and size (frame_template.png) and its inside stays
   transparent. Keep the bottom band calm: the legend, dots and arrow sit there.
2. The logo plate (the game's / section's logo sits in it): 74 x 46, its inside transparent (the
   logo and its pattern show through), a thin border.
3. The stats plate (two lines of text: "Stars 0/162"): 74 x 22, a plain inside for the text.
4. The list card (one per item): 72 x 20, with the picture square on its left (about 17 x 17
   inside, the picture shows through) and a plain area for the name and status.
5. The counter box (the food menu's "NEXT MEAL IN 29:56"): 49 x 28, a plain inside.
6. Small plates that stretch, as 9-slices (3-pixel corners, plain middle): the button legend chip,
   the tags (e.g. "Lantern"), the NEW badge, the price box. One 12 x 12 piece each is enough.
7. The page dots: a filled and an empty one, 4 x 4 (small pixel beads or paper dots).
8. The forward hint (the small >> at the bottom right): 7 x 5.

THE STYLE
- The hokora's pixel size (that's what the sizes above give), its dark plum outline #200010
  (1 art pixel), light from the top left: a 1-pixel highlight top-left, a shade bottom-right;
  windows and plates slightly recessed or raised, like real paper or wood layered on each other.
- Paper: washi fibres, a few 1-pixel specks. Thin wood: a fine straight grain in 2-3 tones, a tiny
  knot here and there. Muted, warm colours (the hokora's palette). Keep the plates under text
  plain enough to read on.
- Hard pixels only, no soft shading, no noise.

WHAT TO DELIVER (docs/mockups/menu_frames/v1/)
Step 1: the slide frame (1) + the logo plate (2) + the stats plate (3) in BOTH materials (paper
and thin wood), so we choose in the game.
Step 2: the chosen material for everything (1-8), the slide in three tints.
```

Notes for us: compose the new slide around today's window insides (diapositive1/2/3), rebuild the
ring, replace the StyleBoxFlat plates by the 9-slices (NinePatchRect / StyleBoxTexture), re-check
menu_legend.gd's measured band, the cards' icon room (SQUARE_IN_FRAME / ICON_ROOM) and the price
box after the swap; try it on the phone; keep the old files to roll back.

TRIED IN THE APP 2026-11-01 (the step 1 samples swapped into today's menus) and DISCARDED: the user,
"awful outlines, awful textures and inner labels". The trial (its textures, the dev launcher's SLIDES
switch, the script) was removed; the menus stay as they are. To rethink from scratch before asking
the designer for anything more.
