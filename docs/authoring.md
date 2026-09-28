# Mission authoring

## Run a mission

Open `scenes/levels/mission_1.tscn` (or 2/3) and press F6. These entry scenes initialize the full game. F5 starts the menu.

## Place encounters

Open `scenes/levels/world_mission_1.tscn` (or 2/3):

- `Encounters/EncounterN`: its X position determines when the wave starts.
- `wave`: selects the WaveData resource containing enemy types and spawn delay.
- `CameraFocus`: its global X frames the locked arena.
- `SpawnPoints/SpawnN`: global X/Y sets the spawn position; Z is always forced to the gameplay lane.

Encounters run in scene-tree order. Keep their trigger positions increasing along X. Spawn markers cycle if a wave contains more enemies than markers. Place markers above solid ground, within the visible arena. The fallback for a spawner without markers lays enemies out to the right of its trigger.

Runtime copies the wave resource before applying scene placement, so editor assets are not modified by gameplay. The level root's `data` resource configures colors, platforms, ladders, elevators, music, rewards and boss content. Geometry is generated at runtime; the editor currently shows placement markers rather than the generated environment.

## Adjust content

- Weapons: `data/weapons/*.tres`
- Enemy health/speed/cooldowns: `data/enemies/*.tres`
- Boss patterns and phase gates: `data/attacks/*.tres`, `data/bosses/*.tres`
- POW reward weights: `data/rewards/pow.tres`
- Platform/ladder/elevator placement: `data/levels/mission_*.tres`

Run `python3 tools/run_tests.py --godot /path/to/Godot` after gameplay changes. This does not replace editor playtesting or balance review.

WaveData `trigger_condition` supports position, level start, elapsed mission timer, and previous-wave-cleared. `trigger_delay` is an absolute mission-time threshold for timer waves and a delay after the previous clear for chained waves. These still run in authored scene order; place their arena/spawn markers where the player will be when they activate.

LevelData also exposes `pow_positions`, `crate_positions`, and `barrel_positions`. Keep prisoner cages reachable from the gameplay lane; the final crate grants rockets, and earlier crates grant machine-gun supplies. Barrels explode without dropping a weapon.
