# Command-core spec

Headless tests for the shared command core (`script.lua`):
the parser, validator, loop/macro expansion, statement
splitting, and enqueue. They run under plain `lua` 5.1.5 —
no LÖVE, no device — so a failing case shows up in the
terminal in under a second.

## Run

From the repository root (also works from inside `spec/`):

    lua spec/script_spec.lua

Output ends with a summary line:

    29 passed, 0 failed, 0 pending

Exit code is `0` when nothing failed, non-zero otherwise,
so the same command works in a CI check. A failure prints
the case name and the expected vs. actual value, e.g.:

    FAIL  validate: stray letter -> Unknown at col  --  ...
          expected {... msg="Unknwn command: Q"}
          actual   {... msg="Unknown command: Q"}

## Active vs. pending

Active cases capture today's behavior and must stay green
through the core extraction and the whitespace change —
this is the "maze plays identically" guarantee.

Pending cases name target behavior that lands in later
steps (whitespace-as-separator; draw's `C` command). They
are recorded, not run, so the baseline stays green until
the feature exists. When a feature lands, its
`T.pending(...)` line becomes a real `T.it(...)` case.

## Files

- `support.lua` — runtime stubs the core reads at call
  time (`PRIMITIVES`, `SILENT_CMDS`, `macros`, `player`,
  `sfx`, `readfile`) plus a tiny assert/runner framework
  (`T.it`, `T.eq`, `T.pending`, `T.run`).
- `script_spec.lua` — the cases. It loads the real
  `script.lua` and `constants.lua`, never a copy.

## Scope

Dev-side only. The build step copies the core and per-app
files into the emitted `maze/` and `draw/` folders; it
never copies `spec/`, so these tests do not ship to the
device.

## Adding a case

    T.it("what it checks", function()
      T.eq(actual_value, expected_value)
    end)

Write `expected_value` as a literal, not derived from the
code under test — a computed expectation can hide a shared
bug.
