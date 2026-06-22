-- core_render.lua

-- Rendering shared by every command-driven
-- program: robot sprite, trail, echo field, banner.

gfx = love.graphics

-- Cyan trace left by the player when moving forward.

function draw_active_trace()
  local a = player.anim
  if a and a.move_cmd == "F"
       and (a.kind == "move" or a.kind == "push")
  then
    local x1, y1 = cell_center(a.from_col, a.from_row)
    local x2, y2 = current_pos()
    gfx.circle("fill", x1, y1, GRID.trace_r)
    gfx.line(x1, y1, x2, y2)
  end
end

function draw_traces()
  gfx.setColor(Color[Color.cyan])
  gfx.setLineWidth(GRID.trace_r * 2)
  for _, t in ipairs(player.traces) do
    local x1, y1 = cell_center(t.c1, t.r1)
    local x2, y2 = cell_center(t.c2, t.r2)
    gfx.line(x1, y1, x2, y2)
    gfx.circle("fill", x1, y1, GRID.trace_r)
    gfx.circle("fill", x2, y2, GRID.trace_r)
  end
  draw_active_trace()
end

-- Angle for each compass direction

DIR_ANGLES = {
  N = 0,
  E = math.pi / 2,
  S = math.pi,
  W = -math.pi / 2
}

-- Draw three copies of a track for wrap coverage.

function draw_track_bars(sprite, off)
  local step = TRACK.bar_step
  local half = step / 2
  local dy = (off + half) % step - half
  gfx.translate(0, dy - step)
  sprite()
  gfx.translate(0, step)
  sprite()
  gfx.translate(0, step)
  sprite()
  gfx.translate(0, -step - dy)
end

-- Draw the player sprite at screen position (x, y).

function draw_player_at(x, y, angle, scale)
  gfx.push("all")
  gfx.translate(x, y)
  gfx.rotate(angle)
  gfx.scale(scale, scale)
  gfx.translate(-PLAYER.sprite_w / 2, -PLAYER.sprite_h / 2)
  robot_back()
  gfx.stencil(robot_back, "replace", 1)
  gfx.setStencilTest("greater", 0)
  draw_track_bars(robot_track_l, player.track_offset_l)
  draw_track_bars(robot_track_r, player.track_offset_r)
  gfx.setStencilTest()
  robot_front()
  gfx.pop()
end

-- Compute scale to fit sprite into cell with fill ratio

function sprite_scale(sw, sh, fill)
  local long_side = math.max(sw, sh)
  return GRID.cell * fill / long_side
end

-- Player position during movement animation

function anim_move_pos()
  local a = player.anim
  local p = anim_progress()
  local x1, y1 = cell_center(a.from_col, a.from_row)
  local x2, y2 = cell_center(a.target_col, a.target_row)
  return x1 + (x2 - x1) * p, y1 + (y2 - y1) * p
end

-- Smoothly rotate between two directions

function lerp_angle(from_dir, to_dir, t)
  local from = DIR_ANGLES[from_dir]
  local to = DIR_ANGLES[to_dir]
  local diff = to - from
  if math.pi < diff then
    diff = diff - 2 * math.pi
  elseif diff < -math.pi then
    diff = diff + 2 * math.pi
  end
  return from + diff * t
end

-- Player position for the current frame

ANIM_DRAW_POS = { }

ANIM_DRAW_POS.move = anim_move_pos

function current_pos()
  local a = player.anim
  local fn = a and ANIM_DRAW_POS[a.kind]
  if fn then
    return fn()
  end
  return cell_center(player.col, player.row)
end

-- Player angle for the current frame

function current_angle()
  local a = player.anim
  if a and a.kind == "turn" then
    local p = anim_progress()
    return lerp_angle(a.from_dir, a.target_dir, p)
  end
  return DIR_ANGLES[player.dir]
end

-- Command echo: show entered lines on editor levels,
-- highlight the symbol currently being executed, keep a
-- crashed token red until the next run, and flag an
-- invalid token red until the program is re-submitted.

function echo_marked(mark, line_idx, col)
  if not mark or mark.line ~= line_idx then
    return false
  end
  return mark.col_from <= col and col <= mark.col_to
end

function set_echo_color(line_idx, col, lit)
  if echo_marked(GS.crash, line_idx, col)
       or echo_marked(GS.invalid, line_idx, col)
  then
    gfx.setColor(Color[Color.red + Color.bright])
    return
  end
  local alpha = lit and 1 or ECHO_DIM_ALPHA
  gfx.setColor(1, 1, 1, alpha)
end

function draw_echo_line(line, line_idx, y)
  local font = gfx.getFont()
  local a = player.anim
  local on = a and a.line == line_idx
  local x = 0
  for col = 1, #line do
    local ch = line:sub(col, col)
    local lit = on and a.col_from <= col and col <= a.col_to
    set_echo_color(line_idx, col, lit)
    gfx.print(ch, x, y)
    x = x + font:getWidth(ch)
  end
end

function draw_echo()
  if cur_controls ~= editor then
    return
  end
  local fh = gfx.getFont():getHeight()
  local start = math.max(1, (#echo_lines - MAX_ECHO_LINES) + 1)
  for i = start, #echo_lines do
    draw_echo_line(echo_lines[i], i, (i - start) * fh)
  end
end

function draw_player(scale)
  local x, y = current_pos()
  draw_player_at(x, y, current_angle(), scale)
end
