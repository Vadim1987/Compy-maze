-- draw_constants.lua

-- Draw-only constants, plus draw's addition to the command
-- sets defined in core_constants.lua (loaded first).

-- The canvas: one fixed grid, no levels.

CANVAS = {
  rows = 8,
  cols = 8
}

-- The runtime draws its command editor as a band across the
-- bottom (a prompt, the input line and a status line) -- three
-- text rows, measured on device. Reserve that height so the
-- 8x8 grid, whose robot starts bottom-left, sits above the
-- band, as the runtime's own drawable height drops its rows.

EDITOR_ROWS = 3

-- Robot start: bottom-left cell, facing north.

START = {
  col = 1,
  row = 8,
  dir = "N"
}

-- Draw's clear-canvas command layered on the core set.
-- Silent: it resets state instead of moving, so no ping.

PRIMITIVES.C = true
SILENT_CMDS.C = true

-- Subtle canvas grid: faint, thin lines.

GRID_LINE = {
  width = 1,
  alpha = 0.15
}
