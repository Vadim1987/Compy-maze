-- main.lua

-- Maze game: guide a player to the destination!

require("constants")
require("controls")
require("graphics")
require("levels")
require("player")
require("keyboard_graphics")
require("macro")
require("script")
require("menu")

sfx = compy.audio

-- Echo of entered commands (one line per Enter).

echo_lines = { }

-- Marker for queue entries with no source (keyboard
-- input on non-editor levels).

NO_REF = { }

-- Grid

GRID = { }

function init_grid(rows, cols)
  GRID.rows = rows
  GRID.cols = cols
  local w, h = gfx.getDimensions()
  GRID.cell = math.min(w / cols, h / rows)
  GRID.offset_x = (w - GRID.cell * cols) / 2
  GRID.offset_y = (h - GRID.cell * rows) / 2
  local long_side = math.max(PLAYER.sprite_w, PLAYER.sprite_h)
  GRID.scale = GRID.cell * PLAYER.cell_fill / long_side
  GRID.bump_dist = (GRID.cell - long_side * GRID.scale) / 2
  GRID.trace_r = GRID.cell * TRACE.radius_frac
  GRID.push_path = GRID.bump_dist + GRID.cell + GRID.bump_dist
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

-- Game State

macros = { }

-- Macros (editor X=... sequences and recorded keyboard
-- macros) carry across levels through a per-level base.
-- Each editor run rebuilds the table from that base, so a
-- definition deleted from the program is dropped; only
-- carried base bindings survive a restart.

function clone_macros(src)
  local t = { }
  for k, v in pairs(src) do
    t[k] = v
  end
  return t
end

level_index = 1
maze = levels[level_index]
cur_controls = editor
cur_progression = portal
cur_legend = nil
cur_grid = false
cur_background = nil

GS = {
  init = false,
  mode = "menu",
  grid = nil,
  goal_map = { },
  box_map = { },
  box_goal_map = { },
  box_goal_count = 0,
  filled_count = 0,
  won = false,
  celebrating = false,
  running = false,
  base_macros = { }
}

-- Parsing: read the maze strings to find the player

CELL_PARSERS = { }

function pos_key(col, row)
  return col + GRID.cols * row
end

CELL_PARSERS["*"] = function(c, r)
  GS.goal_map[pos_key(c, r)] = {
    col = c, row = r, radius = 1
  }
end

CELL_PARSERS["B"] = function(c, r)
  GS.box_map[pos_key(c, r)] = {
    col = c, row = r
  }
end

function CELL_PARSERS.G(c, r)
  GS.box_goal_map[pos_key(c, r)] = {
    col = c,
    row = r
  }
  GS.box_goal_count = GS.box_goal_count + 1
end

function parse_cell(ch, c, r)
  if DIR_DELTA[ch] then
    player_reset(c, r, ch)
    return 
  end
  local fn = CELL_PARSERS[ch]
  if fn then
    fn(c, r)
  end
end

function parse_maze()
  GS.grid = maze
  GS.goal_map = { }
  GS.box_map = { }
  GS.box_goal_map = { }
  GS.box_goal_count = 0
  GS.filled_count = 0
  GS.won = false
  GS.celebrating = false
  for r, row in ipairs(maze) do
    for c = 1, #row do
      parse_cell(row:sub(c, c), c, r)
    end
  end
end

-- Check what is at a grid position

function is_wall(col, row)
  if row < 1 or GRID.rows < row
       or col < 1
       or GRID.cols < col
  then
    return true
  end
  local ch = GS.grid[row]:sub(col, col)
  return ch == "#"
end

function box_at(col, row)
  return GS.box_map[pos_key(col, row)]
end

function push_dir(cmd)
  if cmd == "B" then
    return OPPOSITE_DIR[player.dir]
  end
  return player.dir
end

function can_push(col, row, dir)
  local d = DIR_DELTA[dir]
  local tc, tr = col + d.x, row + d.y
  return not is_wall(tc, tr)
       and not box_at(tc, tr)
end

function win_level(goal, sound)
  start_anim("win", ANIM.win_time)
  player.anim.goal = goal
  sound()
end

function check_goal()
  local k = pos_key(player.col, player.row)
  local g = GS.goal_map[k]
  if g and #player.queue == 0 then
    win_level(g, sfx.win)
  end
end

function check_box_goals(old_key, new_key)
  if GS.box_goal_map[old_key] then
    GS.filled_count = GS.filled_count - 1
  end
  if GS.box_goal_map[new_key] then
    GS.filled_count = GS.filled_count + 1
  end
  if 0 < GS.box_goal_count
       and GS.filled_count == GS.box_goal_count
       and #player.queue == 0
  then
    win_level(nil, sfx.wow)
  end
end

-- Init

function reset_level()
  init_grid(#maze, #(maze[1]))
  parse_maze()
  GS.failed = nil
end

function apply_attrs()
  if maze.controls ~= nil then
    cur_controls = maze.controls
  end
  if maze.progression ~= nil then
    cur_progression = maze.progression
  end
  cur_legend = maze.legend
  if maze.grid ~= nil then
    cur_grid = maze.grid
  end
  cur_background = maze.background
end

function start_level()
  apply_attrs()
  reset_level()
  echo_lines = { }
  GS.crash = nil
  GS.invalid = nil
  GS.program = nil
  GS.running = false
  macros = clone_macros(GS.base_macros)
  cur_controls()
end

function ensure_init()
  if not GS.init then
    GS.init = true
  end
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

function start_bump(cmd, ref)
  local t = ANIM.move_time * ANIM.bump_frac
  start_anim("bump", t, ref)
  player.anim.move_cmd = cmd
end

function start_forward(cmd, ref, tc, tr)
  start_anim("move", ANIM.move_time, ref)
  player.anim.target_col = tc
  player.anim.target_row = tr
  player.anim.move_cmd = cmd
end

function push_duration()
  return GRID.push_path * ANIM.move_time / GRID.cell
end

function start_push(cmd, ref, box)
  local d = DIR_DELTA[push_dir(cmd)]
  start_anim("push", push_duration(), ref)
  sfx.jump()
  local anim = player.anim
  local col, row = box.col, box.row
  anim.move_cmd = cmd
  anim.target_col = col
  anim.target_row = row
  anim.box = box
  anim.box_tc = col + d.x
  anim.box_tr = row + d.y
end

function try_push(cmd, ref, box)
  if can_push(box.col, box.row, push_dir(cmd)) then
    start_push(cmd, ref, box)
  else
    start_bump(cmd, ref)
  end
end

function start_move(cmd, ref)
  local tc, tr = move_cmd_target(cmd)
  if is_wall(tc, tr) then
    start_bump(cmd, ref)
  else
    local box = box_at(tc, tr)
    if box then
      try_push(cmd, ref, box)
    else
      start_forward(cmd, ref, tc, tr)
    end
  end
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

ANIM_FINISHERS = { }

function ANIM_FINISHERS.turn(a)
  player.dir = a.target_dir
  check_goal()
end

function ANIM_FINISHERS.move(a)
  finish_move(a)
  check_goal()
end

-- Remember the crashed token so the editor can keep
-- it red until the next run. Keyboard moves (no source
-- line) leave no marker.

function record_crash(a)
  if not a.line then
    return
  end
  GS.crash = {
    line = a.line,
    col_from = a.col_from,
    col_to = a.col_to
  }
end

function ANIM_FINISHERS.bump(a)
  sfx.lose()
  start_anim("fail", ANIM.fail_pause)
  player.anim.move_cmd = a.move_cmd
  player.anim.line = a.line
  player.anim.col_from = a.col_from
  player.anim.col_to = a.col_to
  record_crash(a)
end

function ANIM_FINISHERS.push(a)
  finish_move(a)
  local old = pos_key(a.box.col, a.box.row)
  GS.box_map[old] = nil
  a.box.col = a.box_tc
  a.box.row = a.box_tr
  local new = pos_key(a.box_tc, a.box_tr)
  GS.box_map[new] = a.box
  check_goal()
  if not player.anim then
    check_box_goals(old, new)
  end
end

-- Level progression

function next_level()
  level_index = level_index + 1
  if #levels < level_index then
    to_menu()
  else
    GS.base_macros = clone_macros(macros)
    maze = levels[level_index]
    local saved_q = player.queue
    local saved_r = player.queue_refs
    local saved_running = GS.running
    start_level()
    player.queue = saved_q
    player.queue_refs = saved_r
    GS.running = saved_running
  end
end

-- Level navigation commands. "." jumps to the next level
-- and "," to the previous one; a leading run collapses into
-- one hop, so "3." / "2," jump three / two levels (clamped
-- to the first and last). Then a fresh editor is presented:
-- a plain jump, not a win -- start_level() sets GS.running
-- false, clears the queue and resets GS.failed, so unlike
-- next_level() we restore nothing and no "goal not reached"
-- fires on arrival. The program ends here (commands after
-- the jump are dropped).

function jump_level(delta)
  local idx = level_index + delta
  if idx < 1 then idx = 1 end
  if #levels < idx then idx = #levels end
  if idx ~= level_index then
    GS.base_macros = clone_macros(macros)
    level_index = idx
    maze = levels[idx]
  end
  start_level()
end

-- Collapse a leading run of the same command in the queue
-- so "3." / "2," become a single multi-level jump.

function take_repeats(ch)
  local n = 1
  while player.queue[1] == ch do
    table.remove(player.queue, 1)
    table.remove(player.queue_refs, 1)
    n = n + 1
  end
  return n
end

function advance_level()
  jump_level(take_repeats("."))
end

function retreat_level()
  jump_level(-take_repeats(","))
end

-- TEMPORARY: Shift+Esc cannot reach a program while the
-- editor input field is active (compy-dl0 / compy-mkr, gated
-- on the editor API), so "<" exits a run to the menu in the
-- meantime. Remove "<" when Shift+Esc works in the editor.

function exit_to_menu()
  to_menu()
end

CMD_HANDLERS = {
  ["."] = advance_level,
  [","] = retreat_level,
  ["<"] = exit_to_menu,
  L = start_turn,
  R = start_turn,
  F = start_move,
  B = start_move
}

function on_win()
  GS.running = false
  cur_progression()
end

function execute_next()
  local cmd, ref = dequeue()
  local fn = CMD_HANDLERS[cmd]
  if fn then
    fn(cmd, ref)
  end
end

-- An editor run that failed (crashed or missed the goal)
-- pauses so the child can read the result and the hint,
-- then restarts on Tab. Keys mode resets immediately.

function enter_failed(kind)
  player.queue = { }
  player.queue_refs = { }
  GS.running = false
  GS.failed = kind
  ctrl_update = nil
end

function on_fail()
  if GS.won then
    player.queue = { }
    next_level()
  elseif cur_controls == editor then
    enter_failed("crash")
  else
    reset_level()
  end
end

ANIM_FINISHERS.fail = on_fail
ANIM_FINISHERS.win = on_win

function finish_anim()
  local a = player.anim
  player.anim = nil
  ANIM_FINISHERS[a.kind](a)
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

TRACK_UPDATE.push = TRACK_UPDATE.move

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

-- Editor input processing

-- The editor runs the whole program from the start each
-- time. A miss or crash shows a modal that waits for Tab
-- (see draw_failed); a syntax error keeps the editor open
-- and shows its message on this prompt so the child fixes
-- it in place.

function input_prompt()
  if GS.invalid then
    return GS.invalid.msg
  end
  return "Commands:"
end

function rearm_input()
  if player.anim or 0 < #player.queue then
    return
  end
  if GS.running then
    finish_run()
  else
    input_text(input_prompt(), string.lines(GS.program or ""))
  end
end

-- A run that ended without a win. A crash already played
-- the lose sound; a plain miss gets a soft "not yet" cue.
-- Either way the run freezes input (ctrl_update = nil) and
-- shows the failed modal until Tab; the robot holds in
-- place behind it.

function finish_run()
  GS.running = false
  if GS.won or GS.celebrating or GS.crash then
    return
  end
  -- A Sokoban goal is a permanent state, not a position:
  -- once every box sits on a target the level is won, even
  -- if later commands moved the robot on. Pushing a box back
  -- off a target lowers filled_count, so this is false again
  -- until they are all on target once more.
  if 0 < GS.box_goal_count
       and GS.filled_count == GS.box_goal_count then
    win_level(nil, sfx.wow)
    return
  end
  sfx.toggle()
  GS.failed = "miss"
  ctrl_update = nil
end

function process_user_input()
  if GS.input:is_empty() then
    rearm_input()
    return
  end
  start_program(string.unlines(GS.input()))
end

function start_program(text)
  GS.failed = nil
  local lines = string.lines(text)
  macros = clone_macros(GS.base_macros)
  local bad = validate_program(lines)
  if bad then
    sfx.wrong()
    GS.invalid = bad
    GS.program = text
    echo_lines = lines
    input_text(input_prompt(), lines)
    return
  end
  GS.invalid = nil
  GS.program = text
  GS.crash = nil
  reset_level()
  echo_lines = lines
  process_input(lines, 0)
  GS.running = true
end

-- Tab from a failed-run modal: send the robot home, drop
-- the failed run's macros back to the level base, and
-- reopen the editor with the kept program text.

function reset_after_fail()
  reset_level()
  GS.crash = nil
  GS.invalid = nil
  macros = clone_macros(GS.base_macros)
  rearm_editor()
end

function rearm_editor()
  ctrl_pressed = nil
  ctrl_update = process_user_input
  GS.input = user_input()
  input_text("Commands:", string.lines(GS.program or ""))
end

-- Main Loop

tab_was_down = false

function poll_tab_progression()
  local down = love.keyboard.isDown("tab")
  local edge = down and not tab_was_down
  if edge and (GS.celebrating or GS.won) then
    next_level()
  elseif edge and GS.failed then
    reset_after_fail()
  elseif edge then
    reset_level()
  end
  tab_was_down = down
end

-- Return to the start menu, dropping game input.

function to_menu()
  GS.mode = "menu"
  ctrl_update = nil
  ctrl_pressed = nil
end

function love.update(dt)
  ensure_init()
  if GS.mode ~= "game" then
    return
  end
  poll_tab_progression()
  if player.anim then
    advance_anim(dt)
  end
  if player.anim then
    update_track_offsets(dt)
  elseif not GS.celebrating then
    execute_next()
  end
  if ctrl_update then
    ctrl_update()
  end
end

function love.draw()
  if not GS.init then
    return
  end
  if GS.mode == "menu" then
    menu_draw()
  else
    draw_scene()
  end
end

SYSTEM_KEYS = { }

function SYSTEM_KEYS.menu()
  cur_grid = not cur_grid
  sfx.sword()
end

love.mousepressed = SYSTEM_KEYS.menu

function is_shift_down()
  local d = love.keyboard.isDown
  return d("lshift") or d("rshift")
end

-- Shift+Esc steps back one level within the game: a game
-- level returns to the track menu; the menu is the top
-- level, so it is a no-op there (UX standard -- leaving the
-- game to the console is Ctrl+Esc / the host). On editor
-- levels the text modal consumes keys, so this reaches us
-- only on direct-control levels and the menu.

function on_escape()
  if GS.mode == "game" then
    to_menu()
  end
end

function game_key(k)
  local fn = SYSTEM_KEYS[k]
  if fn then
    fn()
  elseif ctrl_pressed then
    ctrl_pressed(k)
  end
end

function love.keypressed(k)
  if k == "escape" then
    if is_shift_down() then
      on_escape()
    end
    return
  end
  if GS.mode == "menu" then
    menu_key(k)
  else
    game_key(k)
  end
end

function love.keyreleased(k)
  release_shift(k)
end

function love.resize()
  if GS.init and GS.mode == "game" then
    init_grid(GRID.rows, GRID.cols)
  end
end
