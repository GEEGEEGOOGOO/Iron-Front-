# Dust Battalion rendering pass

The new art direction replaces the earlier voxel surfaces with chamfered planar meshes, smooth gradients, subtle inverted-hull ink outlines and actor rim lighting. ModelFactory caches ArrayMesh chamfers by size; collision boxes retain their original dimensions. Cloth and metal textures generate mipmaps and use linear mipmap filtering. Forward+ retains 4× MSAA and FXAA.

The DustBattalion root in each mission separates ForegroundClutter (Z +3 to +4.5), PlayableRoad, HeroCover, MidgroundUtilities (Z -2 to -4) and BackgroundCityscape (Z -11.5 and -24). The visual road extends beyond the camera's lower frustum; the existing gameplay lane remains at Z 0.

The environment uses ACES, amber sunset lighting, shadow blur 1.5, depth fog beginning at camera distance 27 (approximately behind world Z -6 with the default camera), glow intensity 0.8 and bloom 0.2. Procedural sky gradients, chimney smoke and GPU ash provide atmosphere. Streetlights combine a SpotLight3D with an additive transparent cone. This uses depth fog rather than globally filling the playable lane with volumetric fog.

Cover is dressed around authored platforms without moving their colliders: brick damage, sandbags, supply crates, stone arch frames, green emissive CRTs and green OmniLight3Ds. Nearby terminals show E / Y prompts; interaction requests a magazine reload from existing ammunition. Barrels now use 12-sided cylinders and reinforcing rings. Utilities include curved cables under Path3D nodes, rendered as slim chamfered segments rather than runtime CSG, barbed wire coils, ruined brick walls and lattice towers.

The soldier keeps its existing animation rig with softened armor, a rounded helmet, rim light and outlines. The HUD retains working switch/reload/dash controls with framed status modules. This is procedural game geometry, not an exact reproduction of the painted reference images.

Run scenes/debug/graphics_gallery.tscn with -- --gameplay --save-path=/tmp/dust-visual.json to save test-results/dust-battalion-gameplay.png. The capture stages the player on the first bunker and moves tanks aside; it does not change mission spawn positions.

Validation: smoke across three missions, scene determinism and layer checks, combat, movement/dash, input, graphics pool reuse and chamfer/material checks. GPU performance has not been benchmarked for the denser scene; these checks establish behavior and rendered appearance, not a frame-rate guarantee.

Godot environment property reference: https://docs.godotengine.org/en/stable/classes/class_environment.html

## Gameplay framing correction

Normal perspective framing now uses a 32-degree FOV at Z 20, camera Y 6.5 and a -9-degree pitch. This enlarges action approximately 1.6× relative to the earlier 42-degree FOV at Z 24. The road projects near 79% of screen height, replacing the large empty lower road area. Default orthographic size is 12.5. Boss fights smoothly widen FOV by 8 degrees (orthographic size by 3) and retain the existing intro effect. Projected view bounds constrain both the player and occupied vehicle so the tighter camera does not let them move out of frame. Camera regression checks road placement, player screen size, movement bounds and boss widening.

## Grounding the city

BackgroundTerrain now spans world Z -2 through -40, connecting the utility verge and both facade rows. Sixteen-metre chunks contain a one-metre triangulated grid with shallow deterministic height variation, generated normals and tangents. This is pre-subdivided terrain geometry, not runtime GPU tessellation. Facades sit on concrete plinths with sidewalk aprons. Rear pavement, service-road paint and scattered debris connect the ground visually to the buildings. A seamless generated mipmapped texture supplies broad weathering, fine aggregate and subtle normal relief; the foreground asphalt uses the same material system with a separate palette. Gameplay collision shapes and the corrected camera framing remain unchanged. Graphics regression checks terrain depth coverage, geometric relief, upward normals and texture assignment.

## Reference statistics HUD

The HUD now follows the supplied statistics layout: mission badge above the left weapon card; health, lives, magazine, reserve, grenades and score across the top; dash separately at bottom right. Native Godot drawing provides riveted frames, scratches, stat icons and segmented meters, with muted green/red/gold/cyan/orange accents. A 27% black wash sits behind the top HUD and a local wash supports dash. The battlefield itself is not darkened. Weapon card art uses isolated regions from the generated weapon sheet, fitted without stretching. SystemFont prefers Impact with platform fallbacks.

Transparent click targets preserve the existing controls: weapon card switches sidearm/special, magazine requests manual reload, and bottom-right dash activates the ability. Disabled states still respect ammo availability, full magazines, cooldowns, ladders, vehicles and game state; hover tooltips explain the action and keyboard/controller bindings. Automatic reload remains active. Graphics regression verifies these callbacks alongside input/scoring/mission checks.
