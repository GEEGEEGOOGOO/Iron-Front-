# Campaign menu assets

- `dust_battalion_map.png`: captured from the actual mission 2 level using `tools/render_menu_assets.tscn`, with HUD/player hidden. Not generated concept artwork.
- `player_character.png`: transparent render of the actual `SoldierVisual` game character, including the player headband and imported shotgun.
- `map_placeholder.svg`: neutral placeholder for unfinished Operation Ashfall and Midnight Foundry previews. Replace only when actual map captures are available.
- `campaign_background.png`: AI-edited backdrop from the user's approved arcade campaign mockup. Editing brief: preserve the orange sunset, ruined-city silhouette, foreground rubble and framing; remove all title text, mission cards, buttons, interface elements and the concept soldier. The actual game character is composited separately by the menu.

Background source: `exec-ed313190-6b4c-4fe1-a7ab-685e55152dec.png` supplied by the user. Edited output: `exec-88e00308-f0e8-444f-840f-9b886b2610ed.png` in this chat's generated images folder.

The composition lives in `scripts/ui/campaign_menu.gd`. `tests/campaign_menu_check.tscn` checks structure, thumbnail provenance, selection/deploy signals and viewport scaling headlessly, without starting a mission. Asset rendering is a separate production step, not visual game verification.
