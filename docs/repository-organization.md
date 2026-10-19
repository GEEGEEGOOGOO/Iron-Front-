# Repository organization

## Game assets and authoring files

`assets/` contains files loaded by the game. Keep runtime PNGs alongside the
feature that uses them: menu artwork in `assets/ui/menu/`, weapon icons beside
their exports in `assets/models/weapons/`, and effect sheets in `assets/art/`.
Their paths are referenced by scripts and resources; move them only together
with those references.

`art-source/` contains editable artwork and production evidence. Its `.gdignore`
keeps these files out of Godot’s import scan and exported game. Blender is only
needed to edit or re-export models, not to run the game.

```text
art-source/
  weapons/
    pistol/
    shotgun/
    flamethrower/
    lmg/
      models/       # authored Blender projects
      backups/      # retained earlier versions and .blend1 snapshots
      previews/     # renders for visual review
      references/   # source reference images or models, where available
      scripts/      # LMG authoring utilities
```

Folders appear only where that weapon has corresponding files. The flamethrower
also has `cache/Flamethrower_FireCache_48/`, preserving the simulation cache’s
internal layout. Historical versions and existing cache data have been retained.
If a Blender scene still points at an old absolute render or simulation location,
select its new `previews/` or `cache/` location in Blender before rendering or baking.

## Export workflow

Edit the animated pistol, shotgun, or flamethrower source in its `models/` folder.
From the repository root, use:

```sh
blender -b -P tools/export_blender_weapons.py -- pistol
blender -b -P tools/export_blender_weapons.py -- shotgun
blender -b -P tools/export_blender_weapons.py -- flame
```

The exporter writes GLBs to `assets/models/weapons/`. See
[Blender weapon integration](blender-weapons.md) for animation and verification.
LMG scripts under `art-source/weapons/lmg/scripts/` are historical Blender
production utilities; they are separate from the gameplay export pipeline.

## Adding files

- Put game-ready assets under the appropriate feature in `assets/`.
- Put editable weapon models under `art-source/weapons/<weapon>/models/`.
- Put review PNGs under that weapon’s `previews/`, and references under `references/`.
- Keep design concepts under `docs/concepts/` and explain them in documentation.
- Write temporary screenshots and test logs to ignored `test-results/`.
- Keep generated `.godot/` imports and `builds/` out of Git.
- New Blender autosaves (`*.blend1`, `*.blend2`, etc.) are ignored; existing
  historical snapshots remain tracked in `backups/`.

The root is reserved for the README, Godot project configuration, and repository
configuration. Do not add loose model files, preview images, or simulation caches.

## Documentation index

- [Project README](../README.md): setup, controls, and automated checks.
- [Blender weapons](blender-weapons.md): editable models and runtime exports.
- [Manual playtest](manual-playtest.md): gameplay verification.
- [Progress](progress.md): implementation status and unfinished work.
- [Mission maps](mission-map-implementation.md): battlefield implementation notes.
- [Art direction](dust-battalion-art.md): visual implementation notes.
