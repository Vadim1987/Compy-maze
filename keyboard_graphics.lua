require("utf8")

gfx = love.graphics

-- Colors
BASE_COLOR = Color[Color.black]
MAIN_COLOR = Color[Color.white + Color.bright]
AUX_COLOR = Color[Color.cyan]

-- Normal key height in mm
STD_H = 12.5
-- Top row key height in mm
TOP_H = 11
-- Letter and number width in mm
STD_W = 15
-- Top row key width in mm
TOP_W = 12.5
-- Narrow key width in mm
SMALL_W = 11
-- Wide key width in mm
WIDE_W = 23
-- Medium key width in mm
MED_W = 19
-- Total width in mm
WIDTH = 201.5
-- Total width in pixels
WIDTH_PX = 960
SCALE = WIDTH_PX / WIDTH
-- Font sizes in mm
FONT1_H, FONT2_H, FONT3_H = 5, 4, 3
-- Total width in pixels
FONT1 = gfx.newFont(
  "assets/fonts/SarasaGothicJ-Bold.ttf",
  FONT1_H * SCALE
)
FONT2 = gfx.newFont(
  "assets/fonts/SarasaGothicJ-Bold.ttf",
  FONT2_H * SCALE
)
FONT3 = gfx.newFont(
  "assets/fonts/SarasaGothicJ-Bold.ttf",
  FONT3_H * SCALE
)
-- Layout
layout = { }
layout[1] = {
  "escape",
  "f1",
  "f2",
  "f3",
  "f4",
  "f5",
  "f6",
  "f7",
  "f8",
  "f9",
  "f10",
  "f11",
  "f12",
  "numlk",
  "delete"
}
layout[2] = {
  "`",
  "1",
  "2",
  "3",
  "4",
  "5",
  "6",
  "7",
  "8",
  "9",
  "0",
  "-",
  "backspace"
}
layout[3] = {
  "tab",
  "q",
  "w",
  "e",
  "r",
  "t",
  "y",
  "u",
  "i",
  "o",
  "p",
  "=",
  "\\"
}
layout[4] = {
  "capslock",
  "a",
  "s",
  "d",
  "f",
  "g",
  "h",
  "j",
  "k",
  "l",
  ";",
  "return"
}
layout[5] = {
  "lshift",
  "\\",
  "z",
  "x",
  "c",
  "v",
  "b",
  "n",
  "m",
  ",",
  ".",
  "/",
  "up",
  "rshift"
}
layout[6] = {
  "fn",
  "lctrl",
  "zzz",
  "lalt",
  "pause",
  "space",
  "menu",
  "[",
  "]",
  "'",
  "left",
  "down",
  "right"
}
-- Dimensions
height = { }
width = { }
for _, v in pairs(layout[1]) do
  height[v] = TOP_H * SCALE
  width[v] = TOP_W * SCALE
end
for i = 2, 5 do
  for _, v in pairs(layout[i]) do
    height[v] = STD_H * SCALE
    width[v] = STD_W * SCALE
  end
end
for _, v in pairs({
  "`",
  "=",
  "\\",
  ";",
  ",",
  ".",
  "/",
  "up",
  "rshift"
}) do
  width[v] = SMALL_W * SCALE
end
for _, v in pairs({
  "tab",
  "lshift"
}) do
  width[v] = MED_W * SCALE
end
for _, v in pairs({
  "capslock",
  "return"
}) do
  width[v] = WIDE_W * SCALE
end
for _, v in pairs(layout[6]) do
  height[v] = STD_H * SCALE
  width[v] = SMALL_W * SCALE
end
-- Width of spacebar
width.space = 59.5 * SCALE

-- key caps
keycap = {
  space = function()

  end
}

NUM_SYM = {
  "!",
  "@",
  "#",
  "$",
  "%",
  "^",
  "&",
  "*",
  "(",
  [0] = ")"
}
LOWER, UPPER = { }, { }
for num, sym in pairs(NUM_SYM) do
  local n = "" .. num
  LOWER[n] = n
  UPPER[n] = sym
end
function shift(lower, upper)
  LOWER[lower] = lower
  UPPER[lower] = upper
end
shift("`", "~")
shift("-", "_")
shift("=", "+")
shift("\\", "|")
shift(";", ":")
shift(",", "<")
shift(".", ">")
shift("/", "?")
shift("[", "{")
shift("]", "}")
shift("'", "\"")
function double(x, y, name)
  gfx.setFont(FONT2)
  gfx.print(UPPER[name], x + 2 * SCALE, y + SCALE)
  gfx.print(
    LOWER[name],
    x + 2 * SCALE,
    y + (2 + FONT2_H) * SCALE
  )
end
function double2(x, y, name)
  gfx.setFont(FONT3)
  gfx.print(UPPER[name], x + SCALE, y + 2 * SCALE)
  gfx.print(LOWER[name], x + SCALE, y + (3 + FONT3_H) * SCALE)
end
function letter(x, y, name)
  gfx.setFont(FONT1)
  gfx.print(string.upper(name), x + 2 * SCALE, y + SCALE)
end
for name, _ in pairs(LOWER) do
  keycap[name] = double
end
function single(x, y, name)
  gfx.setFont(FONT3)
  gfx.print(UPPER[name], x + SCALE, y + 3 * SCALE)
end
function key(name, label)
  UPPER[name] = label
  keycap[name] = single
end
key("escape", "Esc")
key("numlk", "Numlk")
key("delete", "Delete")
key("backspace", utf8.char(10229))
key("tab", "Tab " .. utf8.char(8633))
key("return", "Enter")
key("lshift", utf8.char(8679) .. "Shift")
key("rshift", "Shift")
key("lctrl", "Ctrl")
key("lalt", "Alt")
key("menu", utf8.char(9636, 8598))
key("fn", "Fn")
key("zzz", "Zzz")
key("up", utf8.char(8593))
key("left", utf8.char(8592))
key("down", utf8.char(8595))
key("right", utf8.char(8594))
for i = 1, 12 do
  key("f" .. i, "F" .. i)
end
function key2(name, label1, label2)
  UPPER[name] = label1
  LOWER[name] = label2
  keycap[name] = double2
end
key2("capslock", "Caps", "Lock")
key2("pause", "Pause", "Break")

function keycap.fn(x, y, name)
  gfx.setColor(AUX_COLOR)
  single(x, y, name)
end
keycap.zzz = keycap.fn

key_bg = { }
function draw_key(x, y, name)
  local bg = key_bg[name]
  if bg then
    gfx.setColor(bg)
  else
    gfx.setColor(BASE_COLOR)
  end
  gfx.rectangle("fill", x, y, width[name], height[name])
  gfx.setColor(MAIN_COLOR)
  if (keycap[name]) then
    keycap[name](x, y, name)
  else
    letter(x, y, name)
  end
end

gap = { }
for i, row in pairs(layout) do
  local sum = 0
  for _, key in pairs(row) do
    sum = sum + width[key]
  end
  gap[i] = (WIDTH_PX - sum) / (#row - 1)
end

function draw_row(x, y, i)
  local row, g = layout[i], gap[i]
  for j = 1, #row do
    local key = row[j]
    draw_key(x, y, key)
    x = x + g + width[key]
  end
end
function draw_keyboard(x, y)
  for i = 1, #layout do
    draw_row(x, y, i)
    y = y + height[layout[i][1]] + SCALE
  end
end
