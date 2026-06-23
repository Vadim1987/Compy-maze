-- draw_render.lua

-- Draw's canvas: a faint grid under the shared trail,
-- robot and echo. No walls, goals, boxes, legend or
-- modals -- draw has no win or fail state.

-- Faint grid lines along every cell boundary, always on.

function draw_canvas_grid()
  local left, top = GRID.offset_x, GRID.offset_y
  local right = left + GRID.cols * GRID.cell
  local bottom = top + GRID.rows * GRID.cell
  gfx.setColor(GRID_LINE.color)
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

-- A light, flat canvas fill behind everything.

function draw_canvas_bg()
  local w, h = gfx.getDimensions()
  gfx.setColor(CANVAS_BG)
  gfx.rectangle("fill", 0, 0, w, h)
end

-- The whole frame, in z-order: bg, grid, trail, robot,
-- echo, then the command legend on the right.

function draw_scene()
  draw_canvas_bg()
  draw_canvas_grid()
  draw_traces()
  draw_player(GRID.scale)
  draw_echo()
  draw_legend()
end
