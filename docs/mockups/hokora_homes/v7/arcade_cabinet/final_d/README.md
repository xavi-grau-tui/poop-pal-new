# Arcade Cabinet v7 final_d

`front.png` uses the exact 220 × 220 alpha outline and screen opening from `final_c_wide/front.png`. ImageGen supplied the finer red, cream, gold and blue material finish in `source_imagegen.png`. The export script transfers that finish onto the locked grid. The sign, controls, coin grille, proportions and positions stay in place.

`trays.png` is now two straight-on **front faces only**. Each has a cream edge and red trimmed face, without the slanted cream top or red side surface. The game can stack the faces backward to form depth. `inside.png` retains its exact `final_c_wide` alpha and position, with matched left/right recess shading. `guide.png` retains its exact registration.

Draw order: inside, front, game-built tray depth, trays, ornaments. The game draws the offering table in the clear middle of the deck.

`preview_8x.png` is the assembled view; `icon.png` is 96 × 96. The four game layers are 220 × 220 and use hard alpha. Rebuild with `tools/art/hokora_arcade_v7_final_d_export.swift`.
