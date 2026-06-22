-- draw_main.lua

-- Draw: a command-driven drawing canvas on the shared
-- command core. The robot moves on an open 8 x 8 grid,
-- leaving a cumulative trail; C clears it. No walls, no
-- goal, no win, no fail.

require("core_constants")
require("draw_constants")
require("core_sprites")
require("core_render")
require("draw_render")
require("core_editor")
require("player")
require("core_anim")
require("script")

sfx = compy.audio

echo_lines = { }

cur_controls = editor

GS = {
  init = false,
  running = false,
  base_macros = { }
}

-- App hooks. The core names these; each program defines
-- its own. Draw has no goal and no level, so after_step
-- and before_run do nothing -- the trail and the robot
-- persist across runs.

function blocked(tc, tr)
  return tc < 1 or GRID.cols < tc or tr < 1 or GRID.rows < tr
end

function before_run()
end

function after_step()
end

function finish_run()
  GS.running = false
end

-- A move off the canvas is skipped silently: no trail, no
-- sound, and the remaining commands still run.

function draw_move(cmd, ref)
  local tc, tr = move_cmd_target(cmd)
  if blocked(tc, tr) then
    return
  end
  start_forward(cmd, ref, tc, tr)
end

-- C clears the trail and returns the robot to start; the
-- queue is untouched, so the program continues after it.

function clear_canvas()
  reset_robot(START.col, START.row, START.dir)
end

CMD_HANDLERS = {
  F = draw_move,
  B = draw_move,
  L = start_turn,
  R = start_turn,
  C = clear_canvas
}

-- Height of the runtime's command-editor band: EDITOR_ROWS
-- text rows at the current font.

function editor_band_h()
  return EDITOR_ROWS * gfx.getFont():getHeight()
end

-- One fixed canvas, the robot seeded at start, the editor
-- armed. Done once, lazily, when the window is sized.

function ensure_init()
  if GS.init then
    return
  end
  init_grid(CANVAS.rows, CANVAS.cols, editor_band_h())
  player_reset(START.col, START.row, START.dir)
  editor()
  GS.init = true
end

function love.update(dt)
  ensure_init()
  if player.anim then
    advance_anim(dt)
  end
  if player.anim then
    update_track_offsets(dt)
  else
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
  draw_scene()
end

function love.resize()
  if GS.init then
    init_grid(CANVAS.rows, CANVAS.cols, editor_band_h())
  end
end
