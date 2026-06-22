# Draw

A program for learning to code by guiding a turtle
around a canvas to draw!

## Goal

There is no goal to reach and no way to lose. The
canvas is yours: send the turtle across the grid and
watch the trail it leaves behind.

## Editor Mode

Type commands in the text field at the bottom and
press Enter to run them. You hear a ping for each
command that moves the turtle.

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

Both uppercase and lowercase letters work. You can
type several commands at once, for example EEFN, and
they run in order when you press Enter. Spaces,
semicolons and new lines just separate commands.

Entered command lines are echoed on the screen one
under another with reduced opacity. The command
currently being executed is highlighted within its
source line.

### Repeating Commands

Put a number before a command to repeat it:

    3E

This moves east three times.

### Defining Shortcuts

Give a name to a sequence of commands by typing a
letter, an equal sign, and the commands:

    X=3E

Now typing X anywhere runs three steps east.
Shortcuts can build on each other. You cannot use
N, E, S, W, F, B, L or R as shortcut names — those
are already commands.

### Multiple Lines

Press Shift+Enter to type several lines at once. All
lines run in order when you press Enter. If any line
has a mistake, nothing runs and you hear a warning
sound so you can fix it.

## What Happens

The turtle turns and moves with a short animation.

When moving forward, it leaves a bright trail behind.
Moving backward leaves no trail. The trail builds up
across runs, and the turtle keeps going from wherever
it stopped — so you can draw a little at a time.

If a move would take the turtle off the edge of the
canvas, that step is skipped and the rest of your
commands keep running.

## Absolute Direction Reversal

When you send the turtle to the direction directly
opposite to where it faces (for example N when facing
S), it makes a 180-degree turn and then moves one
step forward. The turn goes the same way as the last
turn the turtle made; if none has been made yet, the
turn is clockwise.

## Clearing the Canvas

Type C to wipe the trail and send the turtle back to
its starting corner, facing north. C runs silently,
and the program keeps going: any commands after it
continue on the fresh canvas.

## Leaving

Press Ctrl+Esc to exit.
