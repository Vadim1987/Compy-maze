#!/usr/bin/env bash
#
# verify.sh -- headless verification of the maze/draw build.
#
# Emits both projects to a scratch dir, compiles every .lua,
# runs the command-core spec, and checks each project is
# self-contained (every require resolves inside its own
# folder, except runtime modules). No LOVE, no device.
#
# On-device behaviour (rendering, sound, timing, Ctrl+Esc)
# cannot be checked here -- that is the manual pass in
# TEST-PLAN.md.
#
# Usage:  ./verify.sh
#
set -eu

SRC="$(cd "$(dirname "$0")" && pwd)"
LUA="$(command -v lua || command -v lua5.1)"
LUAC="$(command -v luac || command -v luac5.1)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fail=0

echo "== emit (.compy/build) =="
bash "$SRC/.compy/build" "$TMP"

echo "== compile (luac -p), skipping generated sprites =="
for d in maze draw; do
  for f in "$TMP/$d"/*.lua; do
    head -1 "$f" | grep -q Generated && continue
    "$LUAC" -p "$f" || fail=1
  done
done
echo "  done"

echo "== command-core spec (from repo) =="
( cd "$SRC" && "$LUA" spec/script_spec.lua ) || fail=1

echo "== self-contained (every require resolves in-folder) =="
for d in maze draw; do
  reqs=$(grep -hoE 'require\("[^"]+"\)' "$TMP/$d"/*.lua \
         | sed -E 's/require\("([^"]+)"\)/\1/' | sort -u)
  for r in $reqs; do
    # utf8 is runtime-provided by Compy/LOVE, like gfx/Color.
    [ "$r" = "utf8" ] && continue
    if [ ! -f "$TMP/$d/$r.lua" ]; then
      echo "  MISSING in $d: require(\"$r\")"
      fail=1
    fi
  done
done
echo "  done"

if [ "$fail" = 0 ]; then
  echo "== OK: build verified =="
else
  echo "== FAILED =="
  exit 1
fi
