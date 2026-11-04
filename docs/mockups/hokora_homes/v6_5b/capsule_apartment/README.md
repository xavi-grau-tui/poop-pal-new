# Capsule Pod v6.5b

Four registered 220 × 220 layers, in game draw order: `trays.png`, player ornaments, `glass.png`, `front.png`. The green shelf dots and unchanged bell/lantern hooks are in `guide.png`.

The two white arches, grey ceiling bands and round knob come from the approved v6.2 front, widened by the same eight columns used in v6.4. The window cuts start at row 78, stop at row 156, and end before each arch's outer outline. Every pixel of `front.png` outside the two new cutouts matches that widened approved front.

`preview_8x.png` and `icon.png` show the assembly with the existing central room and table. `qa_magenta_8x.png` shows it over magenta; there are no magenta pixels inside either side-window region. `tools/art/hokora_capsule_v6_5b_export.swift` rebuilds and checks the files.

The built-in ImageGen edit used v6.5 as its edit target and v6.2 as the arch reference. Its visual study is at `../source_imagegen.png`. The final grid uses the original approved arch pixels to guarantee exact frame preservation.
