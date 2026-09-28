# Plan audit — implementation evidence and open work

This maps the supplied plan to the current source. “Implemented” is not a claim of visual quality, balance or rendered performance. Optional/stretch/deferred items remain optional; the full goal is not complete.

| Plan area | Current evidence | Open work / verification |
|---|---|---|
| 0 Setup | project.godot, six autoloads, Git repository, binary asset attributes, resources | No export target requested; Git LFS is unavailable and unnecessary for the current small assets |
| 1 Player/physics | player.gd, camera_rig.gd, ladder/elevator scenes; aim/traversal/camera tests | Manual motion and controller hardware review; scene-component structure remains programmatic |
| 2 Combat | WeaponData, Combat, pooled projectiles, HealthComponent, sidearm/special switching; combat/reset/input tests | Weapon icons are implemented; remaining presentation/resource hooks and visual review |
| 3 Enemies/waves | EnemyData, EnemySpawner markers, WaveData trigger modes, BossData/AttackPattern, role-specific soldier gear | Manual encounter balance and visual readability |
| 4 Vehicles | Tank drive, weapons, armor, ejection and ram tests | Manual handling and collision review; secondary vehicles are stretch goals |
| 5 World | Three world scenes, themed props, cages, weighted rewards, ladders/elevator; mission-specific tank, supply, boss, and flank placements | Automatic geometry limits editor previews; route pacing needs manual review |
| 6 Score/lives | Checkpoints, lives, game-over, itemized score; scoring/pause/reset tests | End-to-end manual difficulty and checkpoint economy |
| 7 UI | Main/pause/options/controls/results, HUD, boss bar, mission start cards | Visual layout review at target window sizes |
| 8 Audio | Original music loops, positional SFX pool, buses/settings; audio tests | Listening/mix review; announcer voice is optional |
| 9 Effects | Hit flash, hitstop, shake, physical casings/debris, staged boss explosions | Layered flash/smoke now implemented; manual feedback review remains |
| 10 Save/progression | JSON high scores/settings/key bindings, open mission select, ranks | Normal save robustness and manual persistence review; missions intentionally open for MVP |
| 11 Boss content | Three boss configs/attack sequences, intro framing, phase transition cues, commander rescue; boss tests | Distinct visual silhouettes and manual attack-pattern balance |
| 12 Optimization | Fixed pools, distant-enemy update skip, reused ray queries, stress metrics | Rendered draw-call/GPU profiling and decoration visibility ranges; headless timings are insufficient |
| 13 QA | Discovered regression suite, complete headless campaign flow, temporary saves and bounded runner | Manual campaign, controller, visual and audio playtest remains user-owned as requested |
| 14 Export | Deferred | No export work required now |

Newly closed gap: wave trigger modes now include level-start, elapsed-time, and previous-wave-clear delay as well as position. The existing authored missions retain position triggers. `wave_regression` checks thresholds and reset behavior.
