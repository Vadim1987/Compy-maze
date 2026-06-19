-- maze_render.lua

-- Maze-only rendering: walls, cells, grid, goals,
-- boxes, legend, macro list, win/fail modals, scene.

-- The in-game HUD inherits the Compy runtime font: a
-- monospace Nerd font carrying icon + CJK fallbacks,
-- sized to the screen. The legend's compass and rotation
-- glyphs live in those fallbacks, so the HUD must NOT
-- install its own font. Only the start menu picks a
-- proportional UI font, cached by size below.

FONT_UI = "assets/fonts/SarasaGothicJ-Bold.ttf"

FONT_CACHE = { }

function getFont(path, px)
  local key = px .. ":" .. path
  local f = FONT_CACHE[key]
  if not f then
    f = gfx.newFont(path, px)
    FONT_CACHE[key] = f
  end
  return f
end

function draw_walls()
  if cur_background then
    cur_background()
    return
  end
  local w, h = gfx.getDimensions()
  gfx.setColor(Color[Color.blue + Color.bright])
  gfx.rectangle("fill", 0, 0, w, h)
end

function draw_cells()
  gfx.setColor(Color[Color.white])
  for r, row in ipairs(GS.grid) do
    for c = 1, #row do
      if row:sub(c, c) ~= "#" then
        local x, y = cell_top_left(c, r)
        gfx.rectangle("fill", x, y, GRID.cell, GRID.cell)
      end
    end
  end
end

-- Grid crosses in center of passable squares

function draw_cross(cx, cy, s)
  gfx.line(cx - s, cy, cx + s, cy)
  gfx.line(cx, cy - s, cx, cy + s)
end

function draw_grid()
  if not cur_grid then
    return 
  end
  gfx.setColor(Color[Color.white + Color.bright])
  gfx.setLineWidth(1)
  for r, row in ipairs(GS.grid) do
    for c = 1, #row do
      if row:sub(c, c) ~= "#" then
        local cx, cy = cell_center(c, r)
        draw_cross(cx, cy, GRID.cell / 4)
      end
    end
  end
end

-- Destination targets

function draw_goals()
  for _, g in pairs(GS.goal_map) do
    local x, y = cell_center(g.col, g.row)
    local fill = TARGET.cell_fill * g.radius
    local w, h = TARGET.sprite_w, TARGET.sprite_h
    local s = sprite_scale(w, h, fill)
    gfx.push("all")
    gfx.translate(x, y)
    gfx.scale(s, s)
    gfx.translate(-w / 2, -h / 2)
    target_sprite()
    gfx.pop()
  end
end

-- Position near the wall edge.

function bump_pos(p)
  local a = player.anim
  local dir = player.dir
  if a.move_cmd == "B" then
    dir = OPPOSITE_DIR[dir]
  end
  local d = DIR_DELTA[dir]
  local cx, cy = cell_center(player.col, player.row)
  return cx + d.x * GRID.bump_dist * p, cy + d.y * GRID.
      bump_dist * p
end

function ANIM_DRAW_POS.bump()
  return bump_pos(anim_progress())
end

function ANIM_DRAW_POS.fail()
  return bump_pos(1)
end

function push_offset(p)
  local peak = GRID.push_path - GRID.bump_dist
  local dist = GRID.push_path * p
  if dist < peak then
    return dist
  end
  return peak - (dist - peak)
end

function push_player_pos()
  local a = player.anim
  local dir = push_dir(a.move_cmd)
  local d = DIR_DELTA[dir]
  local cx, cy = cell_center(a.from_col, a.from_row)
  local f = push_offset(anim_progress())
  return cx + (d.x * f), cy + (d.y * f)
end

function push_box_offset(p)
  local dist = GRID.push_path * p - GRID.bump_dist
  if dist < 0 then
    return 0
  end
  if GRID.cell < dist then
    return GRID.cell
  end
  return dist
end

ANIM_DRAW_POS.push = push_player_pos

-- Show controls legend in the bottom right corner

function draw_legend()
  if not cur_legend then
    return
  end
  local w, h = gfx.getDimensions()
  local font = gfx.getFont()
  local fh = font:getHeight()
  local fw = font:getWidth(cur_legend)
  local _, n = cur_legend:gsub("\n", "")
  local th = fh * (n + 1)
  gfx.setColor(Color[Color.black])
  gfx.print(cur_legend, (w - fw) - fh, (h - th) - fh)
end

-- Letters of currently defined non-empty macros,
-- shown above the legend in up to 3 lines of 8.

function macro_letters()
  local letters = { }
  for k, v in pairs(macros) do
    if 0 < #v then
      table.insert(letters, k)
    end
  end
  table.sort(letters)
  return letters
end

function macro_lines(letters)
  local n = MACRO_LINE_LEN
  local lines = { }
  for i = 1, #letters, n do
    local j = math.min(i + n - 1, #letters)
    table.insert(lines, table.concat(letters, "", i, j))
  end
  return lines
end

function legend_lines()
  if not cur_legend then
    return 0
  end
  local _, n = cur_legend:gsub("\n", "")
  return n + 1
end

function draw_macros_list()
  local letters = macro_letters()
  local lines = macro_lines(letters)
  local font = gfx.getFont()
  local fh = font:getHeight()
  local w, h = gfx.getDimensions()
  local x = (w - fh) - font:getWidth(
    string.rep("X", MACRO_LINE_LEN)
  )
  local y = h - fh * (1 + legend_lines() + #lines)
  gfx.setColor(Color[Color.black])
  for _, line in ipairs(lines) do
    gfx.print(line, x, y)
    y = y + fh
  end
end

-- Dim overlay for macro recording

function draw_dim()
  local w, h = gfx.getDimensions()
  gfx.setColor(0, 0, 0, 0.5)
  gfx.rectangle("fill", 0, 0, w, h)
end

function draw_macro_name(x, y)
  local name = macro_state.name:lower()
  key_bg[name] = Color[Color.blue]
  draw_key(x, y, name)
end

function draw_macro_body(x, y)
  key_bg = { }
  local w = gfx.getDimensions()
  local start_x = x
  for _, k in ipairs(macro_state.body) do
    local lk = k:lower()
    if w < x + width[lk] then
      x = start_x
      y = y + height[lk] + SCALE
    end
    draw_key(x, y, lk)
    x = x + width[lk] + SCALE
  end
end

function draw_macro_ui()
  if macro_state.shift_held then
    draw_dim()
  end
  if not macro_state.recording then
    return 
  end
  local _, h = gfx.getDimensions()
  local name = macro_state.name:lower()
  local m = STD_H * SCALE
  local y = (h - height[name]) / 2
  draw_macro_name(m, y)
  draw_macro_body(m, y + height[name] + SCALE)
end

-- Box drawing

function box_draw_pos(b)
  local a = player.anim
  if not a or a.kind ~= "push"
       or a.box ~= b
  then
    return cell_top_left(b.col, b.row)
  end
  local dir = push_dir(a.move_cmd)
  local d = DIR_DELTA[dir]
  local x, y = cell_top_left(b.col, b.row)
  local f = push_box_offset(anim_progress())
  return x + (d.x * f), y + (d.y * f)
end

function draw_box_goals()
  gfx.setColor(Color[Color.cyan])
  for _, g in pairs(GS.box_goal_map) do
    local x, y = cell_top_left(g.col, g.row)
    gfx.rectangle("fill", x, y, GRID.cell, GRID.cell)
  end
end

function draw_boxes()
  for _, b in pairs(GS.box_map) do
    local x, y = box_draw_pos(b)
    local w, h = BOX.sprite_w, BOX.sprite_h
    local s = sprite_scale(w, h, BOX.cell_fill)
    gfx.push("all")
    gfx.translate(x, y)
    gfx.scale(s, s)
    box_sprite()
    gfx.pop()
  end
end

-- Win modal.

function draw_celebrate()
  if not (GS.celebrating or GS.won) then
    return
  end
  gfx.setColor(Color[Color.white + Color.bright])
  draw_keycap_banner(CELEBRATE_PREFIX, CELEBRATE_SUFFIX)
end

-- Failed-run modal (miss / crash): a calm "not yet",
-- never punitive. Hidden during a win so they never stack.

function draw_failed()
  if not GS.failed or GS.celebrating or GS.won then
    return
  end
  local prefix = FAILED_MISS_PREFIX
  if GS.failed == "crash" then
    prefix = FAILED_CRASH_PREFIX
  end
  gfx.setColor(Color[Color.white + Color.bright])
  draw_keycap_banner(prefix, FAILED_SUFFIX)
end

-- Level indicator: muted "Maze N" in a top corner.
-- Top-right keeps clear of the upper-left echo and the
-- bottom-right legend.

function draw_level_indicator()
  local font = gfx.getFont()
  local label = "Maze " .. level_index
  local m = font:getHeight() / 2
  local x = gfx.getWidth() - font:getWidth(label) - m
  gfx.setColor(1, 1, 1, 0.5)
  gfx.print(label, x, m)
end

-- Draw everything on screen

function draw_scene()
  draw_walls()
  draw_cells()
  draw_grid()
  draw_box_goals()
  draw_goals()
  draw_traces()
  draw_boxes()
  draw_player(GRID.scale)
  draw_echo()
  draw_legend()
  draw_level_indicator()
  draw_macros_list()
  draw_macro_ui()
  draw_celebrate()
  draw_failed()
end
