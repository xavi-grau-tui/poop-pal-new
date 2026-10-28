# RC Prix · Garden: notes for round 12 (butterflies)

A few butterflies flutter over the lawn and the track. The game moves them, flaps their wings and
gives them their shadows, so only the sprite frames are needed.

- `butterfly_0.png`, `butterfly_1.png`, `butterfly_2.png`, 12×10 each: one butterfly seen from
  above, wings **open**, **half closed** and **closed** (a thin sliver). The game plays them as
  0-1-2-1 to flap.
- Draw the wings **white or very light grey**, with shading and a pattern (spots or edge bands)
  in greys. The game tints them in a few soft colours, so one drawing makes them all. The body is
  dark, a thin line down the middle with two tiny antennae.
- The same style as the rest: clean pixels, outline `#281E28`, light from the top left. No shadow.

Boxes in `templates/4_sprites.png`. Test: the three frames side by side at 6×, and the checker
at 0 problems for these files.
