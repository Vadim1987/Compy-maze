# Maze

A game for learning to program by guiding a robot
through a maze!

## Goal

Reach the diamond to win! Some levels have yellow
boxes instead — push every box onto a cyan square.
A few have both.

## Choosing a Maze

When the game starts, a menu asks you to choose a
maze. Press a number to begin:

  1 — Drive the robot
  2 — Plan a path
  3 — All mazes

You can return to this menu while playing by
pressing Shift+Esc.

## Controls

Each level uses one of two control modes.

### Key Mode

Press keys to tell the robot where to go. Each key
adds a command and you hear a short ping.

You can give directions on a compass:

  N — North
  S — South
  E — East
  W — West

Or tell the robot to move and turn relative to where
it is facing:

  F — move forward
  B — move backward
  L — turn left
  R — turn right

Commands run one after another. You can press several
keys in a row and the robot will follow them in order.

#### Recording Shortcuts

You can save a sequence of keys as a shortcut:

 1. Hold Shift and press a key — this names your
    shortcut. You hear a beep and see the key on
    screen with a blue background.
 2. While still holding Shift, press up to 7 keys —
    each one makes a click sound and appears on
    screen.
 3. Release Shift to save your shortcut.

Now just press your shortcut key to replay the whole
sequence!

To erase a shortcut, hold Shift, press the key, and
release Shift right away without adding any keys.

You cannot use N, E, S, W, F, B, L or R as shortcut
names — those are already commands.

While Shift is held, the screen dims to show you are
in recording mode.

### Editor Mode

Type commands in the text field at the bottom and
press Enter to run them. You hear a ping for each
command that runs.

The same compass and relative commands are available.
Both uppercase and lowercase letters work.

You can type several commands at once, for example
SSEEF. Spaces and semicolons just separate commands,
so SSEEF, SS EE F, and SS;EE;F all do the same thing.

Entered command lines are echoed on the screen one
under another with reduced opacity, so the game
remains visible beneath. Up to 16 most recent lines
are shown; older lines scroll off the top. The
command currently being executed is highlighted
within its source line. For loops like 3R, both the
count and the operation are highlighted; for macros,
the macro letter is highlighted, not the expanded
body.

#### Repeating Commands

Put a number before a command to repeat it:

    3R

This turns right three times. It works with any
command — turns (3L, 3R) and moves (4N, 3F) too.

#### Defining Shortcuts

Give a name to a sequence of commands by typing a
letter, an equal sign, and the commands:

    X=3R

Now typing X anywhere runs three right turns.

Shortcuts can build on each other:

    X=3R
    X=2X
    X

This runs six right turns.

You cannot use N, E, S, W, F, B, L or R as shortcut
names — those are already commands.

#### Multiple Lines

Press Shift+Enter to type several lines at once. All
lines run in order when you press Enter.

#### If Something Is Wrong

Before the robot moves, the whole program is checked.
If a command is not understood, nothing runs: the bad
letter turns red and a message appears — "Unknown
command: X" for a stray letter, or "Invalid input"
otherwise — and you hear a soft sound. Fix it and
run again.

## What Happens

The robot turns and moves with a short animation.

When moving forward, it leaves a bright cyan trail
behind. Moving backward leaves no trail.

If the robot hits a wall, you hear a soft sound and
it stops. In Key Mode the maze resets so you can try
again. In Editor Mode a message appears — "Crashed.
Press Tab to try again." — and your program stays on
screen with the step that went wrong marked red, so
you can fix it and run it again.

If a program finishes without reaching the goal, you
see "Goal not reached. Press Tab to try again."

When you reach the diamond with no commands left to
run, you hear a victory sound and the diamond
disappears. If more commands are queued, the robot
passes through without triggering the win.

## Absolute Direction Reversal

When you send the robot to the direction directly
opposite to where it currently faces (for example N
when facing S), it performs a 180-degree turn and
then moves one step forward. The turn goes in the
same direction as the last turn the robot made; if
no turn has been made yet, the turn is clockwise.

## Pushing Boxes

Some levels have yellow boxes. You can push a box by
walking into it. The box moves one square in the
direction you are pushing.

A box can only be pushed if the square behind it is
empty. If it cannot move, the robot bumps against it
like a wall.

## Box Goals

Some levels have cyan squares on the floor. Push
every yellow box onto a cyan square to win! You hear
a victory sound when all boxes are in place. They
stay won even if the robot moves on afterward —
unless you push a box back off a square.

## Macro Letters

Above the legend, every defined non-empty shortcut
is shown by its letter. The list grows as you define
shortcuts and shrinks when you erase them. It spans
up to 3 lines of up to 8 letters, sorted
alphabetically. The list persists across levels.

## Moving Between Levels

When you win, what happens next depends on the level:

- Most levels wait: "Congratulations! Press Tab to
  proceed." appears with the Tab key shown as a
  keycap. Press Tab for the next level.
- Some levels go straight to the next one.

You can also move between levels yourself:

  .  — go to the next level
  ,  — go back one level

Put a number in front to jump several: 3. jumps three
levels forward and 2, jumps two back (it stops at the
first and last level). The program ends at the jump —
any commands after it are not run.

## Leaving

  Shift+Esc — return to the maze menu
  Ctrl+Esc  — exit to the console
  <         — leave a running program back to the menu

While you are typing in the editor, Shift+Esc cannot
get through, so type < and press Enter to leave a
running program. Bare Escape does nothing in Key
Mode; in the editor it clears whatever you have
typed, so watch out for an accidental right-click.

## Grid

Some levels display a grid of small white crosses in
the center of each passable square. Press the Menu
key to toggle the grid on or off.

## The Screen

The maze is shown in the center. Walls can show a
decorative background picture, or a plain blue fill
if the level does not set one. Open paths are white,
with the diamond, any yellow boxes, and cyan squares
sitting on them. The bottom-right corner shows all
available commands, with your shortcut letters just
above it. The level number ("Maze N") is in the
top-right corner. On editor levels, the entered
commands are echoed in the upper-left area.
