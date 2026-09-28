# IRON FRONT — Operation Ashfall

An original Godot 4 run-and-gun project based on the supplied Metal Slug 3D implementation plan. This is an early playable implementation, with procedural placeholder models and synthesized sound effects. The full plan remains in progress.

## Open and play

1. Import `project.godot` in Godot 4.4 or newer (validated with 4.7.2).
2. Press **F5** and select a mission.
3. Move right, defeat each locked encounter, rescue POWs, and defeat the boss.

For a direct mission test, open `scenes/levels/mission_1.tscn`, `mission_2.tscn`, or `mission_3.tscn` and press **F6**. Each starts with the full HUD and game systems. The corresponding `world_mission_*.tscn` exposes its LevelData resource in the Inspector; geometry is built at runtime.

The project uses Forward+ and Jolt, 60 Hz physics, and a 1280 × 720 canvas. No external assets or addons are needed. All three missions are open for testing. Save data goes to Godot's `user://save.json`.

## Controls

| Action | Keyboard | Controller |
|---|---|---|
| Move / aim | A/D or arrows; W/up to aim up | Left stick |
| Crouch / airborne aim down | S/down | Stick down |
| Jump (variable height) | Space | A |
| Fire | J | X |
| Switch sidearm / special weapon | Q | Left shoulder |
| Grenade / tank cannon | K | B |
| Knife / free POW | L | Right shoulder |
| Interact / enter or exit tank | E | Y |
| Pause | Escape | Start |

Use F3 for debug info, F4 for god mode, F5 for a random weapon, F6 to spawn a grunt, and F7 to complete the mission. Debug shortcuts only operate in debug builds. Godot editor F5 may intercept the in-game shortcut when running embedded.

Keyboard controls can be changed in **Options → Controls**. Changes are saved automatically; controller bindings remain available.

At ladders, use aim up/down to climb; release to hold, and jump or move sideways to dismount onto the supply platform.

## Current implementation

- Side-view 3D lane movement, variable jump, coyote time, buffering, crouch, eight-way firing.
- Six weapon resources, sidearm/special weapon switching, grenades, melee, health, mercy frames, lives and checkpoints.
- Seven enemy data variants including a three-phase boss prototype.
- Encounter gates, destructible crates/barrels, weapon/health/grenade pickups, POW rescue.
- Drivable tank with machine gun, cannon, armor and protected ejection.
- Three mission resource sets with distinct platform layouts, themed background props, wave compositions and boss attack sequences.
- Main menu, pause, options, HUD, boss bar, mission result and JSON high scores.
- Mission start title cards with each mission's name and objective.
- Preallocated projectile, effect and enemy pools; positional pooled SFX, three original mission music loops and a boss cue.

## Automated checks

Run the complete suite with isolated temporary save files and per-test logs:

```sh
python3 tools/run_tests.py --godot /path/to/Godot
```

The runner enforces timeouts, checks process exit codes and success markers, and rejects logged script/runtime errors. Results are written to `test-results/summary.json`. This is headless functional verification, not a rendering or hardware-performance benchmark.

Individual checks with a Godot executable on your PATH:

```sh
godot --headless --path . --editor --quit
godot --headless --path . tests/smoke.tscn
godot --headless --path . tests/combat_regression.tscn
godot --headless --path . tests/boss_regression.tscn
godot --headless --path . tests/audio_regression.tscn
godot --headless --path . tests/input_regression.tscn
godot --headless --path . tests/reward_regression.tscn
godot --headless --path . tests/fragment_regression.tscn
godot --headless --path . tests/ram_regression.tscn
godot --headless --path . tests/traversal_regression.tscn
godot --headless --path . tests/elevator_regression.tscn
```

The smoke test covers ground contact, the Z lock, trigger/spawn/clear encounters, rocket lifetime, tank entry/destruction/ejection, lives, respawn and default weapon restoration across all missions. The combat regression checks directional damage, cover, laser piercing and accuracy, and standing clearance. These checks do not prove visual quality, controller hardware behavior or campaign balance.

See `docs/progress.md` for unfinished requirements and planned work. Scene geometry and placeholder models are constructed in GDScript at runtime; open the running game to see them.
