-- constants.lua

-- Animation durations in seconds

ANIM = {
  move_time = 0.45,
  turn_time = 0.45,
  bump_frac = 0.5,
  fail_pause = 0.5,
  win_time = 0.5
}

-- Player sprite box; cell_fill < 1 leaves room
-- for the bump animation to show movement.

PLAYER = {
  sprite_w = 100,
  sprite_h = 100,
  cell_fill = 0.56
}

-- Track animation parameters in transpiled sprite
-- coordinates (100 x 100 box).
-- radius: distance from track center to robot
-- rotation axis (sprite center).
-- bar_step: vertical distance between adjacent
-- bars in a track.

TRACK = {
  radius = 35.9,
  bar_step = 14.5
}

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

-- Movement trail style

TRACE = {
  radius_frac = 0.08
}

-- Legends

LEGEND_FULL = readfile("legend.txt")

-- Keyboard macro limits

MAX_MACRO_LEN = 7

-- Macro letters list above legend

MACRO_LINE_LEN = 8

-- Maximum echo lines visible on screen.

MAX_ECHO_LINES = 16

-- Alpha for non-highlighted echo characters.

ECHO_DIM_ALPHA = 0.4

-- Primitive commands 

PRIMITIVES = {
  N = true,
  E = true,
  S = true,
  W = true,
  F = true,
  B = true,
  L = true,
  R = true,
  ["."] = true
}

-- Celebrate message: prefix + Tab keycap + suffix

CELEBRATE_PREFIX = "Congratulations! Press "
CELEBRATE_SUFFIX = " to proceed."

-- Failed-run modal: prefix + Tab keycap + suffix.
-- A calm "not yet", never punitive.

FAILED_MISS_PREFIX = "Goal not reached. Press "
FAILED_CRASH_PREFIX = "Crashed. Press "
FAILED_SUFFIX = " to try again."
