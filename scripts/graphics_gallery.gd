extends Node3D
# Run this scene to review every new design with fixed, repeatable lighting.
func caption(text: String, pos: Vector3, size := 26) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = pos
	label.font_size = size
	label.pixel_size = 0.012
	label.modulate = Color(0.72, 0.86, 0.87)
	add_child(label)
func _ready() -> void:
	if "--gameplay" in OS.get_cmdline_user_args():
		await capture_gameplay()
		return
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.035, 0.065, 0.08)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.65, 0.8, 0.85)
	env.ambient_light_energy = 0.65
	env.ssao_enabled = true
	env.ssao_radius = 0.6
	env.glow_enabled = true
	env.glow_intensity = 0.4
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, -30, 0)
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	add_child(sun)
	var camera := Camera3D.new()
	add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 13.5
	camera.position = Vector3(0, 7.5, 25)
	camera.look_at(Vector3(0, 5, 0))
	camera.current = true
	caption("IRON FRONT / VOXEL ARMORY", Vector3(0, 10.6, 0), 40)
	var kinds := ["pistol", "machine_gun", "shotgun", "rocket", "flame", "laser"]
	for i in kinds.size():
		var gun := Node3D.new()
		add_child(gun)
		gun.position = Vector3(-7.6 + (i % 3) * 6.5, 9.1 - (i / 3) * 2.0, 0)
		gun.scale = Vector3.ONE * 1.7
		WeaponVisual.build(gun, kinds[i])
		caption(kinds[i].replace("_", " ").to_upper(), gun.position + Vector3(0.8, -0.85, 0))
	var soldier := ModelFactory.soldier(self, Color(0.19, 0.43, 0.47))
	soldier.position = Vector3(-7.5, 1.0, 0)
	soldier.scale = Vector3.ONE * 1.55
	soldier.rotation.y = -0.25
	caption("INFANTRY", Vector3(-7.5, 0.45, 0))
	var scout := ModelFactory.armored_machine(self)
	scout.configure("scout", Color(0.38, 0.43, 0.27))
	scout.position = Vector3(-2.2, 1.0, 0)
	scout.rotation.y = -0.25
	caption("SCOUT / LIGHT ARMOR", Vector3(-2.5, 0.45, 0))
	var heavy := ModelFactory.armored_machine(self)
	heavy.configure("heavy", Color(0.38, 0.43, 0.27))
	heavy.position = Vector3(5.0, 0.85, 0)
	heavy.scale = Vector3.ONE * 1.35
	heavy.rotation.y = -0.25
	caption("SIEGE / HEAVY ARMOR", Vector3(5, 0.45, 0))
	for i in 8:
		var sprite := FxAtlas.sprite(self)
		FxAtlas.setup(sprite, i)
		sprite.position = Vector3(-8.6 + i * 2.45, 5.2, 0)
		sprite.scale *= Vector3(1.9, 0.55, 1)
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://test-results")
		get_viewport().get_texture().get_image().save_png("res://test-results/graphics-gallery.png")
		get_tree().quit()

func capture_gameplay() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	main.start_mission(0)
	GameManager.god_mode = true
	main.mission_card_time = 0
	main.level.wave_index = main.level.data.waves.size()
	for pickup in PoolManager.borrowed.keys():
		if PoolManager.borrowed[pickup] == "pickup":
			PoolManager.release(pickup)
	var player = GameManager.player
	player.position = Vector3(12.65, 1.4, 0)
	if "--ground" in OS.get_cmdline_user_args():
		player.position = Vector3(7, 0.1, 0)
	player.equip(load("res://data/weapons/pistol.tres"))
	main.level.rig.position.x = 12
	main.level.rig.frontier = 12
	main.level.tank.position = Vector3(27, 0.1, 0)
	var scout = main.level.spawn_enemy("tank", Vector3(31, 0.1, 0))
	scout.set_physics_process(false)
	await get_tree().create_timer(0.4).timeout
	main.level.banner_time = 0
	main._process(0)
	if "--dash" in OS.get_cmdline_user_args():
		player.position = Vector3(5, 2, 0)
		player.start_dash()
		await get_tree().create_timer(0.08).timeout
	Combat.fire(player, player.firing_origin(), Vector3.RIGHT, player.weapon, true)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-results")
	get_viewport().get_texture().get_image().save_png("res://test-results/dust-battalion-ground.png" if "--ground" in OS.get_cmdline_user_args() else "res://test-results/dust-battalion-gameplay.png")
	main.quit_to_menu()
	get_tree().quit()
