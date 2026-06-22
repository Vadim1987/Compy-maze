# Build & verify

This one source tree produces two Compy projects, `maze` and
`draw`. A Compy project is a flat, self-contained folder
launched by `run("name")`; there is no runtime sharing
between projects, so the shared command core is physically
copied into each folder by the build step.

## Build

The host build calls this repo's emit script (the
`.compy/build` convention):

    cd <repo> && .compy/build <out-dir>

with an absolute, fresh `<out-dir>`. It populates
`<out-dir>/maze/` and `<out-dir>/draw/`, each a valid Compy
project (a direct `main.lua`) named exactly as its manifest
entry; it works relative to its own location, is
deterministic, and needs no network. `.compy/build`
classifies every source file as:

- **CORE** -> copied into *both* folders: `core_*`, `player`,
  `script`, and the four `ROBOT_03_*` sprite parts.
- **MAZE** -> `maze/` only: `maze_*`, `controls`, `levels`,
  `menu`, `macro`, `keyboard_graphics`, the box / target /
  background sprites, `legend.txt`, and `maze_main.lua`,
  emitted as the project's `main.lua`.
- **DRAW** -> `draw/` only: `draw_constants`, `draw_render`,
  and `draw_main.lua`, emitted as the project's `main.lua`.

The source root has no `main.lua`, so it is not itself a
runnable project: both `maze/` and `draw/` are produced only
by the build step. Each program's child-facing readme
(`README_maze.md` / `README_draw.md`) is emitted as that
folder's `README.md`.

`assets/fonts/` is copied into both folders when an `assets/`
tree is present; the Sarasa Gothic font is runtime-provided
here, so none is committed. The emit is idempotent: re-running
it reproduces identical folders.

## Verify (headless)

    ./verify.sh

Emits both projects to a scratch dir and checks, with no LOVE
and no device:

1. every `.lua` compiles (`luac -p`), generated sprites aside;
2. the command-core spec passes (`lua spec/script_spec.lua`,
   expect `29 passed, 0 failed, 0 pending`);
3. each project is self-contained -- every `require` resolves
   inside its own folder, except the runtime modules
   (`utf8`, `gfx`, `Color`, `compy.audio`).

`spec/` stays at the repo root and runs on the host; it is
not shipped into the emitted projects. Run it directly from
the repo root with `lua spec/script_spec.lua`.

## Verify (on device)

Rendering, sound, ~0.45 s/step timing, the editor, and
`Ctrl+Esc` exit can only be checked on Compy. Deploy the
emitted `maze/` and `draw/` folders, then walk **TEST-PLAN.md**
-- section A is the maze regression, section B is the draw
acceptance against the behaviour spec.
