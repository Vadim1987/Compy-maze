-- maze_decorations.lua

-- Transpiled maze sprites and backgrounds. Each
-- require(...) loads the module once; the module returns
-- a draw function callable every frame without
-- re-creating paths.

-- Box sprite drawn by draw_boxes.
-- Rendered at origin of a BOX.sprite_w by
-- BOX.sprite_h box; caller positions and scales.

box_sprite = require("BOX_03")

-- Target sprite drawn by draw_goals.
-- Rendered at origin of a TARGET.sprite_w by
-- TARGET.sprite_h box; caller positions and scales.

target_sprite = require("TARGET_02")

-- Background draw functions. Each draws over the
-- whole screen. Assign one to a level's
-- `background` attribute in levels.lua. If a level
-- has no `background`, draw_walls falls back to a
-- solid blue fill.

bg1 = require("LABIRINT_NEW_01")
bg2 = require("LABIRINT_NEW_02")
bg3 = require("LABIRINT_NEW_03")
bg4 = require("LABIRINT_NEW_04")
bg5 = require("LABIRINT_NEW_05")
