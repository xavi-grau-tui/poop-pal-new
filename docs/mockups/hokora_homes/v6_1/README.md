# Homes v6.1 art handoff

These are review assets for the tech team. They are not installed in `textures/pet/shrine_new/` yet. The new paintings were made with the built-in ImageGen tool; the Swift tools only crop, scale with nearest neighbour, place layers, and mark bell hooks. High-resolution sources are retained beside the exports.

## Use these files

| Home | Revision |
| --- | --- |
| `golden/` | Taller, more detailed front; new one-piece table; bell and two beads |
| `ruined_night/` | Approved v6 building retained; new one-piece table; bell and two beads |
| `tree_hollow/` | Approved tree retained; new front-face stump; bell and two beads |
| `ramen_stall/` | Curtains retained, round wheels; new one-piece table; bell and two beads |
| `moon/` | v5 arch, pillars, room and details restored exactly; bell and two beads; bell hook moved onto the arch |
| `capsule_apartment/` | Roof/handle repaint; windows and opening retained; bell and two beads; outside-left hook added |
| `arcade_cabinet/` | Marquee retained, central control recess restored, cabinet pass; bell and two beads; hook added |
| `neon_cyber/`, `bathhouse/`, `fire/` | Approved v6 homes and tables stay in place; only the new bell and beads are here |

For revised homes, `front.png`, `inside.png`, `glass.png` where present, `table.png` where revised, `guide.png`, `icon.png`, and `preview_8x.png` are in each home folder. The three new table paintings and the Tree stump are also grouped in [`tables/all_tables_4x.png`](tables/all_tables_4x.png). Each home has `bell.png` (76×86), `bead_1.png` and `bead_2.png` (48×68), and `bell_preview_8x.png` showing the bell with five alternating beads next to its current lantern. Source sheets are in `bells/<home>/source_sheet.png`.

The orange dot in `guide.png` marks the bell hook. For Moon, Capsule and Arcade its revised location is on a visible arch/bracket. The other hooks keep their established positions. The left lantern and spirit opening are clear in the revised fronts. Golden, Capsule, Arcade and Ramen were checked against the full 92×90 spirit safety area: 8,280 of 8,280 pixels remain transparent.

The six already approved one-piece tables (Neon, Moon, Capsule, Arcade, Fire, Bathhouse) remain in `../v6/tables/`; the forest sanbo remains unchanged. Ruined Night's approved building remains the v6 version. The restored v5 Moon front was already 204 px wide within the 220 px canvas, so preserving it at that width gives the requested wider look relative to the v6 revision without changing its features.

## ImageGen prompt set

- Tables: edit each v6 table reference into a single solid, front-facing object with a clear top band and supporting body or legs; Tree stump seen straight from the side with a flat top edge, bark, roots and moss; retain each home's palette and dark-plum pixel-art outline.
- Bells: one material-specific bell and two beads per home, on transparent backgrounds, matching the accepted home and lantern colours at the lanterns' pixel density. The bell and beads in each `source_sheet.png` came from one ImageGen pass.
- Homes: edit the existing v5/v6 home front, preserving the accepted silhouette, opening, windows and marquee as specified. Golden gains higher detailed tiers, Capsule gets a cleaner roof and handles, Arcade regains the control recess and cabinet details, and Ramen retains the accepted curtains with round wheels.

These previews are ready for an in-game fit check. The opening masks, table position, and bell-hook clearance should be checked with the live spirit and movable decorations before replacing production textures.
