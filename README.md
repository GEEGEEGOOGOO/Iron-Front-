# IRON FRONT — Operation Ashfall

An original Godot 4 run-and-gun project based on the supplied Metal Slug 3D implementation plan. This is an early playable implementation, with procedural placeholder models and synthesized sound effects. The full plan remains in progress.

## Repository layout

| Folder | Contents |
|---|---|
| `assets/` | Runtime models, textures, UI images, and audio used by Godot |
| `art-source/weapons/` | Blender projects, references, review renders, and retained backups, grouped by weapon |
| `autoloads/` | Shared game services |
| `data/` | Weapon, enemy, and mission resources |
| `scenes/` | Playable scenes, menus, and debug scenes |
| `scripts/` | Gameplay and UI code |
| `shaders/` | Rendering shaders |
| `tests/` | Automated regression scenes and scripts |
| `tools/` | Export, rendering, and test utilities |
| `docs/` | Implementation notes, concepts, and manual testing guides |

See [repository organization](docs/repository-organization.md) for asset placement
rules and [Blender weapons](docs/blender-weapons.md) for the source-to-game workflow.

## Open and play

The pistol, shotgun, and flamethrower now use the Blender-authored models. For
quick access to all three, open `scenes/debug/blender_armory.tscn` and press F6;
select a weapon with the on-screen buttons, fire with J, and reload with R.
In normal missions, use 1 for the Blender pistol, 2 for shotgun, and 3 for
flamethrower, or click the weapon buttons below the HUD. All three are available
at mission start; changing slots preserves spent ammunition.
See [Blender weapons](docs/blender-weapons.md) for export and integration details.

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
| Reload magazine | R | Left-stick click |
| Rechargeable dash | Shift | Right-stick click |
| Grenade / tank cannon | K | B |
| Knife / free POW | L | Right shoulder |
| Interact / enter or exit tank | E | Y |
| Pause | Escape | Start |

Use F3 for debug info, F4 for god mode, F5 for a random weapon, F6 to spawn a grunt, and F7 to complete the mission. Debug shortcuts only operate in debug builds. Godot editor F5 may intercept the in-game shortcut when running embedded.

Keyboard controls can be changed in **Options → Controls**. Changes are saved automatically; controller bindings remain available.

At ladders, use aim up/down to climb; release to hold, and jump or move sideways to dismount onto the supply platform.

## Current implementation

- Side-view 3D lane movement, variable jump, coyote time, buffering, jointed crouch/jump/landing poses, eight-way firing, and a rechargeable dash.
- Six weapon resources with distinct held models and muzzle positions, sidearm/special weapon switching, grenades, melee, health, mercy frames, lives and checkpoints.
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
godot --headless --path . tests/campaign_flow.tscn
```

The smoke test covers ground contact, the Z lock, trigger/spawn/clear encounters, rocket lifetime, tank entry/destruction/ejection, lives, respawn and default weapon restoration across all missions. The campaign flow check clears all nine authored waves and three bosses. The combat regression checks directional damage, cover, laser piercing and accuracy, and standing clearance. These checks do not prove visual quality, controller hardware behavior or campaign balance.

See `docs/progress.md` for unfinished requirements and planned work. Scene geometry and placeholder models are constructed in GDScript at runtime; open the running game to see them.

For a focused manual pass through all missions, use `docs/manual-playtest.md`.

## Magazines and dash

Weapons now use magazines: reload with R / left-stick click, or keep firing an empty magazine to reload automatically. Reloading does not create ammo; finite special-weapon ammo still comes from pickups. The sidearm has unlimited reserve ammo. Weapon switching cancels a reload and preserves magazine contents.

Shift / right-stick click triggers an original short dash with a three-second recharge. It obeys world and actor collisions and gives no damage immunity. The HUD shows health/armor, life icons, magazine rounds, reserve/reload progress, grenade icons, and dash charge visually. Score, mission and rescue totals remain readable text.
