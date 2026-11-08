# The designer's next round (2026-11-07): dress-ups and cases

**The two briefs:**
- docs/kami_dressup_pixel_brief.md: floaters, under items and head items, as pixel art.
- docs/kami_cases_brief.md: six device cases.

## The quality bar

Everything must look like it was made with the spirits and the hokora, at the size the game shows
it. A picture that looks good big is not enough.

- Judge every piece at game size: the dress-ups shrunk 4x on the spirit, the cases in
  `tools/art/case_preview.py`'s picture.
- **One look:** the October spirits' soft gloss and plum outline for the dress-ups; the device's
  chunky pixel for the cases.

## How we work this round: a pilot first

**1. Pilot (send it on its own and wait for our OK):**
- **Dress-ups:** floaters 1 (hitodama), 4 (goldfish) and 5 (paper crane); the zabuton in its three
  sizes; the sugegasa in its two sizes. Draw them on the sheet in their own rows and leave the rest
  empty.
- **Cases:** Torii and Seigaiha, with their previews.

We check the pilot at game size, on the spirits in the shrine and on the device. The user approves
it before you go on.

**2. The rest,** in the same style:
- the other floaters, under items and head items;
- the other four cases.

**3. Deliver each part to its own folder** as the briefs say. Keep every earlier round.

## Folders

| What | Template / tools | Deliver to |
|------|------------------|-----------|
| Dress-ups | `docs/mockups/spirits/dressup_pixel_brief/` | `docs/mockups/spirits/dressup_pixel/` |
| Cases | `docs/mockups/cases_brief/`, `tools/art/case_preview.py` | `docs/mockups/cases/round1/<id>/` |

Don't touch `textures/`, `scenes/`, `scripts/` or `data/`. Nothing goes into the game until the user
has seen it.
