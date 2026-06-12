-- player.lua

-- Compass directions

-- How each direction moves on the grid

DIR_DELTA = { }

DIR_DELTA.N = {
  x = 0,
  y = -1
}
DIR_DELTA.S = {
  x = 0,
  y = 1
}
DIR_DELTA.W = {
  x = -1,
  y = 0
}
DIR_DELTA.E = {
  x = 1,
  y = 0
}

-- N <-> S, E <-> W

OPPOSITE_DIR = {
  N = "S",
  S = "N",
  E = "W",
  W = "E"
}

-- N -> E -> S -> W (clockwise)

TURN_RIGHT = {
  N = "E",
  E = "S",
  S = "W",
  W = "N"
}

-- N -> W -> S -> E (counter-clockwise)

TURN_LEFT = {
  N = "W",
  W = "S",
  S = "E",
  E = "N"
}

-- Turn an absolute command into relative ones.

function compile_absolute(target, facing)
  if target == facing then
    return "F"
  elseif target == OPPOSITE_DIR[facing] then
    return "B"
  elseif target == TURN_RIGHT[facing] then
    return "R"
  else
    return "L"
  end
end

-- Player state

player = {
  col = 1,
  row = 1,
  dir = "N",
  queue = { },
  queue_refs = { },
  anim = nil,
  traces = { },
  track_offset_l = 0,
  track_offset_r = 0,
  last_turn = nil
}

function player_reset(col, row, dir)
  player.col = col
  player.row = row
  player.dir = dir
  player.queue = { }
  player.queue_refs = { }
  player.anim = nil
  player.traces = { }
  player.track_offset_l = 0
  player.track_offset_r = 0
  player.last_turn = nil
end

-- Command queue

function process_cmd(k)
  local cmd = string.upper(k)
  if string.find("NSEWFBLR.,<", cmd) then
    table.insert(player.queue, cmd)
    table.insert(player.queue_refs, NO_REF)
    return true
  end
  return false
end

function ping_cmd(ch)
  if process_cmd(ch) and not SILENT_CMDS[ch] then
    sfx.ping()
  end
end

-- Dequeue the next relative command

function queue_unshift(cmd, ref)
  table.insert(player.queue, 1, cmd)
  table.insert(player.queue_refs, 1, ref)
end

function dequeue_absolute(cmd, ref)
  local rel = compile_absolute(cmd, player.dir)
  if rel == "F" then
    return rel
  end
  queue_unshift("F", ref)
  if rel == "B" then
    rel = player.last_turn or "R"
    queue_unshift(rel, ref)
  end
  return rel
end

function dequeue()
  local cmd = table.remove(player.queue, 1)
  local ref = table.remove(player.queue_refs, 1)
  if DIR_DELTA[cmd] then
    cmd = dequeue_absolute(cmd, ref)
  end
  return cmd, ref
end

-- Animation state

function start_anim(kind, duration, ref)
  player.anim = {
    kind = kind,
    time = 0,
    duration = duration,
    from_col = player.col,
    from_row = player.row,
    from_dir = player.dir,
    line = ref and ref.line,
    col_from = ref and ref.col_from,
    col_to = ref and ref.col_to
  }
end

function anim_progress()
  return player.anim.time / player.anim.duration
end
