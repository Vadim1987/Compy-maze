-- macro.lua

-- Keyboard macro recording and playback

SHIFT_KEYS = {
  lshift = true,
  rshift = true
}

macro_state = {
  recording = false,
  shift_held = false,
  name = nil,
  body = { }
}

-- Start recording: Shift + key pressed

function start_recording(key)
  local name = key:upper()
  if PRIMITIVES[name] then
    sfx.wrong()
    return
  end
  macro_state.recording = true
  macro_state.name = name
  macro_state.body = { }
  sfx.beep()
end

-- Add a key to macro body

function record_key(key)
  if MAX_MACRO_LEN <= #(macro_state.body) then
    return
  end
  local upper = key:upper()
  if PRIMITIVES[upper] or macros[upper] then
    table.insert(macro_state.body, upper)
    sfx.toggle()
  end
end

-- Finish recording: expand and save

function finish_recording()
  if not macro_state.recording then
    return
  end
  macro_state.recording = false
  local text = table.concat(macro_state.body)
  local result = expand_macros(text)
  macros[macro_state.name] = 0 < #result and result or nil
end

-- Execute a key: expand macro if defined

function execute_key(key)
  local upper = key:upper()
  local cmds = macros[upper]
  if cmds then
    for i = 1, #cmds do
      ping_cmd(cmds:sub(i, i))
    end
  else
    ping_cmd(upper)
  end
end

-- Handle non-escape key presses

function handle_key(k)
  if SHIFT_KEYS[k] then
    macro_state.shift_held = true
    return
  elseif macro_state.recording then
    record_key(k)
  elseif macro_state.shift_held then
    start_recording(k)
  else
    execute_key(k)
  end
end

-- Handle shift release

function release_shift(k)
  if SHIFT_KEYS[k] then
    macro_state.shift_held = false
    finish_recording()
  end
end
