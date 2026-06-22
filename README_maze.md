# Maze

A game for learning to program by guiding a turtle
through a maze!

## Goal

Push every yellow box onto a cyan square to win!
If there is a red circle, you can also win by
reaching it.

## Choosing a Maze

When the game starts, a menu asks you to choose a
maze. Press a number to begin:

  1 — Drive the robot
  2 — Plan a path
  3 — All mazes

You can return to this menu while playing to switch
to a different set of mazes.

## Controls

Each level uses one of two control modes.

### Key Mode

Press keys to tell the turtle where to go. Each key
adds a command and you hear a short ping.

You can give directions on a compass:

  N — North
  S — South
  E — East
  W — West

Or tell the turtle to move and turn relative to where
it is facing:

  F — move forward
  B — move backward
  L — turn left
  R — turn right

Commands run one after another. You can press several
keys in a row and the turtle will follow them in order.

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
valid command.

The same compass and relative commands are available.
Both uppercase and lowercase letters work. Any other
characters are ignored.

You can type several commands at once, for example
SSEEF, and they will run in order when you press
Enter.

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

This turns right three times.

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
lines run in order when you press Enter. If any line
has a mistake, nothing runs and you hear a warning
sound so you can fix it.

## What Happens

The turtle turns and moves with a short animation.

When moving forward, it leaves a bright trail behind.
Moving backward leaves no trail.

If the turtle hits a wall, you hear a sound and the
maze resets so you can try again.

When you reach the red circle with no commands left
to run, you hear a victory sound and the circle
disappears. If more commands are queued, the turtle
passes through without triggering the win.

## Absolute Direction Reversal

When you send the turtle to the direction directly
opposite to where it currently faces (for example N
when facing S), it performs a 180-degree turn and
then moves one step forward. The turn goes in the
same direction as the last turn the turtle made; if
no turn has been made yet, the turn is clockwise.

## Pushing Boxes

Some levels have yellow boxes. You can push a box by
walking into it. The box moves one square in the
direction you are pushing.

A box can only be pushed if the square behind it is
empty. If it cannot move, the turtle bumps against it
like a wall.

## Box Goals

Some levels have cyan squares on the floor. Push
every yellow box onto a cyan square to win! You hear
a victory sound when all boxes are in place.

## Macro Letters

Above the legend, every defined non-empty shortcut
is shown by its letter. The list grows as you define
shortcuts and shrinks when you erase them. It spans
up to 3 lines of up to 8 letters, sorted
alphabetically. The list persists across levels.

## Level Progression

The game has multiple levels. Each level can have
one of three progression modes:

### Portal

The default mode. Upon winning, the game immediately
advances to the next level. Leftover commands carry
over and execute in the new level. Defined shortcuts
also carry over.

### Celebrate

Upon winning, a congratulations message appears on
screen with the Tab key shown as a keycap. Press Tab
to proceed to the next level. A win is counted only
if the command queue is empty at the moment the
turtle reaches the goal — otherwise the remaining
commands continue to execute without winning.

### Continue

Upon winning, the player stays on the same level
and can continue entering commands. The same
congratulations message appears and remains visible
while further commands run. Press Tab at any time
after winning to advance to the next level.
Crashing into a wall after winning also advances to
the next level and discards remaining commands. The
"." command works as usual.

## Skip Level

The command "." immediately advances to the next
level without any animation or sound. It can be
repeated to skip multiple levels:

    3.

skips three levels. It can also be used in shortcuts
and combined with other commands:

    FF.FF

moves forward twice, skips to the next level, then
moves forward twice in the new level.

## Grid

Some levels display a grid of small white crosses
in the center of each passable square. The grid can
be toggled on or off by pressing the Menu key.

## The Screen

The maze is shown in the center. Walls can show a
decorative background picture, or a plain blue fill
if the level does not set one. Open paths are white.
The bottom right corner shows all available commands,
with defined macro letters listed just above the
legend. On editor levels, the upper-left area shows
the echo of entered commands.

Press Ctrl+Esc to exit. Shift+Esc returns to the maze
menu.
