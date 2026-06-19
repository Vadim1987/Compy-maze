-- spec/script_spec.lua

-- Headless characterization spec for the command core
-- (script.lua). Run from anywhere:  lua5.1 spec/script_spec.lua
--
-- The ACTIVE cases capture today's behavior and must stay
-- green through the core extraction and the whitespace
-- change (the "behavior-identical maze" guarantee).
--
-- The PENDING cases document target behavior that lands
-- later: whitespace-as-separator (step 2) and draw's `C`
-- token. They are recorded, not run, so the baseline is
-- green until the feature exists.

local here = arg[0]:match("^(.*)/[^/]*$") or "."
dofile(here .. "/support.lua")
dofile(here .. "/../core_constants.lua") -- core PRIMITIVES
dofile(here .. "/../maze_constants.lua") -- + maze . , <
dofile(here .. "/../script.lua") -- code under test

-- A single-char error marker, as invalid_mark builds it.

local function mark(line, col, msg)
  return {
    line = line,
    col_from = col,
    col_to = col,
    msg = msg
  }
end

-- A command primitive with its source-column span.

local function prim(cmd, from, to)
  return {
    cmd = cmd,
    col_from = from,
    col_to = to
  }
end

print("== ACTIVE: behavior that must be preserved ==")

-- After the constants split, core + maze extras must equal
-- the historical maze command sets, or the maze parser
-- would silently change which tokens it accepts.

T.it("maze constants: primitive set reconstituted", function()
  T.eq(PRIMITIVES, {
    N = true, E = true, S = true, W = true,
    F = true, B = true, L = true, R = true,
    ["."] = true, [","] = true, ["<"] = true
  })
  T.eq(SILENT_CMDS, {
    ["."] = true, [","] = true, ["<"] = true
  })
end)

-- validate_program -------------------------------------

T.it("validate: clean adjacent program passes", function()
  T.eq(validate_program({ "3E3N" }), nil)
end)

T.it("validate: 3L and 0E are valid", function()
  T.eq(validate_program({ "3L" }), nil)
  T.eq(validate_program({ "0E" }), nil)
end)

T.it("validate: stray letter -> Unknown at col", function()
  T.eq(validate_program({ "EQ" }),
    mark(1, 2, "Unknown command: Q"))
end)

T.it("validate: non-letter junk -> Invalid input", function()
  T.eq(validate_program({ "3Q" }), mark(1, 1, "Invalid input"))
end)

T.it("validate: column tracks across ; statements", function()
  T.eq(validate_program({ "E;Q" }),
    mark(1, 3, "Unknown command: Q"))
end)

T.it("validate: define then use passes", function()
  T.eq(validate_program({ "X=3R", "X" }), nil)
end)

T.it("validate: redefinition then use passes", function()
  T.eq(validate_program({ "X=3R", "X=2L", "X" }), nil)
end)

T.it("validate: macro built on earlier macro passes", function()
  T.eq(validate_program({ "X=3R", "Y=2X", "Y" }), nil)
end)

-- The adjacency rule (the trap to keep): a count must hug
-- its command. This stays invalid AFTER whitespace lands.

T.it("validate: '3 E' is invalid (count not hugged)", function()
  T.eq(validate_program({ "3 E" }), mark(1, 1, "Invalid input"))
end)

-- define_macro / eager non-recursive expansion ---------

T.it("define_macro: 3R expands to RRR", function()
  define_macro("X=3R")
  T.eq(macros.X, "RRR")
end)

T.it("define_macro: redefinition overwrites", function()
  define_macro("X=3R")
  define_macro("X=2L")
  T.eq(macros.X, "LL")
end)

T.it("define_macro: body sees earlier macro eagerly", function()
  define_macro("X=3R")
  define_macro("Y=2X")
  T.eq(macros.Y, "RRRRRR")
end)

-- split_statements -------------------------------------

T.it("split: ;-separated with start columns", function()
  T.eq(split_statements("A;B;C"), {
    { text = "A", col = 1 },
    { text = "B", col = 3 },
    { text = "C", col = 5 }
  })
end)

T.it("split: trailing ; yields empty final stmt", function()
  T.eq(split_statements("A;"), {
    { text = "A", col = 1 },
    { text = "", col = 3 }
  })
end)

-- expand_with_refs -------------------------------------

T.it("refs: loop tags each copy, digit-cmd span", function()
  T.eq(expand_with_refs("3E"),
    { prim("E", 1, 2), prim("E", 1, 2), prim("E", 1, 2) })
end)

T.it("refs: bare primitives span one column each", function()
  T.eq(expand_with_refs("EF"),
    { prim("E", 1, 1), prim("F", 2, 2) })
end)

T.it("refs: 0E expands to nothing", function()
  T.eq(expand_with_refs("0E"), { })
end)

T.it("refs: macro body tagged at the macro letter", function()
  macros.X = "RR"
  T.eq(expand_with_refs("X"),
    { prim("R", 1, 1), prim("R", 1, 1) })
end)

T.it("refs: loop-of-macro, digit-letter span", function()
  macros.X = "RR"
  T.eq(expand_with_refs("2X"), {
    prim("R", 1, 2), prim("R", 1, 2),
    prim("R", 1, 2), prim("R", 1, 2)
  })
end)

-- enqueue / process_input ------------------------------

T.it("enqueue: queue, refs, one ping per prim", function()
  local pings = 0
  local saved = sfx.ping
  sfx.ping = function() pings = pings + 1 end
  process_input({ "3E" }, 0)
  sfx.ping = saved
  T.eq(player.queue, { "E", "E", "E" })
  T.eq(player.queue_refs, {
    { line = 1, col_from = 1, col_to = 2 },
    { line = 1, col_from = 1, col_to = 2 },
    { line = 1, col_from = 1, col_to = 2 }
  })
  T.eq(pings, 3)
end)

print("\n== PENDING: target behavior (lands in later steps) ==")

-- Step 2: whitespace-as-separator. These are invalid today
-- (a space is a bad token) and must become valid / shift
-- the error past the space.
T.pending("whitespace: '3E 3N' validates")
T.pending("whitespace: 'X X' validates")
T.pending("whitespace: 'X=3E 2N' then 'X' validates")
T.pending("whitespace: 'E Q' -> Unknown command: Q at col 3")
T.pending("whitespace: echo/ref cols aligned past spaces")

-- Draw program: `C` is a primitive, silent (no ping).
T.pending("draw: 'C' validates under draw PRIMITIVES")
T.pending("draw: 'C' enqueues and emits no ping (SILENT_CMDS)")

T.run()
