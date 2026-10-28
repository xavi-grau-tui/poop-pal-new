# RC Prix: notes for round 23 (the racing font, redrawn crisper)

The racing font (round 17b, `textures/minigames/rcprix/font/`) works in the game: the race messages
("LAP 2", "FINAL LAP", "GO!", "FINISH!", "missed!", "sturdy cars smash!"…) are written with it, letter
by letter. But the user finds it **strange and not defined enough.** On screen each font pixel is
4×4, so every flaw shows.

## What's wrong now (measured)

- **The holes are slits:** A, P, O, G, R, B, D, 0, 6, 8 and 9 have holes only 1–2 px wide, so they
  read as blobs.
- **The strokes vary in thickness,** and the slant steps unevenly.
- **Some characters look alike:** L and I, O and 0.
- **The three colour bands** cut straight across each letter and don't follow its shape.

## What we want: crisp, chunky, arcade-racing lettering

- **Height:** capitals **16 px** tall, plus the outline and the drop (below), on a **24 px** tall
  canvas as now.
- **Strokes:** an even **3 px** everywhere, no 1 px parts.
- **Holes:** at least **3 px wide and 4 px tall**, so every counter is open and clear.
- **Slant:** none, or exactly 1 px every 4 rows on every glyph.
- **Outline:** **2 px** of #281E28 all round.
- **3D drop:** a dark **2 px** extrusion down and to the right, the racing-title look.
- **Colours:**
  - a 2 px light top edge;
  - one main fill (warm yellow);
  - a darker bottom band of about 4 px, following the letter's shape;
  - at most 5 colours, including the outline.
- **Distinct characters:** I with serifs, L with a long foot, 0 narrower than O (or with a slash),
  1 with a flag, 5 vs S and 8 vs B clearly different.
- **Widths:** every digit the **same width** (the timer must not jump). Letters may vary in width.
- **Clean:** fully opaque or fully transparent pixels, no lone pixels, no soft edges.

## Files

The same **44** files and names, into `textures/minigames/rcprix/font/`:
- `0`–`9`, `A`–`Z`;
- `apos`, `colon`, `comma`, `dash`, `dot`, `excl`, `quest`, `slash`.

Each is **24 px tall**, as wide as the glyph needs (the game spaces them 2 px apart).

## How to work

1. **Look sample first:** `L A P 1 2 3 G O ! F I N S H` (14 glyphs). Show them as **"LAP 2"**,
   **"GO!"**, **"FINISH!"** and **"FINAL LAP"** at 4×, made from the delivered PNGs, next to the
   current font.
2. Then the other 30.
3. **The PNGs you deliver must be the pictures you show.** Draw on the grid itself (a 24 px canvas);
   don't shrink a bigger picture. This font is small enough to draw pixel by pixel.
