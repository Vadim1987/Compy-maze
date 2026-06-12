-- script.lua

-- Expand counted loops: 3R -> RRR

function expand_loops(text)
  return text:gsub("(%d+)([%a%.])", function(n, ch)
    return ch:rep(n)
  end)
end

-- Replace macro letters with their contents

function expand_macros(text)
  local result = ""
  for i = 1, #text do
    local ch = text:sub(i, i)
    result = result .. (macros[ch] or ch)
  end
  return result
end

-- Expand loops and macros

function expand(text)
  local expanded = expand_loops(text:upper())
  return expand_macros(expanded)
end

-- Define a macro: X=3RF
--
-- Macros are expanded EAGERLY here, against the macros
-- table as it stands, so a body can reference only macros
-- defined earlier -- never itself. Recursion is therefore
-- impossible by construction; this is deliberate for all
-- maze brackets (the game is not Turing-complete). Do not
-- turn this into late or recursive expansion.

function define_macro(line)
  local name = line:sub(1, 1):upper()
  macros[name] = expand(line:sub(3))
end

-- Split a line into ;-separated statements, each with its
-- 1-based start column within the line.

function split_statements(line)
  local out = { }
  local from = 1
  while true do
    local semi = line:find(";", from, true)
    local to = semi and (semi - 1) or #line
    table.insert(out, {
      text = line:sub(from, to),
      col = from
    })
    if not semi then
      return out
    end
    from = semi + 1
  end
end

-- A runnable command char: a primitive (includes the
-- level-jump "." and ",") or a macro known at this point.

function is_cmd_char(ch, known)
  return PRIMITIVES[ch] or known[ch] == true
end

-- A digit count must be followed by a command char.
-- Returns the index after the loop, or nil if malformed.

function check_loop(seg, i, known)
  local num = seg:sub(i):match("^%d+")
  local nc = i + #num
  local nch = seg:sub(nc, nc)
  if nch == "" or nch:match("%d")
       or not is_cmd_char(nch, known) then
    return nil
  end
  return nc + 1
end

-- First invalid token in a command string: returns its
-- 1-based column and char, or nil when the string is
-- clean.

function bad_token(seg, known)
  local i = 1
  while i <= #seg do
    local ch = seg:sub(i, i)
    if ch:match("%d") then
      local nxt = check_loop(seg, i, known)
      if not nxt then return i, ch end
      i = nxt
    elseif is_cmd_char(ch, known) then
      i = i + 1
    else
      return i, ch
    end
  end
end

-- Marker the editor shows for a rejected token.

function invalid_msg(ch)
  if ch:match("%a") then
    return "Unknown command: " .. ch
  end
  return "Invalid input"
end

function invalid_mark(line, col, msg)
  return {
    line = line,
    col_from = col,
    col_to = col,
    msg = msg
  }
end

-- Validate one statement; return a marker or nil.

function validate_def(li, seg, sc, known)
  local name = seg:sub(1, 1)
  if PRIMITIVES[name] then
    return invalid_mark(li, sc, "Cannot redefine: " .. name)
  end
  local i, ch = bad_token(seg:sub(3), known)
  if i then
    return invalid_mark(li, sc + i + 1, invalid_msg(ch))
  end
  known[name] = true
end

function validate_stmt(li, st, known)
  local seg, sc = st.text, st.col
  if seg == "" then
    return nil
  elseif seg:match("^%a=") then
    return validate_def(li, seg, sc, known)
  end
  local i, ch = bad_token(seg, known)
  if i then
    return invalid_mark(li, sc + i - 1, invalid_msg(ch))
  end
end

-- Validate a whole submission against the macros known so
-- far (base + earlier definitions). Returns nil, or the
-- first error's marker. The robot must not move when this
-- returns non-nil.

function validate_program(lines)
  local known = { }
  for k in pairs(macros) do
    known[k] = true
  end
  for li, line in ipairs(lines) do
    for _, st in ipairs(split_statements(line:upper())) do
      local bad = validate_stmt(li, st, known)
      if bad then
        return bad
      end
    end
  end
end

-- Expand a line into primitives with back pointers.
-- Returns { {cmd = ch, col_from = F, col_to = T}, ... }
-- where F..T span the source columns of the symbol --
-- macro letter, loop digit-letter pair, or primitive.

function expand_with_refs(line)
  local prims = { }
  local i = 1
  while i <= #line do
    local ch = line:sub(i, i)
    if ch:match("%d") then
      i = expand_loop_at(line, i, prims)
    else
      append_one(prims, ch, i, i)
      i = i + 1
    end
  end
  return prims
end

function expand_loop_at(line, i, prims)
  local num_str = line:sub(i):match("^(%d+)")
  local n = tonumber(num_str)
  local col = i + #num_str
  local ch = line:sub(col, col)
  for _ = 1, n do
    append_one(prims, ch, i, col)
  end
  return col + 1
end

function append_one(prims, ch, col_from, col_to)
  if macros[ch] then
    append_macro(prims, macros[ch], col_from, col_to)
  else
    table.insert(prims, {
      cmd = ch,
      col_from = col_from,
      col_to = col_to
    })
  end
end

function append_macro(prims, body, col_from, col_to)
  for j = 1, #body do
    table.insert(prims, {
      cmd = body:sub(j, j),
      col_from = col_from,
      col_to = col_to
    })
  end
end

-- Enqueue a command segment. base_col is the segment's
-- 1-based start column in its source line, so highlight
-- refs point at the right place.

function enqueue_commands(line_idx, seg, base_col)
  local prims = expand_with_refs(seg)
  for _, p in ipairs(prims) do
    table.insert(player.queue, p.cmd)
    table.insert(player.queue_refs, {
      line = line_idx,
      col_from = base_col + p.col_from - 1,
      col_to = base_col + p.col_to - 1
    })
    if not SILENT_CMDS[p.cmd] then
      sfx.ping()
    end
  end
end

-- Run one statement: a definition or a command segment.

function process_statement(line_idx, st)
  if st.text == "" then
    return
  elseif st.text:match("^%a=") then
    define_macro(st.text)
  else
    enqueue_commands(line_idx, st.text, st.col)
  end
end

-- Process a pre-validated submission: each line's
-- ;-separated statements run left-to-right.

function process_input(lines, start_offset)
  for i, line in ipairs(lines) do
    for _, st in ipairs(split_statements(line:upper())) do
      process_statement(start_offset + i, st)
    end
  end
end
