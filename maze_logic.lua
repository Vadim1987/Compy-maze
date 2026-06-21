-- maze_logic.lua

-- Maze game logic: parsing, walls, goal, Sokoban,
-- crash/bump/fail, level progression.

-- Parsing: read the maze strings to find the player

CELL_PARSERS = { }

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

-- The boundary seam: a move is blocked by a wall or the
-- grid edge. Draw overrides this with an off-canvas test;
-- its move handler skips silently instead of bumping.

blocked = is_wall

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
  if box_goal_met() and #player.queue == 0 then
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

function start_bump(cmd, ref)
  local t = ANIM.move_time * ANIM.bump_frac
  start_anim("bump", t, ref)
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
  if blocked(tc, tr) then
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

function step_level(cmd)
  local sign = (cmd == ",") and -1 or 1
  jump_level(sign * take_repeats(cmd))
end

-- TEMPORARY: Shift+Esc cannot reach a program while the
-- editor input field is active (compy-dl0 / compy-mkr, gated
-- on the editor API), so "<" exits a run to the menu in the
-- meantime. Remove "<" when Shift+Esc works in the editor.

function exit_to_menu()
  to_menu()
end

CMD_HANDLERS = {
  ["."] = step_level,
  [","] = step_level,
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

TRACK_UPDATE.push = TRACK_UPDATE.move

-- A Sokoban goal is a permanent state, not a position:
-- once every box sits on a target the level is won, even
-- if later commands moved the robot on. Pushing a box back
-- off a target lowers filled_count, so this is false again
-- until they are all on target once more.

function box_goal_met()
  return 0 < GS.box_goal_count
       and GS.filled_count == GS.box_goal_count
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
  if box_goal_met() then
    win_level(nil, sfx.wow)
    return
  end
  sfx.toggle()
  GS.failed = "miss"
  ctrl_update = nil
end

-- The maze wires the post-step hook to its goal check.

after_step = check_goal
