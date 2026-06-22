-- core_constants.lua

-- Constants shared by every command-driven program (maze,
-- draw, ...). Program-specific constants live alongside in
-- <app>_constants.lua, which may extend the tables here and
-- must be loaded after this file.

-- Animation durations in seconds.

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

-- Movement trail style.

TRACE = { radius_frac = 0.08 }

-- Maximum echo lines visible on screen.

MAX_ECHO_LINES = 16

-- Alpha for non-highlighted echo characters.

ECHO_DIM_ALPHA = 0.4

-- Core command set: absolute moves N/E/S/W and relative
-- move/turn F/B/L/R. Each program extends this with its
-- own commands in <app>_constants.lua.

PRIMITIVES = {
  N = true,
  E = true,
  S = true,
  W = true,
  F = true,
  B = true,
  L = true,
  R = true
}

-- Commands that change state instead of moving, so they
-- emit no movement ping. Empty in the core; each program
-- adds its own silent commands.

SILENT_CMDS = { }
