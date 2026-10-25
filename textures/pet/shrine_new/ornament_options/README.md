NEW SHRINE hanging ornaments

The active new-shrine textures are one directory up:
- lantern.png: glowing paper lantern
- bell.png: gold suzu bell
- bead_red.png / bead_white.png: modular red and ivory ribbon sections

The previous new-shrine textures are preserved in previous/.
source/ holds the full generated images. preview_new_shrine.png is a static composition on the NEW SHRINE artwork; motion and depth are supplied by scripts/shrine.gd when DevLaunch.new_shrine is enabled.

2026-10-23: oval_beads/ preserves the first outlined-oval NEW SHRINE ornament version. The two lanterns hang beside the orange roof blocks. Six outlined red and ivory oval beads hang below a simplified bell at the far left eave. oval_beads/source/ contains the full image-generation outputs; oval_beads/{bead_red,bead_white,bell}.png contains those pixel-sized sprites. broad_ribbon/ and before_two_lanterns/ preserve earlier concepts. The regular SHRINE textures are unchanged. Full app-viewport preview: /private/tmp/new-shrine-oval-beads-screen-refreshed/pet.png.

2026-10-23 revision: paler_slim_ovals/ supplies the active bead_red.png and bead_white.png. The bead sprites are narrower and lighter, the chain spacing is tighter, and its first bead meets the unchanged simple bell. Final app-viewport preview: /private/tmp/new-shrine-slim-overlap-final/pet.png.

2026-10-23 revision: the bead sprites now have a one-step thicker dark outline. In NEW SHRINE each oval rotates to follow the tangent of its neighboring links, and a narrow plum connector runs from the bell through the chain so the assembly stays visually joined while swinging. Full view: /private/tmp/new-shrine-connected-beads/pet.png; tilted view: /private/tmp/new-shrine-connected-beads-tilt/pet.png.

2026-10-23 revision: restored the earlier hanging gold bell from proposed_three_hangers/ and softened the plum outlines on the bell and oval beads. The active bell asset is now a palette-adjusted copy; the original concept remains preserved in proposed_three_hangers/.

2026-10-23 revision: reduced the NEW SHRINE bead chain's tilt response, initial kick, settling acceleration, and ambient sway so it feels heavier. Lantern physics keep their existing settings. Tilt comparison: /private/tmp/new-shrine-heavy-chain-tilt-v2/pet.png.
