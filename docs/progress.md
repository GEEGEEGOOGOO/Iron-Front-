# Implementation status

Source specification: `implementation-plan.md` (unmodified copy of the user-provided plan).

## Decisions

- Original working title and procedural art: IRON FRONT.
- Perspective side camera; fixed gameplay Z = 0.
- Default 3 HP; arcade 1 HP option, applied on mission start/respawn.
- Three missions available from the start for editor testing.
- Export, extra depth lanes and secondary vehicle types remain deferred as specified.

## Implemented foundation

Project configuration, collision layer names, six core autoloads, keyboard/gamepad input, resource-driven weapons/enemies/waves/levels, reusable health, fixed-capacity pools, menu and mission flow, player movement and combat, enemy archetype variations, encounters, checkpoints, rescues, destructibles, pickup rewards, tank entry/exit/destruction, basic boss phases, score/rank/high-score persistence, HUD/options/debug controls.

## Remaining work against full plan

- Mission content: three different resource-authored platform layouts and coastal crane/freight, desert ruins and foundry furnace props now exist. Rescue, crate, barrel and encounter positions are now mission-specific and resource-authored; the missions still share the corridor-generation system. Manual pacing/balance review remains.
- Character and enemy presentation: continue refining the original procedural models and death animation. Soldiers now have articulated limbs, directional facing, walking/climbing/airborne poses and independently aimed arms. Enemy tanks and bosses now use preallocated armored-machine models with matching hurt volumes. Further boss silhouette variation and visual animation review remain.
- Remaining combat fidelity: further explosion-layer polish. Boss intros now use a timed camera push-in and restore the configured framing. Boss deaths now stage multiple explosions and reveal/rescue a commander before the result screen. Flame now applies repeated cone damage; knife uses a forward cone without explosion effects; enemies flash on hit and explosions request 45 ms of hitstop.
- Architecture expansion: remaining weapon/level metadata. Encounter placement is now authored through EnemySpawner nodes, WaveData resources and camera/spawn markers. Each mission now has a resource-backed world scene and a standalone F6 entry scene.
- Vertical traversal: each mission now has a resource-positioned ladder and elevated supply platform, climb/hold/dismount states, and bounded vertical camera tracking. The foundry now also has a freight elevator and raised supply landing. More authored camera zones remain. Crouch checks standing clearance.
- Audio now includes original looping mission cues, a boss cue, pooled positional combat SFX and saved per-bus sliders. Listening/mix review remains part of the manual playtest.
- Keyboard rebinding and default restoration are exposed in Options and persisted; mission select displays recorded best scores. Controller hardware parity still needs manual testing. All missions remain available for MVP testing.
- Pool audit: pickups now reuse a fixed 48-item pool; physical casings/debris now use a fixed 160-item RigidBody3D pool. Enemy/effect/projectile pools do not grow during gameplay.
- Regression coverage now includes bosses, combat, audio, saved bindings, rewards, pools, tank ram, ladders and elevator behavior. Broader mission reset edge cases, controller hardware parity, balance and meaningful rendered performance measurements remain.
- Manual visual/playability and balance review remains to be performed by the user in Godot as requested.

## Verification

- Godot 4.7.2 headless editor import: passed.
- Main-menu runtime startup: passed with no logged script/runtime errors.
- Initial smoke test across all three missions: passed ground/lane, waves and rocket checks.
- Expanded three-mission smoke test: passed vehicle entry, destruction/ejection, invulnerability, life consumption, respawn and default weapon reset; no logged script/runtime errors.

Do not treat this checklist or the smoke test as evidence that the entire game specification is complete.

## Combat follow-up

- Weapon range, piercing count and cone parameters are resource fields rather than weapon-name checks.
- Laser accuracy counts one successful shot regardless of victims pierced.
- Zero-damage cosmetic blasts no longer trigger damage or invulnerability.
- Respawning while driving first exits the vehicle; recycled effects/actors reset transient state.
- Enemy tracking avoids duplicate references when pooled actors are reused.
- `tests/combat_regression.tscn` passes directional melee, repeated cone damage, cover occlusion, laser piercing/accuracy, standing clearance and zero-damage checks.

## Mission and boss resource pass

- `AttackPattern` and `BossData` resources configure three named bosses with distinct attack sequences, HP, phase gates, projectile speeds and telegraphs. Each encounter grants an intro grace period.
- Platform position/size arrays and a theme field live in each LevelData resource.
- Boss regression passes all three mission spawns, three health phases, gated pattern selection, projectile plane lock, death and completion.
- Regression exposed and fixed a scene-transition race: retiring levels now leave the tree before the next mission is added.
- The user still owns manual Godot visual testing. Headless checks do not establish visual polish or difficulty balance.

## Audio pass

- Four original synth cues are generated reproducibly by `tools/generate_music.py` and stored as WAV assets. Mission resources select background and boss music.
- The audio manager caches looping streams and preallocates 32 positional SFX voices; menu feedback uses the UI bus.
- Options persist Master/Music/SFX/UI/Voice levels. Zero volume explicitly mutes; increasing volume unmutes.
- Checkpoint restart restores the mission cue. Boss entry switches cues. Menu/results stop music and combat sound tails.
- `tests/audio_regression.tscn` passes cue uniqueness, looping, routing, boss/mission switching, fixed pool size during bursts, volume save/mute behavior and shutdown. No audible quality claim is made by a headless test.

## Controls and progression menu pass

- Options → Controls remaps keyboard movement, aim, jump, fire, grenade, melee, interaction and pause. Controller bindings remain intact.
- Duplicate action keys and debug-reserved F3–F7 are rejected; Escape cancels key capture. Default restoration restores arrow-key alternates.
- Saved bindings load at startup. Menu help and in-game control hints reflect the current keys.
- Mission select displays saved high scores.
- Input regression covers save/reapply, duplicate/reserved-key rejection, controller mapping preservation, remapping while paused, cancellation and default restoration.

## POW and pickup pass

- Weighted `RewardTable` resources configure supplies, bonus score and extra-life chances. LevelData selects its table.
- Rescued POWs run away; a rescued flag prevents duplicate awards even while the character remains visible.
- Pickups now preallocate meshes/collision/labels once and recycle after collection.
- Reward regression passes weighted selection boundaries, safe empty-table fallback, rescue idempotency, escape movement, score/life grants and pickup reuse without scene-node allocation.

## Physical fragment pass

- Gunfire ejects physical shell casings; explosions and crates emit physical debris. The fixed 160-item pool preallocates mesh, shape and material resources.
- Fragments collide only with world geometry, expire automatically and freeze with zero collision masks when recycled. Pool exhaustion omits cosmetic fragments instead of growing the scene tree.
- Fragment regression checks gravity, ground collision, collision masks, frozen recycling, bounded capacity and expiry of a full 160-fragment burst.

## Tank ram pass

- Occupied tanks moving above the speed threshold deal directional ram damage to enemy hurtboxes and destructibles. A 0.45-second cooldown prevents per-frame repeated damage.
- Ram regression passes occupancy/speed guards, directional hits, damage amount, cooldown and a subsequent finishing hit.

## Ladder traversal pass

- Level resources define ladder positions/heights; each ladder reaches a raised supply platform.
- Player climb state respects the gameplay plane, supports holding position, upward/downward movement and jump/sideways dismount. Respawn clears ladder state.
- Camera Y follows elevation within a bounded band while keeping horizontal encounter locks.
- Traversal regression passes ascent, top reach, lane lock, vertical camera tracking, holding and platform dismount in all three missions.

## Freight elevator pass

- Resource-defined elevator positions and travel distances build an AnimatableBody3D lift with top/bottom dwell periods in the foundry.
- Elevator regression passes player carrying upward and downward, gameplay-plane lock and pause stability.

## Integrated regression runner

- `tools/run_tests.py` imports the project, discovers regression scenes and runs each in a separate headless process with a 90-second timeout.
- Each test gets an isolated temporary save path, leaving normal player progress and settings untouched.
- A passing result requires zero exit status, the expected completion marker and no logged engine/script errors; logs and a machine-readable summary are retained under ignored `test-results/`.

## Boss defeat sequence

- Bosses emit timed secondary explosions before recycling; a preallocated commander appears and escapes after destruction.
- The commander adds one rescue and 500 points exactly once, with a short victory delay and player protection before results. HUD/results now show four available POWs per mission.
- Boss regression additionally verifies the commander award and delayed mission completion.

## Articulated soldier pass

- Shared SoldierVisual builds pivoted arms/legs, boots, helmet, visor and backpack. Fixed-step pose updates drive stride, climbing and airborne poses, facing, and arm aim.
- Player, foot soldiers and rescued POWs use the rig; enemy flash overlays traverse all limb meshes.
- Headless import and combat regression pass after the model change. Animation appearance remains unverified until manual Godot review.

## Mission tally pass

- Results itemize combat/pickup score, rescue bonus, time bonus and total, alongside rescue count, time, accuracy and rank.
- Time bonuses use LevelData.par_time; repeated completion cannot reapply bonuses. Accuracy is bounded to 0–100%.
- Scoring regression passes configurable par time, itemized bonuses, save totals, idempotent completion, zero-shot accuracy and over-par behavior.

## Standalone mission scenes

- Each LevelData references a world PackedScene with its level resource exposed in the Inspector. Menu and standalone launches use those same world scenes.
- `scenes/levels/mission_1.tscn` through `mission_3.tscn` support F6 launch with pools, player, HUD and menus initialized.
- Scene regression passes correct mission selection, world scene loading, player creation and HUD setup for all three entry scenes.

## Editable encounter placement

- World scenes contain three EnemySpawner nodes with camera-focus and spawn markers. Runtime uses these nodes for trigger X, locked framing and enemy placement.
- Wave resources are duplicated before placement overrides, preserving source assets.
- `docs/authoring.md` documents scene order, lane constraints and the runtime-generated geometry limitation.

## Camera configuration pass

- LevelData exposes horizontal/vertical bounds, perspective/orthographic projection, FOV/size and player screen limits. Boss locks obey those bounds.
- Boss intros briefly push in before restoring framing; checkpoint reset clears the intro.
- Camera regression passes both projections, bound enforcement and intro restoration. Visual framing still needs manual review.

## Pool and checkpoint reset pass

- Enemy activation restores projectile speed, hurt/death timers and visual displacement; pooled flashes restore their full mesh scale.
- Checkpoint resets clear projectiles, flashes and physical debris, cancel hitstop and reset vertical camera offset/shake.
- Reset regression verifies actual actor reuse and all of these reset conditions.

## Enemy drop tables

- EnemyData exposes a weighted RewardTable and drop chance. Regular enemies have a small supply-drop chance; enemy tanks guarantee a rocket/laser pickup.
- Death handling is idempotent, preventing repeated score/drop awards.
- Drop regression passes guaranteed tank rewards, configured-table selection and duplicate-death protection. Drop probabilities are initial balance values for manual testing.

## Combat stress measurement

- Added a repeatable 360-frame headless stress scenario: 48 heavy enemies, 12 projectile requests per frame, and repeated physical debris bursts.
- Capacity assertions pass: 712 pooled root nodes remain fixed, peak borrowed objects reach 591, saturated projectile requests are rejected without allocation, and all borrowed objects return on menu exit.
- Measured on this host: median physics 6.528 ms, p95 132.894 ms. These numbers reveal spikes and do not meet a 16.67 ms frame-budget claim. Investigate physics/update hotspots and repeat after changes; do not present pool stability as performance completion.
- Headless measurement excludes GPU/rendering cost. Raw metrics are retained in ignored `test-results/stress_metrics.json`.

## Stress measurement correction and projectile allocation

- Corrected the stress procedure to seed its workload, separate 120 warm-up ticks and report 360 sustained-load samples. Godot monitor values can repeat; their percentile is not an independent per-frame latency percentile.
- Warm-up-aware baseline: physics monitor median 7.105 ms, p95 7.966 ms, warm-up maximum 133.093 ms. The earlier 132.894 ms p95 mixed startup into the report and must not be interpreted as sustained gameplay p95.
- Projectiles now reuse one PhysicsRayQueryParameters3D each instead of allocating one every physics tick. Same workload after change: median 6.959 ms, p95 7.268 ms; pool occupancy and denied requests remained identical. This single comparison suggests a modest improvement, not a statistical performance guarantee.
- Render/GPU cost and manual playability remain unverified. Startup remains substantially heavier than steady-state physics.

## Pause and final-life restart

- Fixed the pause-menu checkpoint action overriding Game Over when the player had zero lives. It now preserves Game Over and unpauses the result UI.
- Pause regression passes projectile/clock freezing, ordinary checkpoint resume and final-life restart behavior.

## Aim input parity

- Added simulated physical-key and joy-axis coverage for all eight airborne aiming directions plus stick deadzone behavior.
- The test flushes buffered input between sequences so a pending neutral event cannot overwrite the next input combination.
- Aim regression passes. This verifies mapping/logic parity, not physical controller hardware or subjective aiming feel.

## Destructible POW cages

- Regular POWs now start in visible destructible cages. Weapons can break the cage; close interaction/knife rescue opens it directly. Remote destruction unlocks the prisoner without granting an out-of-range rescue.
- Cage destruction disables collision and emits pooled metal fragments; rescue remains idempotent.
- Reward regression also checks cage damage, unlocking, collision removal and prevention of remote rescue credit.

## Weapon HUD icons

- Six original SVG silhouettes are linked through WeaponData.icon and shown beside the HUD, updating with the equipped weapon.
- Mission scene startup checks pass after importing the icons. HUD visual layout remains subject to manual review.

## Layered explosion effects

- A fixed 64-item burst pool provides expanding bright cores and rising, fading smoke spheres alongside existing physical debris.
- Materials/meshes are initialized once, effects recycle after their lifetimes, and checkpoint resets clear the new pool category.
- Visual appearance still requires the user’s manual Godot review; headless runtime checks cannot establish effect quality.

## Enemy visual differentiation

- EnemyData.tint now drives uniforms/armor. Grunts, heavies, grenadiers and rushers use distinct colors; heavies have a larger silhouette and matching hurt volume. Turrets use a compact armored emplacement model.
- Pooled soldier rigs reset limb pose/cycle on reuse. Combat regression still passes after silhouette/hurtbox changes; visual readability awaits manual review.

## Save validation and replacement

- Save loading validates known field types, clamps volume/unlock ranges and preserves valid score entries while ignoring malformed entries.
- Writes flush to a temporary file and rename it over the destination after successful writing; failures leave the previous destination intact and report a warning.
- Save regression passes sanitization, file replacement, score reload and malformed JSON handling using an isolated test path.

## Boss silhouette equipment

- BossData selects prebuilt bulwark, mortar or reactor equipment and armor tint. Each mission now has a different boss silhouette as well as different attack resources.
- Equipment meshes are allocated during pool initialization and hidden/reset between uses. No boss-spawn mesh allocation is introduced.
- Visual silhouette quality remains unverified until manual review in Godot.

## Mission placement variation

- Three missions now author separate POW/crate/barrel coordinates and encounter thresholds; resources/scene markers expose the placement for editing.
- Explosive barrels no longer inherit the default machine-gun crate reward.
- First-encounter smoke checks cover the revised opening triggers; full manual route pacing remains unverified.

## Integrated verification after mission placement and VFX changes

- The full test runner completed successfully: editor import plus 20 headless regression scenes. The stress run retained a fixed 776 pooled nodes with 48 heavy enemies and saturated projectile requests.
- One combat-test shutdown warning came from quitting immediately after stopping audio. Allowing 150 ms for audio playback cleanup removes the warning in that test; no gameplay behavior was changed for it.
- Headless suite success does not verify rendered art, controller hardware, sound balance, mission pacing or GPU cost. Manual Godot playtesting remains outstanding under the user's chosen workflow.

## Mission route authoring

- LevelData now exposes tank and supply placements plus the boss trigger, arena camera lock, spawn, room boundary, and rescued commander position. Dust Battalion and Midnight Foundry have their own values and supply mixes.
- The direct mission scene regression checks these placements and activates each boss at its configured threshold. Editor import, mission scene checks, and the three-mission smoke run pass.
- Smoke cleanup now allows audio teardown before quitting, matching the combat regression shutdown fix. Manual route and balance review remains necessary.

## Checkpoint wave replay

- Checkpoints now capture the pending wave index when secured. Respawn restores that exact index instead of inferring progress from X triggers, which incorrectly skipped timer and chained waves.
- A chained wave's delay restarts from the checkpoint reset when a prior wave was already cleared. The regression covers checkpoint capture, delayed replay, and an unplayed timer wave with an earlier X value.
- The full headless suite passed after the change: editor import plus 20 regression scenes. Manual campaign pacing and checkpoint feel still need Godot playtesting.

## Accuracy and campaign ending

- Friendly grenades now count as shots when thrown, and an explosive projectile counts one accuracy hit if its blast damages at least one target. Multi-target blasts still contribute one hit; decorative and barrel explosions do not affect accuracy.
- Mission three now shows a campaign completion result and returns to mission select instead of looping "Next Mission" to mission one. The remaining result button receives controller focus.
- Editor import and the focused combat and scoring regressions pass. Rendered combat readability and mission-end presentation still need manual review.

## Boss checkpoint replay

- Commander rescue credit and its 500-point award now require a successful new rescue. Restarting at a checkpoint during the boss victory delay and defeating the boss again cannot count the same commander twice.
- The boss regression replays that exact sequence in mission one, then completes all three bosses. Editor import and the boss regression pass.

## Source snapshot

- The project source, Godot UID/import metadata, resource data, tests, and small original audio assets are prepared for an initial local Git commit.
- Git LFS is unavailable on this host; current binary files are small, so `.gitattributes` treats them as binary instead of requiring a missing LFS filter. Large future models/audio can be moved to LFS when it is installed.

## Sidearm and special switching

- The previously mapped but unused switch action now toggles between the unlimited sidearm and one carried special weapon. Special ammo is preserved while stowed; a matching pickup refills it, a different pickup replaces it, and depletion or respawn clears it.
- Q and controller left shoulder are mapped; the action can be rebound in Options, and the HUD displays the switch cue when a special is carried.
- Editor import and input regression pass for controller mapping, switch state, ammo refill, and empty-ammo fallback. Controller feel and HUD layout await manual Godot review.

## Mission start card

- Each mission now opens with a large in-game title card showing its number, authored name, and objective. It fades out after 2.8 seconds while gameplay proceeds; pausing preserves the remaining display time.
- The direct scene regression checks the card content and expiry in all three missions. Editor import, scene and pause regressions pass. Visual composition still needs the user's Godot review.

## Enemy role silhouettes

- Heavy gunners now have shoulder and chest armor, grenadiers carry a pack and visible grenades, and rushers carry a forward blade and red headband. These are built once with the pooled soldier model.
- Activation shows only the equipment for the selected EnemyData behavior. The reset regression checks grunt-to-heavy-to-grenadier-to-rusher reuse; editor import and reset regression pass.
- Readability, color contrast, and draw-call cost need manual rendered review.

## Distinct mission encounters and campaign flow

- Desert waves now favor rushers and grenadiers, with two authored flank spawns. Foundry waves emphasize turrets and armor, culminating in two tanks and a rear turret. Mission two and three have longer par times appropriate to their larger rosters.
- Added a headless campaign flow check that starts every authored wave, clears it, defeats every boss, and verifies the commander/result transition. All three missions pass, as does the existing smoke test after the roster changes.
- The check does not measure whether those encounters are fair, legible, or fun. Their balance and spawn timing need the user's manual Godot playtest.

## Mission state consistency

- HUD and result POW totals now read the active level's prisoner count, so adding or removing authored rescues does not leave a stale `/ 4` display.
- Starting a mission resets debug god mode to prevent an invulnerability toggle from silently carrying into a later mission. Editor import and scoring regression pass these behaviors.

## Boss phase transitions

- Bosses now announce phases two and three with a banner, bright pooled effect, and camera shake when health crosses each threshold. A two-second attack pause makes the transition visible before the next unlocked pattern begins.
- The boss regression checks threshold cues and completes all three encounters. Editor import and boss regression pass; visual timing and difficulty need manual playtesting.

## Saved binding compatibility

- Saved keyboard bindings now resolve collisions with newly added default actions. For example, an older Fire=Q save keeps Fire on Q and moves Switch Weapon to Fire's freed J key, while controller mappings remain intact.
- The input regression covers this legacy case plus saving and reloading a custom Switch Weapon key. Editor import and input regression pass.

## Mission ground identity

- Coastal scenery now has water and dock markings, the desert has layered dunes and worn road markers, and the foundry has a glowing channel with hazard stripes. These are visual-only meshes behind or beside the fixed gameplay lane.
- Godot editor import and the three-mission smoke test pass after the additions. The rendered appearance and draw-call effect still need manual Godot review.

## Tank ram query reuse

- The drivable tank now keeps one configured physics shape query and updates its transform during ram checks, avoiding a new query object on each moving frame.
- Editor import and the existing ram regression pass for unoccupied, stationary, forward, cooldown, reverse, and finishing hits. This is an allocation reduction, not a measured FPS claim.
