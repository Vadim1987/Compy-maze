-- spec/support.lua

-- Headless test support for the Compy command core.
-- Stubs the runtime globals that script.lua reads at call
-- time, plus a tiny assert/runner framework. No LOVE: runs
-- under plain lua5.1 (5.1.5) on the dev host.

-- Runtime-provided globals the core touches.
macros = { }
player = {
  queue = { },
  queue_refs = { }
}
sfx = {
  ping = function() end
}

-- constants.lua pulls the legend through the runtime's
-- readfile; stub it so the file loads headless.
function readfile()
  return ""
end

-- Fresh state before every case.

function reset_state()
  macros = { }
  player.queue = { }
  player.queue_refs = { }
end

-- Value formatting for failure messages.

local function show(v)
  if type(v) ~= "table" then
    if type(v) == "string" then
      return string.format("%q", v)
    end
    return tostring(v)
  end
  local keys = { }
  for k in pairs(v) do
    keys[#keys + 1] = k
  end
  table.sort(keys, function(a, b)
    return tostring(a) < tostring(b)
  end)
  local parts = { }
  for _, k in ipairs(keys) do
    parts[#parts + 1] = tostring(k) .. "=" .. show(v[k])
  end
  return "{" .. table.concat(parts, ", ") .. "}"
end

local function deep_eq(a, b)
  if type(a) ~= type(b) then
    return false
  end
  if type(a) ~= "table" then
    return a == b
  end
  for k, v in pairs(a) do
    if not deep_eq(v, b[k]) then
      return false
    end
  end
  for k in pairs(b) do
    if a[k] == nil then
      return false
    end
  end
  return true
end

-- Framework. Cases run immediately as declared.

local pass, fail, pend = 0, 0, 0
local fails = { }

T = { }

function T.it(name, fn)
  reset_state()
  local ok, err = pcall(fn)
  if ok then
    pass = pass + 1
  else
    fail = fail + 1
    fails[#fails + 1] = name .. "  --  " .. tostring(err)
  end
end

-- Target behavior not yet implemented: recorded, not run,
-- so the baseline stays green while documenting intent.

function T.pending(name)
  pend = pend + 1
  print("  ~ pending: " .. name)
end

function T.eq(actual, expected, msg)
  if not deep_eq(actual, expected) then
    -- level 2 points the error at the failing case
    error((msg or "eq")
      .. "\n      expected " .. show(expected)
      .. "\n      actual   " .. show(actual), 2)
  end
end

function T.run()
  print(string.format(
    "\n%d passed, %d failed, %d pending", pass, fail, pend
  ))
  for _, f in ipairs(fails) do
    print("  FAIL  " .. f)
  end
  os.exit(fail == 0 and 0 or 1)
end
