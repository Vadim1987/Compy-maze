-- menu.lua

-- Start screen: pick a maze track. Matches the calm look
-- of the mouse and keyboard games (cream field, dark
-- centered numbered list).

COL_BG = {
  0.93,
  0.93,
  0.9
}
COL_TEXT = {
  0.16,
  0.16,
  0.16
}
COL_DIM = {
  0.5,
  0.5,
  0.48
}

-- menu_draw restores the runtime font on exit so the
-- in-game HUD keeps inheriting it; the menu's UI font is
-- local to this function.

function menu_draw()
  local prev_font = gfx.getFont()
  local w, h = gfx.getDimensions()
  gfx.setColor(COL_BG)
  gfx.rectangle("fill", 0, 0, w, h)
  gfx.setFont(getFont(FONT_UI, math.floor(h / 16)))
  gfx.setColor(COL_DIM)
  gfx.printf("Choose a maze", 0, h * 0.18, w, "center")
  for i, t in ipairs(TRACKS) do
    local y = h * 0.34 + (i - 1) * h * 0.1
    gfx.setColor(COL_TEXT)
    gfx.printf(t.key .. ".  " .. t.name, 0, y, w, "center")
  end
  gfx.setFont(prev_font)
end

function menu_key(k)
  for _, t in ipairs(TRACKS) do
    if t.key == k then
      start_track(t)
      return
    end
  end
end

function start_track(t)
  levels = t.levels
  level_index = 1
  maze = levels[1]
  GS.base_macros = { }
  GS.mode = "game"
  start_level()
end
