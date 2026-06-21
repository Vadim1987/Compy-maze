-- main.lua

-- Maze game: guide a player to the destination!

require("core_constants")
require("maze_constants")
require("controls")
require("core_sprites")
require("maze_decorations")
require("core_render")
require("maze_render")
require("levels")
require("player")
require("core_anim")
require("maze_logic")
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

function ensure_init()
  if not GS.init then
    GS.init = true
  end
end

function execute_next()
  local cmd, ref = dequeue()
  local fn = CMD_HANDLERS[cmd]
  if fn then
    fn(cmd, ref)
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

function process_user_input()
  if GS.input:is_empty() then
    rearm_input()
    return
  end
  start_program(string.unlines(GS.input()))
end

function start_program(text)
  GS.failed = nil
  -- Any submit clears the previous run's crash marker; it
  -- otherwise persists through Tab so it stays visible
  -- while the child edits.
  GS.crash = nil
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
  reset_level()
  echo_lines = lines
  process_input(lines, 0)
  GS.running = true
end

-- Tab from a failed-run modal: send the robot home, drop
-- the failed run's macros back to the level base, and
-- reopen the editor with the kept program text. The crash
-- marker stays red until the next submit so the child can
-- glance at what went wrong while editing.

function reset_after_fail()
  reset_level()
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
