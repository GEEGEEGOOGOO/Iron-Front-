# Metal Slug 3D — Implementation Plan (Godot Engine)

**Genre:** 2.5D Run-and-Gun (3D models/environments, locked side-scrolling gameplay plane)
**Engine:** Godot 4.x (GDScript, upgradeable to C# later if needed)
**Scope:** Full game — core systems, multiple missions/levels, enemies, bosses, vehicles, progression
**Target for now:** MVP playable in-editor; platform export decided later

---

## 0. Design Pillars (read before building anything)

These are the non-negotiable rules that keep "3D graphics, 2D gameplay" coherent. Every phase below refers back to these.

1. **Movement is locked to a 2D gameplay plane.** The player and most enemies move only along X (left/right) and Y (jump/crouch). The Z-axis (depth) is fixed or restricted to a very narrow band ("the lane"), purely for visual parallax/depth (foreground props, background layers, background-only enemies that shoot into the lane).
2. **Camera is a side-scrolling camera**, not a free third-person camera. It tracks the player on X, has limited/no control on Z, and is clamped by level bounds.
3. **Physics uses full 3D collision (`CharacterBody3D`, `RigidBody3D`, `Area3D`)** for accurate hit detection, ragdolls, and destructible props — but **movement input is constrained** to the gameplay plane via code, not by disabling 3D physics.
4. **Everything is data-driven** where possible: weapons, enemies, levels, and waves are defined as Resources (`.tres`) so designers can add content without touching code.
5. **Object pooling everywhere** — bullets, casings, explosions, enemies — because Metal Slug-style games throw huge numbers of entities on screen (bullet-hell moments, big explosions, swarms).

---

## Phase 0 — Project Setup & Architecture

### 0.1 Project Configuration
- Create Godot 4.x project, GDScript as primary language.
- Set **Rendering > Renderer** to Forward+ (desktop) for now; note Mobile renderer as a future toggle if targeting mobile/console later.
- Set physics tick rate: `Physics > Common > Physics Ticks per Second` = 60 (default is fine; keep consistent since run-and-gun timing is precision-sensitive).
- Enable **Jolt Physics** (Godot 4.4+ default engine, or via plugin on older 4.x) for more stable `CharacterBody3D` collision resolution — important for fast bullet/character interactions.
- Define **Input Map** actions early (see 0.4).
- Set project **Display > Window** to a fixed aspect ratio (e.g., 16:9) with "canvas_items" stretch mode if you keep a 2D HUD layer (Phase 7), since this is visually a 2D-composed game.

### 0.2 Folder Structure
```
res://
  assets/
    models/         (characters, weapons, vehicles, props - .glb/.gltf)
    textures/
    animations/
    audio/
      sfx/
      music/
  autoloads/         (singletons)
  data/
    weapons/         (WeaponData .tres resources)
    enemies/         (EnemyData .tres resources)
    levels/          (LevelData .tres resources)
    waves/           (WaveData .tres resources)
  scenes/
    player/
    enemies/
    weapons/
    projectiles/
    vehicles/
    levels/
    ui/
    fx/
  scripts/
    (mirrors scenes/ structure — or co-located .gd files next to .tscn, your preference)
  shaders/
  resources/         (shared PhysicsMaterial, Environment, etc.)
```

### 0.3 Core Architecture / Autoload Singletons
Register these as Autoloads (Project Settings > Autoload):

| Singleton | Responsibility |
|---|---|
| `GameManager` | Current game state (menu/playing/paused/gameover), lives, continues, current level, score |
| `EventBus` | Global signal hub (decouples systems — e.g. `player_died`, `enemy_killed`, `pow_rescued`, `weapon_picked_up`) |
| `AudioManager` | Plays SFX/music through pooled `AudioStreamPlayer` nodes, manages buses |
| `PoolManager` | Generic object pooling service (bullets, casings, explosions, enemy corpses) |
| `SaveManager` | Persists high scores, unlocked levels/weapons, settings |
| `InputManager` (optional) | Wraps input map, supports rebinding, controller/keyboard parity |

### 0.4 Input Map (baseline)
`move_left`, `move_right`, `jump`, `crouch` (hold = crouch/prone), `fire`, `fire_secondary` (grenade), `melee`, `interact` (enter vehicle / rescue POW), `switch_weapon` (if you allow carrying 2), `pause`.

### 0.5 Version Control
- Git repo from day one. `.gitattributes` with Git LFS for `.glb`, `.png`, `.wav`, `.ogg`, `.tres` binary blobs if large.
- `.gitignore`: `.godot/`, `*.tmp`, export builds.

---

## Phase 1 — Player Foundation & 2.5D Physics

This is the most important phase — get this wrong and everything downstream feels bad.

### 1.1 Player Node Structure
```
Player (CharacterBody3D)
  CollisionShape3D (capsule, standing)
  CollisionShape3D (capsule, crouching — swap or resize at runtime)
  MeshInstance3D / Skeleton3D (character model + AnimationPlayer/AnimationTree)
  Marker3D "MuzzlePoint" (per weapon, or child of weapon socket)
  Marker3D "WeaponSocket" (bone attachment point for held weapon mesh)
  Area3D "HurtBox" (for receiving damage, separate from movement collision)
  Area3D "InteractZone" (for POW rescue / vehicle entry)
  RayCast3D or ShapeCast3D (ground check, ledge check)
  Camera-related: NOT a child camera — camera is a separate rig (see 1.5)
```

### 1.2 Locking Movement to the Gameplay Plane
- Define a constant `LANE_Z := 0.0` (or the level's current lane depth, if you support multi-lane fighting — see 1.7).
- In `_physics_process`, **do not read a Z-axis input at all** for player locomotion — only X and Y.
- Use `CharacterBody3D.velocity` with `velocity.z` forcibly kept at 0 (or snapped back toward `LANE_Z`) every frame:
  ```
  velocity.x = input_x * speed
  velocity.y = gravity/jump calc
  # velocity.z left at 0, or lerp position.z toward LANE_Z if any drift occurs from pushes/collisions
  ```
- After `move_and_slide()`, **clamp `global_position.z`** to the allowed lane band to prevent physics pushes (e.g., from RigidBody3D collisions) from nudging the player off-plane.
- Character always faces along +X or -X (never rotates toward camera). Flip the model's mesh `scale.x` or use a `Skeleton3D` root rotation of 0°/180° to face movement/aim direction — this replaces 2D sprite-flipping.

### 1.3 Locomotion States (simple FSM)
States: `Idle`, `Run`, `Jump`, `Fall`, `Crouch`, `Prone` (optional), `Climb` (ladders), `Hurt`, `Dead`, `EnterVehicle`.
- Implement as a lightweight state machine (either a `StateMachine` node pattern with child `State` nodes, or a single script with an enum + `match` statement — for MVP scope, the enum+match approach is faster to build and sufficient).
- Each state defines: allowed inputs, gravity behavior, animation to play, whether firing is allowed.

### 1.4 Jump/Gravity Physics
- Standard platformer gravity, NOT realistic 3D gravity — Metal Slug jumps are floaty/controllable:
  - `gravity` applied only on Y.
  - Support **variable jump height** (cut velocity.y if jump button released early) for responsive control.
  - Coyote time (~0.1s) and jump buffering (~0.1s) — critical for run-and-gun feel.
- Ground detection via a short downward `ShapeCast3D`/`RayCast3D` rather than relying purely on `is_on_floor()`, to handle fast-moving platforms and slopes gracefully.

### 1.5 Camera Rig (Side-Scrolling in 3D)
```
CameraRig (Node3D) — separate scene, follows player on X only
  Camera3D (orthogonal-feel via narrow FOV + fixed distance, or true Orthographic projection for a classic look)
```
- **Projection choice:** Use `Camera3D.projection = ORTHOGONAL` for a faithful "flat" Metal Slug look, OR `PERSPECTIVE` with a fixed rotation and locked distance for more depth/parallax feel (recommended for showing off 3D models). Decide per level's art direction — this is a good early prototyping decision to test both.
- Camera position: `x = lerp(camera.x, player.x, follow_speed * delta)`, `y` mostly fixed or gently follows player's Y within a band (dead-zone box), `z` fixed at a set distance from the lane.
- **Look-ahead**: offset target X slightly in the direction of movement/aim for better forward visibility (classic run-and-gun camera trick).
- **Level bounds clamp**: each level defines `camera_min_x` / `camera_max_x` (and optionally min/max y for vertical sections) — clamp every frame so camera never shows outside the playable set.
- **Screen shake**: implement as a small random offset added post-clamp (explosions, big weapon fire, boss stomps), decaying over time. Route through an `EventBus.shake_requested(intensity, duration)` signal so any system can trigger it.
- **Boss-room camera lock**: support a trigger volume that pins the camera to a fixed framing for boss arenas (Metal Slug does this constantly).

### 1.6 Aiming System
- Player can aim in 8 directions classically (left/right/up/down/diagonals), even though movement is only X/Y — this is achieved by:
  - Reading aim input (stick direction or up/down held while moving) to select an aim angle.
  - Rotating only the **upper body bones** (via `Skeleton3D` bone overrides or a simple two-bone blend in `AnimationTree`) so legs keep running while torso/gun aims — OR swap discrete aim-pose animations if you skip advanced rigging for MVP.
  - Muzzle point direction is computed from the aim angle, not from the camera, so shooting stays reliable in a 2.5D view.

### 1.7 Optional: Multi-Lane Depth (Background/Foreground Combat)
Classic Metal Slug occasionally has enemies firing from the background or foreground. If you want this:
- Define 2–3 discrete `LANE_Z` values (e.g., -1.5, 0, +1.5).
- Player generally stays on lane 0; certain scripted moments allow switching lanes at fixed trigger points (ladders, doors) rather than free depth movement — keeps controls simple.
- Treat this as a **post-MVP stretch feature**; ship Phase 1 with a single fixed lane first.

### 1.8 Collision Layers/Masks Plan
Define early and document in a table (this avoids painful rework later):

| Layer # | Name | Used by |
|---|---|---|
| 1 | `world` | Level geometry, static props |
| 2 | `player` | Player CharacterBody3D |
| 3 | `player_hurtbox` | Player Area3D that receives enemy damage |
| 4 | `enemy` | Enemy CharacterBody3D |
| 5 | `enemy_hurtbox` | Enemy Area3D that receives player damage |
| 6 | `player_bullet` | Player projectiles |
| 7 | `enemy_bullet` | Enemy projectiles |
| 8 | `interactable` | POWs, pickups, vehicle entry zones |
| 9 | `destructible` | Crates, walls, barrels |
| 10 | `vehicle` | Drivable vehicle bodies |

Bullets use masks so player bullets only collide with `world`, `enemy_hurtbox`, `destructible`, `vehicle` — never `player_hurtbox` — and vice versa for enemy bullets.

---

## Phase 2 — Weapons & Combat System

### 2.1 Data-Driven Weapons
Create a `WeaponData` Resource (`.tres`) class with fields:
`name`, `damage`, `fire_rate`, `projectile_scene`, `is_hitscan (bool)`, `spread_angle`, `max_ammo`, `starting_ammo`, `reload_time (if applicable — classic Metal Slug has no reload, just pickups, so likely N/A)`, `muzzle_flash_scene`, `sfx_fire`, `is_explosive`, `explosion_radius`, `pickup_model`, `icon` (for HUD).

Weapon roster (classic-inspired, reskin freely):
- **Default sidearm** (infinite ammo, weak, fallback)
- **Heavy Machine Gun** (fast fire rate, medium damage)
- **Rocket Launcher / Iron Lizard** (explosive, splash damage, slow fire rate)
- **Shotgun** (short range, multiple pellets/raycasts per shot)
- **Flamethrower / Drop Shot** (continuous damage-over-time cone/area)
- **Laser / Energy weapon** (piercing hitscan, hits multiple enemies in a line)
- **Grenades** (arc-thrown, `fire_secondary`, always available, limited count)
- **Melee knife** (close-range, infinite, no ammo — used when out of gun ammo, classic ammo-empty scenario)

### 2.2 Firing Pipeline
1. Input `fire` held/pressed → check fire-rate cooldown and ammo.
2. Compute spawn transform at `MuzzlePoint`, oriented along the current 8-way aim direction.
3. **Hitscan weapons**: `RayCast3D`/`PhysicsDirectSpaceState3D.intersect_ray()` on frame of fire — instant damage application, spawn a tracer VFX line.
4. **Projectile weapons**: pull a pooled projectile scene (`Area3D` or `RigidBody3D` with a simple forward-velocity script), set velocity along aim direction, register a `body_entered`/`area_entered` handler for damage + destruction.
5. Apply **damage via a shared `Damageable` interface/component** (see 2.5), not by hardcoding "if player then... if enemy then...".
6. Trigger muzzle flash VFX, shell casing pooled particle, camera micro-shake, SFX (via `AudioManager`), ammo decrement, HUD update signal.

### 2.3 Explosions & Splash Damage
- On projectile impact for explosive weapons: spawn pooled explosion VFX + `Area3D` with a sphere `CollisionShape3D` for one physics frame (or use `intersect_shape` query) to find all `Damageable` bodies within `explosion_radius`.
- Apply falloff damage by distance from explosion center.
- Trigger camera shake proportional to explosion size/proximity to player.
- Explosions should also damage/destroy `destructible` layer objects (Phase 5).

### 2.4 Weapon Pickups
- Pickup is an `Area3D` in the level (or dropped by defeated enemies/crates) holding a reference to a `WeaponData`.
- On player `InteractZone`/body overlap: replace current weapon (classic Metal Slug swaps instantly, no inventory management) and set ammo to the pickup's granted amount.
- If player already holds max-tier weapon, picking up same type tops up ammo instead.

### 2.5 Damage & Health Component
Build a reusable `HealthComponent` (Node script attached to player, enemies, vehicles, destructibles):
- `max_health`, `current_health`, `take_damage(amount, source)`, `die()`.
- Emits `EventBus` signals on damage/death so UI, score system, and AI can react without tight coupling.
- Supports **hitstun** (brief flinch animation) for enemies, and **invincibility frames** for the player after being hit (classic run-and-gun mercy window).
- Player health in classic Metal Slug is usually 1-hit-kill unless in a vehicle — decide: (a) authentic 1-HP player (harsh, arcade-accurate) or (b) small HP pool for a friendlier MVP. Recommend starting with **option (b), 2–3 HP**, for smoother early testing, with a difficulty setting to go 1-HP "arcade mode" later.

### 2.6 Hit Feedback / Juice
- Hitstop (brief `Engine.time_scale` dip, ~0.03–0.06s) on heavy hits/explosions.
- Enemy flash-white shader on hit (a simple emission-boost material override triggered via `AnimationPlayer` or shader param tween).
- Ragdoll or death animation + pooled corpse fade-out after a few seconds (don't let corpses accumulate forever — recycle via `PoolManager`).

---

## Phase 3 — Enemy AI

### 3.1 Enemy Base Class
`EnemyBase (CharacterBody3D)` script, extended per enemy type, holding:
- `HealthComponent`
- `EnemyData` resource reference (`move_speed`, `damage`, `fire_rate`, `detection_range`, `attack_range`, `score_value`, `drop_table`)
- Simple FSM: `Idle/Patrol → Alert → Attack → (Hurt) → Dead`
- Movement locked to the same X/Y plane rules as the player (Section 1.2) unless it's a background-lane enemy (1.7).

### 3.2 Enemy Archetypes (build as data + light behavior variation, not fully separate classes where possible)
- **Grunt Soldier**: walks toward/holds position, fires sidearm, low HP, dies in 1–2 hits.
- **Heavy Gunner**: stationary or slow, higher HP, higher damage, may need to be flanked.
- **Grenadier**: lobs arcing grenades (reuses player's grenade arc logic).
- **Melee Rusher**: charges player, only melee damage, fast.
- **Sniper/Turret (fixed emplacement)**: doesn't move, telegraphed shot, high damage — teaches players to use cover.
- **Background lane enemy** (optional, Phase 1.7 dependent): visually behind main plane, shoots into player's lane.

### 3.3 Enemy Detection & Combat Logic
- Detection via distance check + optional `RayCast3D` line-of-sight check against `world` layer only (ignoring other enemies) so enemies can't "see" through walls.
- Attack range check → transition to `Attack` state → face player (flip along X) → fire using the **same weapon-firing pipeline as the player** (2.2) so behavior is consistent and reusable.
- Simple cooldown/telegraph timers so enemies don't all fire in perfect sync (add small random jitter per-instance).

### 3.4 Spawning System
- `EnemySpawner` node placed in level, referencing a `WaveData` resource: list of `(enemy_scene, spawn_point, delay, trigger_condition)`.
- **Trigger conditions**: on level load, on reaching an X-position trigger volume (classic "walk forward, door opens, enemies pour in, door locks until cleared"), on timer, or on previous wave cleared.
- **Gate mechanic**: an invisible `Area3D` "encounter trigger" that, when entered by the player, closes off backward camera scroll and spawns a wave; camera unlocks once `wave_cleared` signal fires from the spawner (all enemies in that wave dead). This is a signature Metal Slug pacing tool — implement it early, it structures entire levels.

### 3.5 Enemy Vehicles/Mechs (non-boss, regular encounters)
- Small tanks/mechs the player can destroy for a weapon pickup or that must be avoided — treat as a variant using the vehicle collision rules (Phase 4) but AI-controlled instead of player-controlled, with a `HealthComponent` and simple attack pattern (fire shells, ram).

### 3.6 Boss Framework (used again in Phase 11)
- `BossBase` extends `EnemyBase` with:
  - Multi-phase state machine (`Phase1 → Phase2 → Phase3` based on HP thresholds).
  - Attack pattern list per phase (array of `AttackPattern` resources: telegraph time, attack script/animation, cooldown).
  - A dedicated boss health bar UI hook (Phase 7).
  - Camera lock trigger integration (Phase 1.5).

---

## Phase 4 — Vehicles (the "Metal Slug" Tank & friends)

### 4.1 Vehicle Base
`VehicleBase (CharacterBody3D or RigidBody3D)`:
- Own `HealthComponent`, own movement speed/handling (typically slower, more powerful than on-foot).
- Mounted weapon(s) with a separate, usually stronger `WeaponData` (e.g., cannon + machine gun combo like the classic SV-001 tank).
- Player enters via `InteractZone` overlap + `interact` input; on enter, player node is hidden/disabled and control switches to the vehicle; on exit (`interact` again, or vehicle destroyed), player is re-instantiated at the vehicle's position.
- Vehicle destruction: big explosion, player is ejected (forced into on-foot state, brief invulnerability), vehicle wreck left as a pooled destructible prop.

### 4.2 Vehicle-Specific Physics
- Vehicles still respect the plane-lock rule (Phase 1.2) but may have different collision shape (larger capsule/box), different jump behavior (some Metal Slug vehicles can jump/slam), and may crush certain enemy types or destructible props on contact (simple "ram damage" via body collision + velocity check).

### 4.3 Vehicle Types to Plan For
- Main battle tank (primary, drivable, cannon + MG).
- Optional secondary vehicles per level theme (e.g., camel/animal mount for desert level as a humor/traversal variant, helicopter for a rail-shooter-style level — mark these as stretch goals beyond MVP).

---

## Phase 5 — Level Design & World Systems

### 5.1 Level Data Structure
`LevelData` Resource: `level_scene_path`, `mission_name`, `par_time`, `wave_data_list`, `camera_bounds`, `checkpoint_positions`, `background_music`.

### 5.2 Level Scene Composition
```
Level (Node3D)
  Environment (WorldEnvironment node — fog, ambient light, tonemap per level mood)
  DirectionalLight3D (sun/key light)
  Geometry/
    Ground (StaticBody3D, walkable collision along the lane)
    BackgroundLayer (visual-only meshes, no collision, parallax-style depth staging)
    ForegroundLayer (visual-only meshes for depth framing, may partially occlude gameplay for style)
  Props/
    Destructibles (crates, barrels, walls — see 5.4)
    StaticDecor
  Triggers/
    EncounterTriggers (Area3D, Phase 3.4)
    CameraLockZones (Phase 1.5)
    CheckpointMarkers
    LevelEndTrigger
  Spawners/ (EnemySpawner nodes, Phase 3.4)
  Pickups/ (weapon pickups, health, POW cages)
  NavigationOrPathHints (optional, if enemies need patrol paths — Path3D + PathFollow3D per patrol route)
```

### 5.3 "Rail" Level Flow (how forward progress works)
- The level is authored as a long corridor along X. Camera + player move rightward (or level-defined direction) by default.
- **Soft-lock scrolling**: camera won't advance past the player's max reached X (classic run-and-gun "can't outrun the camera, but also can't be left behind" boundary) — implement via clamping player min-X to `camera.x - screen_half_width` and player max-X to `camera.x + screen_half_width`, updated as camera advances.
- **Hard gates** at encounter triggers (Phase 3.4) fully stop camera advance until wave cleared.
- Occasional **vertical sections** (ladders, elevators) where camera reorients to track Y instead of X — plan these as distinct camera-behavior zones with their own bounds.

### 5.4 Destructible Environment
- `Destructible (StaticBody3D or RigidBody3D)` with its own small `HealthComponent`.
- On destroyed: swap mesh for a "broken" variant or spawn debris `RigidBody3D` pieces (pooled), remove collision, optionally reveal a pickup or shortcut behind it (classic "shoot the wall to find a POW" secret).

### 5.5 Prisoners of War (POW) Rescue — signature Metal Slug mechanic
- `POW (Area3D/StaticBody3D)` placed in cages/behind destructible walls throughout levels.
- Player `interact`/melee near a POW to "free" them; POW runs off-screen and grants a random reward (extra weapon ammo, score bonus, extra life, or a food item for a small score/health bonus) resolved through a simple weighted-random reward table (data-driven `.tres`).
- Track POWs rescued per level for end-of-level scoring/ranking (Phase 10).

### 5.6 Level Streaming
- For MVP, single-scene levels are fine. If levels get large, split into segments loaded/unloaded via `Node3D` visibility + `ResourceLoader.load_threaded_request` as the camera crosses zone boundaries, to control memory.

---

## Phase 6 — Scoring, Lives & Continue System

- `ScoreManager` (part of `GameManager` or its own autoload): tracks score, combo/kill-chain bonuses (optional), POWs rescued, accuracy.
- Classic arcade **lives + continues**: player has N lives; death consumes a life and respawns at last checkpoint; 0 lives triggers "Continue?" countdown (arcade authenticity) or simple Game Over for a friendlier MVP.
- Checkpoints: `CheckpointMarker` nodes update `GameManager.current_checkpoint`; respawn logic restores player position, current weapon reset to default (classic behavior — dying strips your weapon upgrade), and clears/resets any in-progress wave triggers as needed.

---

## Phase 7 — HUD & UI

### 7.1 In-Game HUD (CanvasLayer, 2D overlay on top of the 3D viewport)
- Health/lives icons (top-left, classic style).
- Current weapon icon + ammo count.
- Score (top-right or top-center).
- POW rescued counter.
- Boss health bar (only active during boss encounters, Phase 3.6 hook).
- Grenade count.

### 7.2 Menus
- Main Menu (Start, Level Select if unlocked progressively, Options, Quit).
- Pause Menu (Resume, Restart Checkpoint, Options, Quit to Menu) — use `get_tree().paused = true` with the HUD/pause menu on a `process_mode = ALWAYS` `CanvasLayer`.
- Mission Start card (level name splash, classic "MISSION 1" title card).
- Game Over / Continue screen.
- Level Complete summary (score breakdown, POWs rescued, time).

### 7.3 Implementation Notes
- Build HUD in Control nodes on a `CanvasLayer` above the `SubViewport`/main 3D viewport — since the "3D" is purely visual, keep the entire UI system standard 2D Control-node UI (no need for 3D world-space UI except optional enemy health bars/damage numbers, which can use `Label3D` or billboarded `Sprite3D`).

---

## Phase 8 — Audio

- `AudioManager` autoload with separate **Buses**: `Master → Music, SFX, UI, Voice`.
- Music: per-level looping track, intensity layer swap for boss fights (optional: crossfade to a "boss theme" bus layer).
- SFX pooling: reuse a small pool of `AudioStreamPlayer3D` nodes for gunfire/explosions rather than instancing new players constantly (positional audio adds to the 3D feel — explosions/enemy fire should be spatial).
- Voice lines (optional, classic Metal Slug has radio/announcer barks): "Mission Start", "Enemy Approaching", boss intro — hook these to `EventBus` signals.

---

## Phase 9 — VFX & Game Feel Polish

- Muzzle flashes: pooled `GPUParticles3D` or simple billboard quad + flipbook shader.
- Shell casings: pooled small `RigidBody3D` with a short lifetime, ejected on fire.
- Explosions: layered particle bursts (core flash + smoke + debris), pooled.
- Screen shake (Phase 1.5), hitstop (Phase 2.6).
- Damage numbers (optional, `Label3D` billboard, pooled, fades/rises and despawns).
- Death animations vs. simple flinch-and-fade for minor enemies (perf budget: only "important" enemies deserve full ragdoll).

---

## Phase 10 — Progression, Save & Meta Systems

- `SaveManager`: JSON or Godot `ConfigFile`/`FileAccess` based save of: unlocked levels, high scores per level, settings (volume, key bindings).
- Level select screen unlocks sequentially on completion (or open from the start for MVP simplicity — recommend open-all for MVP testing, add gating later).
- End-of-level rank/grade (S/A/B/C) based on score, time, accuracy, POWs rescued — classic arcade flavor, low implementation cost, high perceived polish.

---

## Phase 11 — Boss Battles (content pass, using Phase 3.6 framework)

- Design 1 boss per major level/mission (MVP: at least 1 fully realized boss to validate the framework end-to-end before authoring more).
- Each boss: intro camera cinematic (simple `AnimationPlayer` camera move + lock, Phase 1.5), 2–3 phases, distinct attack patterns, weak-point mechanic if desired (e.g., glowing core takes bonus damage), death sequence (multi-stage explosion + score bonus + POW cage reveal, classic reward pattern).

---

## Phase 12 — Optimization & Technical Polish

- **Object pooling audit**: confirm bullets, casings, explosions, enemies, debris all route through `PoolManager` — no runtime `instantiate()`/`queue_free()` churn during gameplay.
- **Culling**: rely on Godot's built-in frustum culling; since camera movement is constrained/predictable, consider manually disabling `_physics_process` on enemies/props far outside the camera bounds (cheap, effective for a linear level).
- **LOD**: simple mesh LODs or `VisibilityRange` on background/foreground decoration meshes if levels get dense.
- **Profiling**: use Godot's built-in profiler/monitor regularly once Phase 3 (many enemies) is in place — watch physics process time and draw calls specifically, since 3D models + high enemy counts + particles is the main perf risk area vs. the original's 2D sprites.
- **Fixed timestep discipline**: keep all gameplay-affecting logic in `_physics_process`, not `_process`, for determinism (important for consistent hit detection).

---

## Phase 13 — Testing & QA Pass

- Playtest each level standalone via a level-select debug menu (build this early — massive time saver).
- Debug console/cheats: god mode, level skip, weapon-give, spawn-specific-enemy — implement as a simple autoload debug overlay, strip/hide for release builds.
- Balance pass: enemy damage/HP, weapon damage/ammo economy, wave difficulty curve.
- Controller + keyboard parity testing (8-way aim is the highest-risk area for input mismatches).

---

## Phase 14 — Build & Export (deferred, per your note)

- Not needed for MVP editor testing now. When ready: configure export presets (Windows/Linux/etc.), decide on the renderer trade-offs (Forward+ vs Mobile) based on final target platform, and re-test performance on target hardware before wide release.

---

## Suggested Build Order (practical sequencing, not just phase numbers)

1. Phase 0 (setup) → Phase 1 (player movement/camera — get this *feeling* right first, in a blank gray-box level).
2. Phase 2 (basic weapon: hitscan pistol only) → confirm damage pipeline against a dummy target.
3. Phase 5.1–5.3 (one gray-box level with encounter gates) + Phase 3.1–3.4 (one grunt enemy type + spawner) → first playable loop.
4. Phase 6 (lives/score) + Phase 7 (minimal HUD) → first "real" testable slice.
5. Expand weapons (2.1 roster), enemy variety (3.2), destructibles (5.4), POWs (5.5).
6. Phase 4 (vehicle) once on-foot loop is solid.
7. Phase 3.6/11 (first boss) to validate the boss framework.
8. Phase 8–9 (audio/VFX polish pass).
9. Phase 10 (save/progression).
10. Repeat 5–7 to build out remaining levels/missions/bosses using the now-proven systems.
11. Phase 12–13 (optimization/QA) continuously, not just at the end.

---

## Open Decisions to Revisit Later
- Orthogonal vs. perspective camera (test both early, Section 1.5).
- Player HP model: authentic 1-hit-kill vs. small HP pool (Section 2.5).
- Multi-lane background combat: include or cut for MVP (Section 1.7).
- Level gating: sequential unlock vs. open level-select for testing (Phase 10).
- Platform/export target (Phase 14) — deferred per your request.
