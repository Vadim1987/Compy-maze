-- maze_constants.lua

-- Maze-only constants, plus the maze's additions to the
-- command sets defined in core_constants.lua (loaded
-- first).

-- Box sprite box. cell_fill = 1: box fully covers
-- its cell, matching the current rectangle behavior.

BOX = {
  sprite_w = 100,
  sprite_h = 100,
  cell_fill = 1
}

-- Target sprite box.

TARGET = {
  sprite_w = 100,
  sprite_h = 100,
  cell_fill = 0.9
}

-- Legend shown in the bottom-right corner.

LEGEND_FULL = readfile("legend.txt")

-- Keyboard macro limits.

MAX_MACRO_LEN = 7

-- Macro letters list above legend.

MACRO_LINE_LEN = 8

-- Maze-only navigation commands layered on the core set:
-- "." next level, "," previous level, "<" exit to menu.
-- All silent (no movement ping).

MAZE_CMDS = { ".", ",", "<" }

for _, c in ipairs(MAZE_CMDS) do
  PRIMITIVES[c] = true
  SILENT_CMDS[c] = true
end

-- Celebrate message: prefix + Tab keycap + suffix.

CELEBRATE_PREFIX = "Congratulations! Press "
CELEBRATE_SUFFIX = " to proceed."

-- Failed-run modal: prefix + Tab keycap + suffix.
-- A calm "not yet", never punitive.

FAILED_MISS_PREFIX = "Goal not reached. Press "
FAILED_CRASH_PREFIX = "Crashed. Press "
FAILED_SUFFIX = " to try again."
