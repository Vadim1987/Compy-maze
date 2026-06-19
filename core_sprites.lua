-- core_sprites.lua

-- Transpiled robot sprite, shared by every program.
-- Each require(...) loads the module once; the module
-- returns a draw function callable every frame without
-- re-creating paths.

-- Player sprite parts drawn by draw_player_at.
-- All four rendered in the same PLAYER.sprite_w by
-- PLAYER.sprite_h box; caller centers, rotates and
-- scales. Drawn in z-order back -> tracks -> front.

robot_back = require("ROBOT_03_a")
robot_track_l = require("ROBOT_03_b1")
robot_track_r = require("ROBOT_03_b2")
robot_front = require("ROBOT_03_c")
