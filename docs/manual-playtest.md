# Manual Godot playtest

Open `project.godot` in Godot 4.4 or newer and press F5. Choose a mission from the menu. For a direct launch, open `scenes/levels/mission_1.tscn`, `mission_2.tscn`, or `mission_3.tscn` and press F6. The world scenes alone show editor markers; the full scenery is built when a mission runs.

## First pass: feel and readability

1. Move, jump with a short and long press, crouch, and aim in all eight directions. Try a keyboard and a controller if available.
2. Fire the sidearm, collect a special weapon, and press Q or controller left shoulder to swap. Confirm its ammo is preserved while stowed and that it returns to the sidearm when empty.
3. Break a POW cage, rescue the prisoner at close range, and check the reward and POW counter. Break a crate and an explosive barrel.
4. Enter the Iron Mule tank with E or controller Y. Drive, fire both weapons, ram an enemy, exit, and let the tank be destroyed to check ejection. Shoot the remaining wreck until it breaks, then walk through its former position.
5. Pause, restart from a checkpoint, and verify that the active encounter replays without losing an already rescued POW.

## Mission route checks

| Mission | Things to check |
|---|---|
| Operation Ashfall | Coastal water and dock markings; three encounter gates; ladder supplies; Iron Colossus boss. |
| Dust Battalion | Desert dunes; rushers from behind in the first fight and grenadiers in the second; Dune Mortar boss. |
| Midnight Foundry | Glowing channel and hazard stripes; elevator supplies; rear turret and two tanks in the last wave; Furnace Sentinel boss. |

Each boss should introduce itself, show a health bar, announce phases two and three, pause briefly at each transition, and end with a commander rescue and results screen. Mission three should end at “Campaign Complete.”

## Settings and persistence

- Change a volume slider and a keyboard binding under Options. Restart the game and check that both choices remain.
- Check that the best score for a completed mission appears on the mission menu after restarting.
- Test the pause menu and results screen with keyboard and controller navigation.

## Feedback that helps fix an issue

For each issue, record the mission, approximate X position from the F3 debug overlay if useful, what you did, what happened, and what you expected. A screenshot or a copied Godot error is useful for visual or crash issues. Report any unreadable attack, unreachable enemy, confusing pickup, camera problem, sudden frame drop, or sound that is too loud or quiet.

For slowdowns, enable F3 and record FPS, physics milliseconds, and draw calls during the affected encounter. These are Godot monitor readings; GPU timing can be inspected separately in the editor's profiler. Include your window size and renderer when reporting performance.

The automated suite verifies headless gameplay logic and a full campaign flow. It does not verify rendered quality, GPU frame time, physical controller feel, or encounter balance.
