# Distinct mission environments

Operation Ashfall uses a modular military research facility: open laboratory
bays, instrument benches and monitors, server cabinets, rooftop HVAC equipment,
generators, fences, reinforced doors and communications dishes. Lighting is cool
overcast daylight. Mission objective: breach the research facility.

Dust Battalion retains its original scenery builder and lighting.

Midnight Foundry uses furnaces, exhaust stacks, crane gantries with suspended
ladles, coils, pipework, cabinets and steel platform dressing. Lighting is blue
night ambient with orange furnace lights. Geometry is modular, built in Godot;
the concept images remain visual references rather than background planes.

## Interaction

- Three side-alcove doors per new map at X=17, 52 and 91. Approach the terminal
  and press E to toggle the door. Collision switches with the door state.
- Existing mission ladders, elevators and platforms retain traversal collision.
- Existing supply crates remain destructible and drop weapons; barrels explode.
- Lab furnishings, generators, dishes, cranes, coils and pipes are decorative.
  Furnaces are lit scenery, not damaging hazards; cranes are not player-operated.

The combat lane and encounter coordinates were retained to preserve campaign
progression. These are environment rebuilds, not new encounter layouts. Door
alcoves sit behind the lane so they cannot trap the player or block a boss gate.

Verification is headless only, per user preference. Manual visual review remains
with the user: start missions 1 and 3, inspect lighting and platforms, and use E
near the door terminals. No game window was opened during implementation.
