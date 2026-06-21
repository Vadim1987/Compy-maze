-- core_editor.lua

-- The command-line editor flow shared by every program:
-- prompt, submit, validate, run, and re-arm. The app
-- supplies before_run() (what to do once a program
-- validates) and finish_run() (what a finished run means).

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

-- before_run() is supplied by the app and called by
-- start_program once a program validates: the maze resets
-- the level, draw does nothing (the trail persists, the
-- robot continues). The core names it but never defines
-- it.

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

function process_user_input()
  if GS.input:is_empty() then
    rearm_input()
    return
  end
  start_program(string.unlines(GS.input()))
end

-- The reject path: a failed validation keeps the typed
-- text on screen, marks it invalid, and re-prompts.

function reject_program(text, bad, lines)
  sfx.wrong()
  GS.invalid = bad
  GS.program = text
  echo_lines = lines
  input_text(input_prompt(), lines)
end

-- Any submit clears the previous run's crash marker; it
-- otherwise persists through Tab so it stays visible while
-- the child edits.

function start_program(text)
  GS.failed = nil
  GS.crash = nil
  local lines = string.lines(text)
  macros = clone_macros(GS.base_macros)
  local bad = validate_program(lines)
  if bad then
    reject_program(text, bad, lines)
    return
  end
  GS.invalid = nil
  GS.program = text
  before_run()
  echo_lines = lines
  process_input(lines, 0)
  GS.running = true
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

function rearm_editor()
  ctrl_pressed = nil
  ctrl_update = process_user_input
  GS.input = user_input()
  input_text("Commands:", string.lines(GS.program or ""))
end
