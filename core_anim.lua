-- core_anim.lua

-- Grid geometry and the generic animation engine
-- (move/turn) shared by every command-driven program.

-- Grid

GRID = { }

-- Sprite scale, bump distance, trace radius and push
-- path, all derived from the current cell size.

function init_cell_metrics()
  local long_side = math.max(PLAYER.sprite_w, PLAYER.sprite_h)
  GRID.scale = GRID.cell * PLAYER.cell_fill / long_side
  GRID.bump_dist = (GRID.cell - long_side * GRID.scale) / 2
  GRID.trace_r = GRID.cell * TRACE.radius_frac
  GRID.push_path = GRID.bump_dist + GRID.cell + GRID.bump_dist
end

function init_grid(rows, cols, opts)
  GRID.rows = rows
  GRID.cols = cols
  local o = opts or {}
  local m = o.margin or 0
  local w, h = gfx.getDimensions()
  local avail_w = w - m - (o.pad_right or 0)
  local avail_h = h - 2 * m - (o.pad_bottom or 0)
  GRID.cell = math.min(avail_w / cols, avail_h / rows)
  local slack = (avail_w - GRID.cell * cols) / 2
  GRID.offset_x = m + slack
  GRID.offset_y = m + (avail_h - GRID.cell * rows) / 2
  init_cell_metrics()
end

function cell_top_left(col, row)
  local x = GRID.offset_x + (col - 1) * GRID.cell
  local y = GRID.offset_y + (row - 1) * GRID.cell
  return x, y
end

function cell_center(col, row)
  local x, y = cell_top_left(col, row)
  local half = GRID.cell / 2
  return x + half, y + half
end

function pos_key(col, row)
  return col + GRID.cols * row
end

-- Animation execution

function start_turn(cmd, ref)
  start_anim("turn", ANIM.turn_time, ref)
  if cmd == "R" then
    player.anim.target_dir = TURN_RIGHT[player.dir]
  else
    player.anim.target_dir = TURN_LEFT[player.dir]
  end
  player.last_turn = cmd
end

function move_cmd_target(cmd)
  local dir = player.dir
  if cmd == "B" then
    dir = OPPOSITE_DIR[dir]
  end
  local d = DIR_DELTA[dir]
  return player.col + d.x, player.row + d.y
end

function start_forward(cmd, ref, tc, tr)
  start_anim("move", ANIM.move_time, ref)
  player.anim.target_col = tc
  player.anim.target_row = tr
  player.anim.move_cmd = cmd
end

function finish_move(a)
  player.col = a.target_col
  player.row = a.target_row
  if a.move_cmd == "F" then
    table.insert(player.traces, {
      c1 = a.from_col,
      r1 = a.from_row,
      c2 = a.target_col,
      r2 = a.target_row
    })
  end
end

-- after_step() is supplied by the app and called by the
-- finishers below once a move or turn settles: the maze
-- checks its goal, draw does nothing. The core names it
-- but never defines it.

ANIM_FINISHERS = { }

function ANIM_FINISHERS.turn(a)
  player.dir = a.target_dir
  after_step()
end

function ANIM_FINISHERS.move(a)
  finish_move(a)
  after_step()
end

function finish_anim()
  local a = player.anim
  player.anim = nil
  ANIM_FINISHERS[a.kind](a)
end

-- Pull the next queued command and dispatch it through
-- the app's CMD_HANDLERS. Runs once per idle frame from
-- love.update when no animation is in flight.

function execute_next()
  local cmd, ref = dequeue()
  local fn = CMD_HANDLERS[cmd]
  if fn then
    fn(cmd, ref)
  end
end

-- Update

function advance_anim(dt)
  player.anim.time = player.anim.time + dt
  if player.anim.kind == "win"
       and player.anim.goal
  then
    player.anim.goal.radius = 1 - anim_progress()
  end
  if player.anim.duration <= player.anim.time then
    finish_anim()
  end
end

-- Track offset updaters, one per animation kind.
-- Each adds a delta to player.track_offset_l/r
-- based on the animation's duration and direction.

TRACK_UPDATE = { }

function TRACK_UPDATE.move(a, dt)
  local sign = (a.move_cmd == "F") and -1 or 1
  local d = sign * GRID.cell * dt / (a.duration * GRID.scale)
  player.track_offset_l = player.track_offset_l + d
  player.track_offset_r = player.track_offset_r + d
end

function TRACK_UPDATE.turn(a, dt)
  local right = a.target_dir == TURN_RIGHT[a.from_dir]
  local sign = right and 1 or -1
  local d = TRACK.radius * (math.pi / 2) * dt / a.duration
  player.track_offset_l = player.track_offset_l - sign * d
  player.track_offset_r = player.track_offset_r + sign * d
end

function update_track_offsets(dt)
  local fn = TRACK_UPDATE[player.anim.kind]
  if fn then
    fn(player.anim, dt)
  end
end
