# RC Prix Garden · road furniture, stands, flags and butterflies

## Delivered on the final pixel grid

- Round 10: `start_v`, `start_h_wide`, `start_v_wide`; `boost_w/n/s` and all
  `boost_*_wide`; `ramp_e/w/n/s` and all `ramp_*_wide` in
  `textures/minigames/rcprix/garden/`. The approved `start_h` and `boost_e`
  remain in place. None of the start lines has a number.
- Ramp cross-road width is exactly 76 px on the narrow track and 88 px on
  the wide track. Their reach matches the measured `ramp_e`: east 41–138,
  west 42–139, south 41–138, north 42–139 (exclusive upper bounds).
- Round 11: `stand_n/s/w/e_end_a`, `_mid`, `_end_b`, plus `flag_0` and
  `flag_1`. The approved north look carries through all four directions:
  five 12 px bench rows and a green-and-cream awning. Middle pieces repeat.
- Round 12: `butterfly_0/1/2`, 12×10, white/grey, no sprite shadow.

## Previews made from the delivered PNGs

- `round10_ramps_all_3x.png`
- `round10_boosts_all_3x.png`
- `round10_starts_all_3x.png`
- `round11_stand_n_sample_3x.png`
- `round11_stands_all_3x.png`
- `round11_flags_sample_4x.png`
- `round12_butterflies_6x.png`

## Generation and rebuild

Built-in imagegen mode supplied visual references. Prompts requested an
empty five-step wood stand with a green-and-cream scalloped awning, and two
white race-pennant wave frames. The approved long ramp continues to use its
saved imagegen source in `round10_ramp_imagegen_reference.png`. Final assets
were drawn or adapted at their native sizes, with binary alpha and
nearest-neighbour previews. Rebuild commands:

```sh
.venv/bin/python3 tools/art/rcprix_garden_round10_finish.py
.venv/bin/python3 tools/art/rcprix_garden_round11_sample.py
.venv/bin/python3 tools/art/rcprix_garden_round11_finish.py
.venv/bin/python3 tools/art/check_rcprix_art.py
```

The full checker reports **110/110 files present, 0 problems**.
