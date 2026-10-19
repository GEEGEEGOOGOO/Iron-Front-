extends Node
var failures := 0
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _ready() -> void:
	call_deferred("run")
func run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	main.start_mission(0)
	GameManager.god_mode = true
	var player = GameManager.player
	player.set_physics_process(false)
	player.position = Vector3(20, 1, 0)
	for kind in ["pistol", "shotgun", "flame"]:
		var data: WeaponData = load("res://data/weapons/" + kind + ".tres")
		player.equip(data)
		var visual := player.gun_models[kind].get_node("BlenderWeapon") as BlenderWeapon
		check(visual != null and visual.get_meta("blender_asset").ends_with(kind + ".glb"), "Actual Blender asset must be equipped")
		check(visual.trigger != null, "Imported trigger must be animated")
		if kind != "flame":
			check(visual.action_part != null, "Pistol slide and shotgun pump must be present")
		var before: int = player.magazine_rounds()
		Input.action_press("fire")
		player.cooldown = 0
		player._physics_process(0.016)
		Input.action_release("fire")
		check(player.magazine_rounds() == before - 1, "Imported weapon must consume gameplay ammunition")
		if visual.action_part:
			# Advance the tween deterministically; wall-clock timers race under load.
			visual.action_tween.pause()
			visual.action_tween.custom_step(0.07 if kind == "pistol" else 0.20)
			check(visual.action_part.position.x < visual.action_home.x, "Firing must move the imported action")
			visual.action_tween.kill()
		if kind == "flame":
			check(visual.plume != null and visual.plume.amount <= 96, "Flame effect must have a bounded particle budget")
			check(visual.fuel_lights.size() == 8, "Flame must expose an on-model fuel gauge")
			visual.fire()
			check(visual.plume.emitting, "Firing must start the flame plume")
			visual._process(0.3)
			check(not visual.plume.emitting, "Release must stop new waves while existing particles fade")
		player.start_reload()
		check(player.reload_remaining > 0, "Existing reload behavior must remain available")
		player.start_reload_cancel()
	# Verify normal-campaign selection, not only pickup/debug equipping.
	player.select_loadout("shotgun")
	var shotgun_ammo: int = player.ammo
	var shotgun_magazine: int = player.magazine_rounds()
	Input.action_press("fire")
	player.cooldown = 0
	player._physics_process(0.016)
	Input.action_release("fire")
	player.select_loadout("pistol")
	player.select_loadout("flame")
	check(player.weapon.model_kind == "flame", "Campaign loadout must make the flamethrower selectable")
	player.select_loadout("shotgun")
	check(player.ammo == shotgun_ammo - 1 and player.magazine_rounds() == shotgun_magazine - 1, "Weapon selection must retain spent ammo and magazine state")
	check(InputMap.has_action("select_pistol") and InputMap.has_action("select_shotgun") and InputMap.has_action("select_flame"), "All three campaign weapon slots must have input actions")
	main.quit_to_menu()
	main.queue_free()
	await get_tree().create_timer(0.1).timeout
	print("BLENDER WEAPONS REGRESSION ", "PASS" if failures == 0 else "FAIL")
	get_tree().quit(0 if failures == 0 else 1)
