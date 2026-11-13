# Tomo Tunes, world 2 (Toy Piano): brief for the designer (round 2, 2026-11-13)

The second world's art. World 1 (the toy xylophone, `docs/mockups/tomo_tunes/round1/`) is in the
game and approved; this brief keeps its delivery and adds what world 1 taught us (equal keys,
straight lanes, no bands on the wall). The message to send is the block below. Reference to
attach: `docs/mockups/tomo_tunes/in_game_world1_play.png` (world 1 as it looks in the game).

```
TOMO TUNES - WORLD 2, THE TOY PIANO (one picture first, then its layers)

World 1, the toy xylophone, is in the game and it looks great: thank you. in_game_world1_play.png
shows it running (we pixelate your painting and move the pieces on the beat). Now the second
world, same recipe, with three changes we learned from the first.

THE IDEA
A child's TOY PIANO, the small wooden kind with a few big chunky keys, in the same toy-room
family as world 1 but clearly ANOTHER PLACE: a different corner of the house and a different
light. World 1 was a sunny morning; this one is a late afternoon going to evening: warmer and
lower light, long shadows, a lamp or a paper lantern already on. Calm, cosy, a little quieter in
mood than world 1 (this world's songs are not all cheerful: some are thoughtful, one is a bit
mysterious). Soft, warm, Japanese toys again, but DIFFERENT ones from world 1 (no kokeshi,
daruma, maneki-neko, ball or top this time). Ideas that move well on a beat: a wind-up tin
robot, a wooden train, a paper crane mobile, a jack-in-the-box, a row of nesting dolls, a toy
metronome, a music-loving teddy. The falling notes must stay the brightest thing on screen.

THE LAYOUT (1900 x 1896 = the game's screen at 2x; same as world 1)
- The piano sits at the bottom, seen from the front and a little from above. It has exactly
  THREE BIG KEYS, side by side, and these are the game's three buttons.
- NEW 1: THE THREE KEYS ARE THE SAME SIZE. Each about 370 px wide and 140 px tall, their centres
  at x = 517, 953 and 1388, their middle at y = 1635. Left key pink, middle yellow, right mint.
- NEW 2: THE THREE LANES ARE THE SAME WIDTH AND GO STRAIGHT UP from the keys (no perspective
  slant, no lanes that narrow towards the back). A note falls in a straight vertical line onto
  the middle of its key. Whatever the piano's body does behind the keys (its lid, its top), it
  must not suggest slanted tracks.
- NEW 3: PAINT NO COLOURED BANDS ON THE WALL. The game draws the lanes' light itself. Keep the
  wall behind the three lanes calm (x from about 330 to 1570, y from 200 to 1180): no toys, no
  strong patterns there.
- The top strip (0-220) is the game's score band: keep it calm.
- Free for the picture: the two side margins (shelves, toys) and the floor around the piano.

STEP 1 - ONE PICTURE (send this first, we approve it before step 2)
tomo_piano_mockup.png, 1900 x 1896: the screen in the middle of a song: the room, the toy piano
with its three keys, the toys, and four or five notes falling. THIS WORLD IS ABOUT PRESSING TWO
KEYS AT ONCE, so show it: two notes falling side by side at exactly the same height in two
lanes, and one single note elsewhere. Paint big and smooth, as before; we make the pixels.
Light from the top left, soft shadows under everything.

STEP 2 - THE SAME PICTURE IN LAYERS (after our OK), each a PNG at 1900 x 1896 with transparency,
registered exactly as in world 1:
1. room.png: wall, window, floor, light. NOTHING that moves. Also room_overscan.png (80 px more
   on every side), as you did last time.
2. piano.png: the toy piano's body WITHOUT its three keys.
3. key_low.png, key_mid.png, key_high.png: each key alone, in place, all three the same size.
   Plus the same three LIT (key_low_lit.png ...): the key glowing as when it is pressed.
4. Toys: 4 to 6, each ALONE in its own file, in place (toy_robot.png ...). Any part that should
   move by itself gets its own file too, like the cat's paw last time (toy_robot_arm.png, the
   metronome's needle, the jack-in-the-box's head).
5. note_low.png, note_mid.png, note_high.png, note_gold.png: the falling notes, 130 x 130. You
   may keep world 1's wooden beads exactly, or give this world its own (a small round felt
   hammer head reads well for a piano). One per lane in its colour, plus gold.

RULES (as before)
- Nothing that moves is painted into a layer that stays still.
- Each moving piece is whole: paint what is hidden behind it too.
- No text, no numbers, no musical staff lines, no sheet music with readable notes.
- Do not put the spirit in: the game adds it (top left, over the window area: keep that corner
  simple).
- Send into docs/mockups/tomo_tunes/round2/ only, with a short README like last time. Please do
  not touch textures/, scenes/, scripts/ or data/.

HOW IT WILL MOVE
On every beat the toys bob, rock or wave. A key dips when the player presses it and lights when
the note is hit. When the player misses, the room dims and the toys nearly stop.
```
