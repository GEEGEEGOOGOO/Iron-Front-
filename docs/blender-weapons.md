# Blender weapon integration

The pistol, shotgun, and flamethrower now use the authored Blender geometry in
the existing 3D side-view game. Movement, enemy AI, damage, ammo balance, HUD,
pickups, and saves retain their existing behavior.

## Try them

Open `scenes/debug/blender_armory.tscn` and press **F6**. Use the three buttons
above the game view to equip the pistol, shotgun, or flamethrower. **J** fires,
**R** reloads, **A/D** moves, and **W** aims upward. These are the normal player
and combat systems; this scene only provides convenient equipment buttons.

The regular campaign starts with all three available: **1 pistol**, **2 shotgun**,
**3 flamethrower**, or click their visible buttons below the HUD. Switching retains
each weapon's magazine and remaining reserve; it never refills ammunition.
Existing finite reserve ammo applies to the shotgun and flame weapon; the pistol
has unlimited reserve. The flame gauge shows magazine fuel and turns blue during
reload. Reload does not create reserve ammunition.

## Portable assets and animation

- `assets/models/weapons/pistol.glb`: Body, Slide, Trigger.
- `assets/models/weapons/shotgun.glb`: Body, Pump, Trigger.
- `assets/models/weapons/flame.glb`: Body, Trigger; embedded portable wear maps.
- `scripts/components/blender_weapon.gd`: mechanical firing animation, bounded
  72-particle expanding flame plume, and fuel indicator.

Meshes are evaluated with Blender modifiers and combined by mechanical group.
Small UV wear maps approximate Blender's procedural corrosion; they are not
full-resolution Cycles bakes. glTF preserves metallic/roughness and emissive PBR
materials. Camera, lights, test targets, outgoing preview bullets, and Blender
Python control panels are excluded.

Godot owns the slide/pump/trigger motion through runtime tweens. Projectile,
hitscan, muzzle flash, casing, ammo and reload logic remain in the existing game
systems, so Blender preview scripts are never executed by Godot. The plume
stops emitting on release and lets existing particles grow and fade within a
finite lifetime. Flame damage still uses the existing obstructed cone query.

Source Blender files live under `art-source/weapons/<weapon>/models/`.
Review renders are in each weapon’s `previews/` folder; older versions are in
`backups/`. See [repository organization](repository-organization.md). Direct `.blend` auto-import is
disabled in `project.godot`: the game loads only explicit GLB exports and does
not require a local Blender install to import them.

## Re-export after model edits

From the project root, run each command using your Blender executable:

```sh
blender -b -P tools/export_blender_weapons.py -- pistol
blender -b -P tools/export_blender_weapons.py -- shotgun
blender -b -P tools/export_blender_weapons.py -- flame
```

The exporter reads the animated `.blend` sources at their idle frame, normalizes
their scale and grip origin, and never saves over them. Existing gameplay muzzle
distances are preserved. Godot imports the updated GLBs on the next scan.

## Verification

`tests/blender_weapons_regression.tscn` checks the actual GLB instances, moving
parts, ammo consumption, reload availability, particle budget, fuel gauge, and
flame release. The standard graphics gallery also displays the imported guns.
