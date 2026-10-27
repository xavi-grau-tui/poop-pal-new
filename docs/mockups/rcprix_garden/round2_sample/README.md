# Round-two depth sample

These are approval samples only. They do not replace the active Garden pilot art in
`textures/minigames/rcprix/garden/`.

- `corner_se.png` and `straight_h.png` are the two 180×180 road pieces.
- `joined_preview_2x.png` places them together over provisional grass at nearest-neighbour 2×.

The curb uses a whole number of red/white blocks on each piece: 10 px blocks on the straight,
and separate whole counts along the corner's inner and outer curb arcs. At the join, a white
block ends and a red block begins. The centre dashes are centred within six straight periods
and five quarter-arc periods, leaving a gap at the join.

Both pieces use fully opaque or fully transparent pixels. The joined edge has the same occupied
pixels and the same asphalt, outline and side-face colours; only the intentional white-to-red
curb transition differs. The existing checker currently expects identical RGBA colours at every
road join, so it will need to recognise this curb phase before the final 76-file delivery.

The asphalt light and dark bands use distance from the road centre. They stay continuous through
the curve and match the straight at the join; there are no angular patch endings.
