# RC Prix Garden · Round 10 look sample

The seven sample PNGs in `textures/minigames/rcprix/garden/` are drawn at the final grid size:

| File | Size |
|---|---:|
| `start_h.png` | 180×180 |
| `boost_e.png` | 180×180 |
| `ramp_e.png` | 180×180 |
| `start_gantry.png` | 90×32 |
| `start_lamp_off.png` | 22×22 |
| `start_lamp_red.png` | 22×22 |
| `start_lamp_green.png` | 22×22 |

The overlays have crisp transparent backgrounds. The start line uses a 24 px deep three-row
checker band with white painted edges, scuffs and a pole-position mark. The cyan boost plate has
an opaque light spill, metal frame and lit corner bolts. The ramp is extracted from the exact
imagegen study in `round10_ramp_imagegen_reference.png`, masked around its outline and reduced
with nearest-neighbour to the final game grid. Its low west entry and high east lip retain the
source plank shading, thick side face, rails and painted arrow. The gantry has a small roof and a warm-metal
fascia, without a red-and-white stripe. Its sockets are centered at x=18,
45 and 72, y=16, and its lamps add lit rims around the sockets.

## Previews

- `round10_sample_startline_3x.png`
- `round10_sample_boost_3x.png`
- `round10_sample_ramp_3x.png`
- `round10_sample_lights_3x.png`
- `round10_sample_overview.png`

These are composed from the delivered PNGs with nearest-neighbour enlargement. To rebuild:

```sh
.venv/bin/python3 tools/art/rcprix_round10_sample.py
.venv/bin/python3 tools/art/check_rcprix_art.py --round10-sample
```

## Imagegen reference prompt set

Built-in imagegen was used for visual references, followed by a deterministic final-grid pixel
draw. Shared prompt: “RC Prix Garden pixel-art road furniture in the approved road style; flat
opaque colours, clusters at least 2×2 pixels, top-left light, outline #281E28, no gradients,
noise, antialiasing, soft glow, text, extra objects or ground shadow.”

- Start line: bold 20–24 px deep checkered band with white painted border, light scuffing and a
  pole-position mark.
- Boost: dark inset metal pad with three bright cyan east-facing chevrons, light spill and corner
  bolts or lamps.
- Ramp: substantial wooden slope nearly filling the road across its width; lighter high east end,
  darker west entry, exposed side faces, rails, planks and a painted arrow.
- Gantry: compact 90×32 housing with shallow roof, neutral metal fascia and three empty sockets centered
  at x=18, 45, 72 and y=16; off/red/green lamp states glow onto the sockets.

## Validation

The Round 10 sample checker reports **7/7 files present, 0 problems**. Each sample also has
binary alpha (fully transparent or fully opaque). The full checker currently reports 14 missing
stand and flag sprites (`stand_*` and `flag_0/1`), which belong to a separate sprite round; no
Round 10 sample asset is flagged.
