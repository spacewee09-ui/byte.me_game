# BYTE.ME

A meat-grinder precision platformer made with **Godot 4.7**.
You are a very small, very squishy meat guy. Run fast, jump, wall-jump, die
instantly on spikes and saws, and try again. Five levels, one grinder at the end.

No art or sound files were downloaded: the drawings are code and the sound
effects were generated. That means the whole game is text, so it fits in Git
nicely and anyone on the team can change it.

---

## 1. Play it (5 minutes)

1. Download **Godot 4.7** (standard, not .NET): <https://godotengine.org/download>
2. Unzip it. It is a single program, there is nothing to install.
3. Open Godot, click **Import**, pick the `project.godot` file in this folder,
   click **Import & Edit**.
   (You can also just double-click `project.godot` once Godot is associated.)
4. Press **F5** (or the ▶ button, top right).

To quit the game window: close it like any window, or add `--quit` when running
from a terminal.

If Godot asks to upgrade the project or warns about a newer format, you are on
the wrong version - use 4.7.x.

## 2. Controls

| Action | Keys |
| --- | --- |
| Run | `A` / `D` or `←` / `→` |
| Jump | `Space`, `W`, `↑` or `J` |
| Jump higher | hold jump, let go early to jump lower |
| Wall jump | jump while touching a wall in the air |
| Restart level | `R` |
| Pause | `Esc` (then `R` restart, `Q` menu) |
| Menus | `←` `→` to pick a level, `Space` to confirm |

Progress (unlocked levels, best times, bandages) saves automatically to Godot's
user folder, so it survives closing the game. Delete that file to reset
everything:
`%APPDATA%\Godot\app_userdata\BYTE.ME\byte_me_save.cfg` on Windows,
`~/.local/share/godot/app_userdata/BYTE.ME/byte_me_save.cfg` on Linux/macOS.

## 3. What is in the box

- 5 levels: *First Cut*, *Saw Point*, *The Shaft*, *Saw Alley*, *Final Cut*
- Movement with coyote time, jump buffering, variable jump height, wall slide
  and wall jump - the stuff that makes a platformer feel tight
- Instant respawn with meat explosion, screen shake and squash/stretch
- Spinning saws (some slide on rails), spikes, one hidden bandage per level
- Timer, death counter, best times, level unlocking, saved progress
- Title screen, level select, pause screen, level clear screen, ending

## 4. Project map

```
project.godot          game settings: window size, main scene, input map, autoload
icon.svg               the meat guy icon
scenes/
  main.tscn            the only scene the game needs: World + HUD + background
  player.tscn          the meat guy: body, collision box, drawing node
scripts/
  game.gd              runs everything: menus, level order, save file
  level.gd             builds a level from ASCII art and runs it
  levels.gd            THE LEVELS. ASCII art lives here, one character per tile
  player.gd            movement. All the feel constants are at the top
  player_visual.gd     draws the meat guy (squash, eyes, legs)
  hud.gd               timer, menus, overlays (drawn, not scene files)
  background.gd        parallax meat-packing plant
  camera.gd            follow + screen shake
  spike.gd saw.gd bandage.gd goal.gd gib.gd   the objects in a level
assets/sfx/*.wav       generated sound effects
tests/smoke.gd         headless checks: level data + actually plays level 1
prototype leftovers    control.gd, node_2d.tscn and the red PNG are from the
                       very first test. Nothing uses them; delete whenever.
```

## 5. Make a level (the fun part)

Open `scripts/levels.gd`. A level is a list of equal-length strings, one
character per 32x32 tile:

```
#  solid block          ^  floor spikes          v  ceiling spikes
S  saw                  T  saw sliding left/right U  saw sliding up/down
o  bandage (optional)   G  exit grinder          P  player start
.  empty air
```

Copy an existing level entry, paste it, change `name` and `hint`, and draw.
Rules of thumb, given the jump arc (about 2.6 tiles up and 5 tiles across):

- never require a climb of more than **2 tiles** without a ledge in between
- keep gaps **4 tiles or narrower** unless you add a platform
- a row of spikes placed on the floor goes in the row **above** the floor
- every level needs exactly one `P` and one `G`, and all rows the same length
- to add the level to the game, add it to `LEVELS`; the menu picks it up
  automatically

Then check your work:

```bash
godot --headless --path . -s res://tests/smoke.gd
```

`godot` there means the Godot binary you downloaded (on Windows:
`Godot_v4.7-stable_win64.exe`). It prints `ok` lines and `ALL CHECKS PASSED`,
or tells you exactly which level is broken.

## 6. Tune the feel

All in `scripts/player.gd`, in one block at the top:

```gdscript
const RUN_SPEED := 300.0        # pixels per second
const JUMP_VELOCITY := -580.0   # more negative = higher jump
const GRAVITY := 2000.0         # higher = snappier
const WALL_JUMP_PUSH := 350.0   # how far a wall jump throws you
const COYOTE_TIME := 0.1        # jump grace after leaving a ledge
```

Change one number, press F5, feel it. This is how all platformers get tuned.
The tiles are 32 pixels, so the window is 40 x 22.5 tiles at 1280x720.

## 7. Git and GitHub for the first time

Git is a save history for a folder. GitHub is a website that stores a copy so
the team can share it. The whole workflow is five commands:

```bash
git clone https://github.com/spacewee09-ui/byte.me_game.git   # get the code
cd byte.me_game
git status                     # what did I change?
git add -A                     # stage everything I changed
git commit -m "Add level 6"    # save a snapshot with a message
git push                       # upload the snapshot to GitHub
```

That is it. Rules that keep you out of trouble:

- **Pull before you start working** and **push when you finish**:
  `git pull` then work then `git add -A && git commit -m "..." && git push`.
- Commit small and often. "Add saws to level 3" is a good message. "stuff" is not.
- Never commit `*.tmp`, videos, or the `.godot/` folder. The `.gitignore` already
  covers Godot's cache.
- If two people edit the same lines, Git will say there is a conflict. Do not
  panic: open the file, look for `<<<<<<<`, keep the lines you want, delete the
  markers, then `git add -A` and `git commit`. Text levels keep conflicts tiny;
  that is one reason the levels are text.
- Godot's editor shows changed files with a **Git** tab if you enable the Git
  plugin; VS Code also works fine for editing `.gd` files.

## 8. Build something to show the judges

You do not need a build to demo - run it from Godot. But a standalone build is
nicer:

1. In Godot: **Editor → Manage Export Templates → Download and Install**.
2. **Project → Export → Add… → Web**. Export to a folder, e.g. `build/web/`.
3. Serve that folder with any static server and open it in a browser. Godot web
   builds must be served over http, not opened as a file. Upload the folder to
   itch.io (as an HTML game) if the hackathon wants a link.
4. For a desktop build, do the same with **Windows Desktop** / **Linux**.

Add `build/` to `.gitignore` if you export inside the repo.

## 9. Five-minute demo script

1. Menu, one sentence: "It's Super Meat Boy, but you're a byte of meat."
2. Play level 1 fast, die once on purpose, point out the instant respawn.
3. Show the wall jump in level 3, grab a bandage.
4. Show the timer and "new best time" on the level clear screen.
5. Finish level 5, land on the ending screen, say what you would build next
   (more levels, a level editor, ghosts of your best run, leaderboard).

Practical: turn the volume down a little before you project, learn one level
well enough to finish it live, and have a second person ready to take over if a
level refuses to be beaten on stage.

## 10. Where to go next

Cheap, high-impact additions, roughly in order:

- more levels (you can add ten in an afternoon with the ASCII format)
- a dash, and a second character with different physics
- moving platforms, conveyor belts, one-way platforms
- a ghost replay of your best run (record positions, play them back)
- a level editor that saves the ASCII grid
- a shared leaderboard (needs a backend and an HTTP request)

Have fun, and ship it.
