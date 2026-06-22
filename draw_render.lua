-- draw_render.lua

-- Draw's canvas: a faint grid under the shared trail,
-- robot and echo. No walls, goals, boxes, legend or
-- modals -- draw has no win or fail state.

-- Faint grid lines along every cell boundary, always on.

function draw_canvas_grid()
  local left = GRID.offset_x
  local top = GRID.offset_y
  local right = left + GRID.cols * GRID.cell
  local bottom = top + GRID.rows * GRID.cell
  gfx.setColor(1, 1, 1, GRID_LINE.alpha)
  gfx.setLineWidth(GRID_LINE.width)
  for c = 0, GRID.cols do
    local x = left + c * GRID.cell
    gfx.line(x, top, x, bottom)
  end
  for r = 0, GRID.rows do
    local y = top + r * GRID.cell
    gfx.line(left, y, right, y)
  end
end

-- The whole frame, in z-order: grid, trail, robot, echo.

function draw_scene()
  draw_canvas_grid()
  draw_traces()
  draw_player(GRID.scale)
  draw_echo()
end
