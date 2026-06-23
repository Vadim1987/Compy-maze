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

EDITOR_ROWS = 2

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

-- Light off-white canvas with dark-grey grid lines: visible
-- but soft (spec: light gray or off-white background).

CANVAS_BG = { 0.8, 0.8, 0.78 }

GRID_LINE = {
  width = 1,
  color = { 0.4, 0.4, 0.4 }
}

-- Command hint shown to the right of the canvas, like maze.
-- The shared compass already covers N/S/E/W and L/R/F/B.

DRAW_LEGEND = readfile("legend.txt")
