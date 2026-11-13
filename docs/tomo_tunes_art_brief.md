# Tomo Tunes, world 1 (Toy Xylophone): brief for the designer (round 1, 2026-11-13)

The first art for the music game. One world as the test; the other five follow once this one
works in the game. The message to send is the block below. Files it refers to:
`docs/mockups/tomo_tunes/xylophone_guide.png` (the layout) and `today.png` (what is being replaced).

Our side afterwards: we pixelate the paintings to the game's grid, cut them, and make them move in
code (everything that moves, moves on the song's beat, which the game knows exactly).

```
TOMO TUNES - WORLD 1, THE TOY XYLOPHONE (round 1: one picture first, then its layers)

A new game needs its first look. It is the music game: notes fall down three lanes and the player
taps them as they land. The player is PLAYING A TOY XYLOPHONE: every note that falls is a note of
the xylophone in the song. today.png shows the game now (flat purple, three rings): all of it is
to be replaced.

THE IDEA
A child's wooden toy xylophone on a shelf of a toy room, seen from the front, a little from above,
in warm morning light (the song is called "Wooden Steps": sunny, gentle, a first morning). The
xylophone IS the play field: its three big wooden bars are where the notes land. Around it, a few
toys that will bounce to the music. It belongs to the same world as the shrine and the spirits:
soft, warm, Japanese toys (kokeshi, a daruma, a paper balloon, a wooden top, a small maneki-neko),
cream and warm wood with a few bright accents. Calm enough that falling notes are always the
brightest thing on the screen.

THE LAYOUT IS FIXED (xylophone_guide.png, 1900 x 1896 = the game's screen at 2x)
- Three lanes, top to bottom. Notes fall inside them.
- At y = 820 of 948 each lane ends on a round target: this is where a XYLOPHONE BAR goes, one per
  lane, wide and clear. Left bar = LOW notes (the longest, biggest bar), middle = MID, right =
  HIGH (the shortest). Colours: left pink, middle yellow, right mint (the game's three buttons).
- The top strip (0-110) is the game's score band: keep it calm, nothing important there.
- Free for the picture: the side margins and everything BEHIND the lanes. The lanes themselves
  can be the xylophone's long body going back into the picture (like a road seen from above), or
  simply a calm area of the shelf: your call, but the three lanes must stay readable.

STEP 1 - ONE PICTURE (send this first, we approve it before step 2)
tomo_xylophone_mockup.png, 1900 x 1896: the whole screen as it would look in the middle of a song:
the room, the xylophone with its three bars at the bottom, three or four notes falling in the
lanes, the toys around. Paint it big and smooth, as you did for the race game: we turn it into
pixel art ourselves. Light from the top left, soft shadows under everything.

STEP 2 - THE SAME PICTURE IN LAYERS (after our OK), each a PNG at 1900 x 1896 with transparency,
so we can move them:
1. room.png: the far background (wall, window, light), with NOTHING that should move. Paint it a
   little past the edges (about 80 px more on every side: the game tilts the view).
2. shelf.png: the shelf or table and the xylophone's body, without the three bars.
3. bar_low.png, bar_mid.png, bar_high.png: each bar alone, in place. Plus the same three LIT
   (bar_low_lit.png ...): the bar glowing as when it is struck.
4. toys: each toy that bounces ALONE in its own file, in place, 4 to 6 of them (toy_daruma.png,
   toy_kokeshi.png ...). Things that are good at moving on a beat: a daruma rocking, a kokeshi
   nodding, a paper balloon breathing, a wind-up bird pecking, a small drum-monkey, a row of
   wooden ducks.
5. note_low.png, note_mid.png, note_high.png: the falling note, about 130 x 130, one per lane in
   its colour. A round wooden mallet head or a wooden bead reads well. Plus note_gold.png (a
   golden one, for a secret).
6. mallet.png (optional): a small mallet that we swing onto a bar when the player hits.

RULES
- Nothing that moves is painted into a layer that stays still (no toy baked into room.png).
- Each moving piece is whole: paint what is hidden behind it too.
- No text, no numbers, no musical staff lines.
- Do not put the spirit in: the game adds it.
- Send into docs/mockups/tomo_tunes/round1/ only. Please do not touch textures/, scenes/,
  scripts/ or data/.

HOW IT WILL MOVE (so you can judge what to make separate)
On every beat the toys bounce a little, on the first beat of each bar a bit more. The bar the
player hits lights up and the mallet strikes it. When the player misses, the room dims slightly.
When they play well for a while, more toys join in. So: more separate toys = more to bring in.
```
