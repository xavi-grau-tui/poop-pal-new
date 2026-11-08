# Device cases: brief, round 1 (2026-11-07)

The user liked Melon Soda (docs/mockups/case_melon_soda.png). They now want new examples that match
KamiTomo's look (the shrine, the spirits) and fit the device, which has a chunkier pixel than the
spirits. Every example must follow the case rules below; most of them are built in already.

## What a case is (the agreed rules)

A case re-skins the device's shell, front and back. The game builds every case from Melon Soda's own
layers (tools/art/cases_games.py), so these rules hold automatically:

- **Colour:** the case's colour on a three-tone ramp (outline, body, light), plus a print on its flat
  parts.
- **What it hides:** the screws, the device's dark edges and the back sticker. It has its own darker
  rim. The device's sides become one even stripe in the case's dark tone (seen when the device turns
  over).
- **What stays:** the screen, the buttons and the speaker keep their own colours.
- **Logos:** KamiTomo 神友 on the front and Kobaya Tech on the back are carved into the case, in its
  own colour (pressed in: shade on the top-left inner edge, light on the bottom right).
- **Menu buttons:** the top three get raised frames in the case's colour with a darker edge, holes
  showing only the button's face.
- **Screen:** round the main screen, the case reaches the screen's dark border and keeps the bezel's
  shaded band, in its own tones.
- **No print on the details:** never on the carving, the rim or the button frames. Those take the
  case's colour only.
- **The ladder, simple to fancy:**
  - Taro first: plain, early;
  - Melon Soda: 100 stars;
  - the Shop's prints: 40 coins;
  - the games' fancy ones: their 6-9 finales;
  - the planned shrine cases below.

## What you design: three tones and two small pictures

1. **Three tones** (hex): outline (the darkest, the rim and carving shade), body (the main colour)
   and light (the carving's highlight and the print's light).
2. **`back_print.png`, exactly 270 x 480.** It is pixel art on the device's own grid: 1 print pixel
   = 1 device pixel = 4 screen pixels. Only the white area of
   `docs/mockups/cases_brief/back_print_area.png` shows; everything grey takes the case colour by
   itself.
3. **`front_print.png`, also 270 x 480.** It only shows round the screens and buttons; see
   `front_print_area.png`. A calmer version of the back works best.

**Grid:** `print_area_guide.png` shows both areas at 2x.

## How it should look

- **KamiTomo's world:** shrine materials and festival things, warm and a little glossy, like the
  hokora and the spirits. Not flat clip-art, not photo textures.
- **The device's grid is chunkier than the spirits'.** Draw with whole device pixels:
  - motifs at least 6–8 pixels across;
  - shading in 3–4 clear steps;
  - no 1-pixel noise or dithering (it shimmers when the device tilts and flips);
  - no soft gradients.
- **Colours:** the three tones plus at most three accents per case. Light from the top left, like the
  device.
- **Keep the logos readable:** keep the print calm round the carved Kobaya Tech on the back (top
  third) and the KamiTomo patch on the front. Leave about 12 pixels round them quiet.
- **Look at what we have:** the 11 cases built so far are in `textures/cases/` (look only). Melon
  Soda's dots and Koma's lacquer and gold are the closest to the right level of detail.

## The examples we'd like (6)

| id | Case | Idea | Where it comes from |
|----|------|------|---------------------|
| `torii` | Torii | vermilion lacquer, a thin gold line inset round the edge, a soft lacquer sheen | 250 stars in all |
| `matsuri` | Matsuri | indigo cloth, rows of small red chōchin lanterns, a festival rope along the top | 500 stars in all |
| `washi` | Washi | cream paper with long fibres and a few pressed maple leaves | the Shop, 40 |
| `seigaiha` | Seigaiha | the blue wave pattern over the whole case, two blues and white | the Shop, 40 |
| `kintsugi` | Kintsugi | black lacquer mended with gold seams: a few bold cracks, not a web | every star (planned as Gold Leaf) |
| `koke` | Moss Garden | the forest hokora's moss: soft greens, small stones, a fern or two | the Tomopedia, 60 spirits (proposed) |

## Check before delivering

```
.venv/bin/python tools/art/case_preview.py <id> "<outline>" "<body>" "<light>" back_print.png front_print.png
```

It writes `docs/mockups/cases/round1/<id>/preview.png`, the front and back exactly as the game builds
them. Judge your case on that picture, not on your painting.

## Delivery

- **Where:** `docs/mockups/cases/round1/<id>/` for each case.
- `back_print.png` and `front_print.png`.
- `tones.txt` (the three hex colours).
- `preview.png`.
- Your concept painting, if you made one.

We show the user each case on the device in the game before anything is installed. Don't touch
`textures/`, `scenes/`, `scripts/` or `data/`.
