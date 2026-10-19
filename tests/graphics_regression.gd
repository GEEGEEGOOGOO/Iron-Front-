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
	var mat := ModelFactory.material(Color.WHITE)
	check(mat.rim_enabled and mat.next_pass != null, "Low-poly actor materials must include rim and outline passes")
	check(mat.texture_filter == BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS, "Actor materials must use smooth mipmapped filtering")
	var bevel := ModelFactory.beveled_mesh(Vector3(2, 1, 3))
	check(bevel.get_aabb().size.is_equal_approx(Vector3(2, 1, 3)), "Chamfers must retain authored mesh bounds")
	check(bevel == ModelFactory.beveled_mesh(Vector3(2, 1, 3)), "Identical chamfers must reuse their mesh")
	check(main.level.battlefield.get_node_or_null("HeroCover") != null, "Battlefield must include the cover layer")
	var terrain: Node3D = main.level.battlefield.get_node("BackgroundTerrain")
	var chunk := terrain.get_child(0) as MeshInstance3D
	check(chunk.mesh.get_aabb().size.z >= 38, "Background ground must bridge both building rows")
	check(chunk.mesh.get_aabb().size.y > 0.01, "Subdivided terrain must contain actual height relief")
	var arrays := chunk.mesh.surface_get_arrays(0)
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	check(normals[0].y > 0.9, "Background terrain must face upward and remain visible from gameplay")
	check(chunk.material_override.get_shader_parameter("surface_map") != null, "Terrain must have a filtered texture")
	var player = GameManager.player
	for kind in ["pistol", "machine_gun", "shotgun", "rocket", "flame", "laser"]:
		var data: WeaponData = load("res://data/weapons/" + kind + ".tres")
		player.equip(data)
		for other in player.gun_models:
			check(player.gun_models[other].visible == (kind == other), "Only the equipped weapon should be visible")
		check(is_equal_approx(player.muzzle.position.x, data.muzzle_distance), "Visual swap must retain the weapon muzzle offset")
	var actions: Control
	for child in main.screen.get_children():
		if child.get_script() and child.get_script().resource_path.ends_with("action_controls.gd"):
			actions = child
	check(actions != null, "Reference HUD must retain clickable action regions")
	actions.switch_button.pressed.emit()
	check(player.weapon.model_kind == "pistol", "Weapon card must switch to the sidearm")
	actions.switch_button.pressed.emit()
	check(player.weapon.model_kind == "laser", "Weapon card must restore the special weapon")
	player.magazines[player.weapon] = 1
	actions.reload_button.pressed.emit()
	check(player.reload_remaining > 0, "Magazine panel must request a reload")
	player.start_reload_cancel()
	actions.dash_button.pressed.emit()
	check(player.dash_remaining > 0, "Bottom-right dash panel must activate dash")
	player.dash_remaining = 0
	player.dash_recharge = 0
	var bullet = PoolManager.acquire("projectile")
	bullet.activate(player, Vector3(5, 5, 0), Vector3.RIGHT * 18, 1, true, 2, 3, false, "rocket")
	check(bullet.artwork.texture.region == FxAtlas.REGIONS[2], "Rocket must use generated rocket region")
	bullet.artwork.rotation.z = 2.0
	PoolManager.release(bullet)
	var reused = PoolManager.acquire("projectile")
	check(reused == bullet, "Test must reuse the same pooled projectile")
	reused.activate(player, Vector3(5, 5, 0), Vector3.LEFT * 30, 1, false, 1, 0, false)
	check(reused.visual_kind == "bullet" and reused.radius == 0 and not reused.ballistic, "Ordinary round must clear rocket state")
	check(reused.artwork.texture.region == FxAtlas.REGIONS[0], "Round must restore its own atlas region")
	check(reused.artwork.scale.x < 1 and reused.artwork.modulate.g < 0.5, "Reused enemy round must restore size and allegiance tint")
	PoolManager.release(reused)
	var effect = PoolManager.acquire("effect")
	effect.activate_art(Vector3.ZERO, Vector3.ONE, 5, 0.1, 1.0)
	PoolManager.release(effect)
	effect = PoolManager.acquire("effect")
	effect.activate(Vector3.ZERO, Vector3.ONE, Color.GRAY, 0.2)
	check(effect.model.visible and not effect.artwork.visible and effect.rotation == Vector3.ZERO, "Pooled beam must reset to a plain effect")
	PoolManager.release(effect)
	var enemy = main.level.spawn_enemy("boss", Vector3(50, 0, 0))
	check(enemy.machine_model.selected == "heavy", "Boss must use the heavy chassis")
	enemy.machine_model.get_node("reactor").show()
	enemy.set_model_alpha(enemy.machine_model, 0.2)
	PoolManager.release(enemy)
	var scout = main.level.spawn_enemy("tank", Vector3(50, 0, 0))
	check(scout == enemy, "Test must reuse the heavy enemy as a scout")
	check(scout.machine_model.selected == "scout" and not scout.machine_model.designs.heavy.visible, "Scout must hide the previous heavy chassis")
	check(not scout.machine_model.get_node("reactor").visible, "Scout must clear boss equipment")
	var mesh := scout.machine_model.designs.scout.get_child(0) as MeshInstance3D
	# Any built chassis mesh must have a fully restored material after recycling.
	if mesh:
		check(mesh.material_override.albedo_color.a == 1.0, "Pooled chassis must restore opacity")
	PoolManager.release(scout)
	main.quit_to_menu()
	main.queue_free()
	await get_tree().create_timer(0.15).timeout
	print("GRAPHICS REGRESSION ", "PASS" if failures == 0 else "FAIL")
	await get_tree().process_frame
	get_tree().quit(0 if failures == 0 else 1)
