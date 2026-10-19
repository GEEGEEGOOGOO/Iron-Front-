# Graphics integration

The character, weapon and tank PNGs are design references. Their shapes and materials have been translated into animated procedural 3D geometry; they are not flat billboards replacing the actors. The generated projectile PNG is used directly as an atlas with eight cached regions in `scripts/combat/fx_atlas.gd`.

- `SoldierVisual`: textured cloth, helmet band, plate carrier, straps, magazine pouches, backpack, gloves and knee armor. Gear follows existing limb pivots.
- `WeaponVisual`: six held weapons with separate receivers, grips, stocks, magazines, muzzle assemblies, cooling fins, fuel bottles and laser emitters. Visual recoil leaves the collision-safe muzzle calculation intact.
- `ArmoredVisual`: independently built scout, heavy siege and stationary twin-gun sentry silhouettes. Heavy machinery includes engine vents, exhausts, hydraulic pistons, wiring and armor panels. Boss bulwark/mortar/reactor equipment still works. Designs are built on demand and retained for pooled reuse.
- `ModelFactory`: shared deterministic 32px cloth/metal surface maps, per-instance tint/fade materials and low-sided track wheels. Terrain remains simple.
- Combat: generated tracers, laser beams, rocket/shell artwork, flame jets and impact sparks; ballistic sprites face their velocity; rocket/shell smoke uses the existing effect pool. Plasma and shotgun-spread atlas regions are available in the gallery for future effects. Existing weapon damage and projectile collision rules are retained.
- Environment: contact shading, restrained glow and softer sun shadows in Forward+.

## Preview

Run `scenes/debug/graphics_gallery.tscn` in Godot for a fixed-lighting armory view. This shows actual runtime geometry and atlas regions. Add `-- --capture` when launching the scene to save `test-results/graphics-gallery.png` and exit. Add `-- --gameplay` to capture a staged mission view with the actual player, held weapon, tanks and HUD.

## Verification

`tests/graphics_regression.tscn` checks projectile and effect pool reuse, allegiance/atlas reset, heavy-to-scout reuse, boss attachment cleanup, and restored material opacity. Existing smoke, combat, aim, boss, scene and ram checks cover the surrounding integration. Stress regression checks bounded pool growth and saturation, not GPU frame rate. Use isolated saves when running tests, e.g. `-- --save-path=/tmp/iron-front-graphics-save.json`.
