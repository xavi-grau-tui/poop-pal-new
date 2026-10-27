# Drink icon redesign options

The 15 drinks in `scripts/DrinkLibrary.gd` each have two new 32×32 PNG options in
`option_a/` and `option_b/`. The three sheets show the current icons and both
options at native size and a nearest-neighbour enlargement. These are previews;
the live `textures/drinks/` files are unchanged by this redesign.

## Export rules

- Each icon's longest opaque dimension is 30 pixels, centered with at least one
  transparent pixel on every side.
- Alpha is binary: every pixel is fully opaque or fully transparent.
- The outside edge is a continuous one-pixel dark red-brown outline, #320E12.
- The exporter samples the generated art with nearest-neighbour scaling and
  retains the colored interior shading.

The export script is `tools/art/export_drink_options.swift`. It takes a JSON
array containing `name`, `file`, `a` and `b` source paths, followed by an
output directory. It checks size, alpha and footprint when writing sprites.

## Image generation brief

Built-in ImageGen produced one large transparent concept per option. Each used
the current Green Tea, Shrine Water and Energy Drink PNGs as exact style
references plus the current subject icon. The common prompt required a single
game drink sprite with large flat color areas, rich three-tone shading, a
continuous #320E12 outline, no speckles, and a centered 30-pixel footprint.
Option A refined the existing vessel; Option B explored an alternate vessel or
silhouette. The native PNGs here are the deliverables.

| Drink | Option A | Option B |
| --- | --- | --- |
| Shrine Water | Clear water cup | Blue-rimmed water bowl |
| Barley Tea | Amber tea in the Green Tea cup shape | Brighter amber tea in the same cup shape |
| Coconut Water | Halved coconut with straw | Upright cut coconut with straw |
| Cola | Classic bottle | Short can |
| Ramune | Glass bottle with marble | Tilted bottle with prominent marble |
| Cream Soda | Tall mint soda float | Shorter mint soda float |
| Green Tea | Handmade tea cup | Shallower tea cup |
| Coffee | Sturdy ceramic mug | Stout cafe cup |
| Energy Drink | Blue lightning can | Red-orange lightning can |
| Milk | White milk bottle | Full glass |
| Bubble Tea | Sealed tall cup | Wider lidded cup |
| Milkshake | Strawberry shake glass | Wider diner shake glass |
| Mikan Juice | Glass with wedge and straw | Glass with large wedge |
| Peach Juice | Peach bottle | Peach juice glass |
| Smoothie | Pink berry smoothie | Green fruit smoothie |
