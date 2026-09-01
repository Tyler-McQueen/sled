# Sled

We're going down this mountain on whatever we grabbed at the top. That's the game. Slope, friends, bottom.

Godot 4. Local 1–4 players. Grab a sled, a fridge, an inner tube, a mattress, a kayak, a folding table, a kiddie pool, or a door at the summit — then ride it down.

## How to run

1. Install [Godot 4.2+](https://godotengine.org/download) (4.2, 4.3, or 4.4).
2. Open Godot → **Import** → select this folder (`project.godot`).
3. Press **F5** (or Project → Run).

The main scene is `scenes/main.tscn`. No extra assets or downloads.

## Controls

| | P1 | P2 | P3 / P4 |
|---|---|---|---|
| Move | WASD | Arrow keys | Left stick (gamepad 3 / 4) |
| Grab / hop off | E | Enter | A / South button |
| Jump / hop the ride | Space | Right Shift | B / East button |
| Restart race | R | R | Start |

P1 also uses gamepad 1, P2 uses gamepad 2. Plug in extra pads for P3 and P4.

Walk around the summit, get close to something, **Grab** to attach, then steer it off the lip. You stay stuck to whatever you grabbed (no ragdoll) — fridge tumble included. Press Grab again to hop off, or Grab another ride in range to steal it. The fridge holds two; everything else is a steal. Jump while riding pops the object up a bit.

## First playable

- One mountain: trees you can hit, a barn jump, a split into **ice** vs **powder**, finish in a parking lot
- Eight rideables: sled steers, fridge plows (holds two), tube spins, mattress flops, kayak tracks and tips, folding table catches a leg, kiddie pool sloshes, door wants to go on edge
- Shared follow camera
- Finish volume over the lot; places show on screen
- Physics is supposed to be chaotic and a little stupid

Out of scope on purpose: online multiplayer, menus, real art.

## Restart

Press **R** to dump everyone back on the summit.
