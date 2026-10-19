extends Node
## Asset production only: renders the real map and real character, not a menu test.
func _ready() -> void:
	call_deferred("render_assets")

func render_assets() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/ui/menu")
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_4X
	add_child(viewport)
	var main = load("res://scenes/main.tscn").instantiate()
	viewport.add_child(main)
	main.start_mission(1)
	main.ui.hide()
	main.level.set_physics_process(false)
	main.level.rig.set_physics_process(false)
	main.level.player.set_physics_process(false)
	main.level.player.hide()
	main.level.rig.position = Vector3(22, 0, 0)
	GameManager.state = GameManager.State.MENU
	for i in 6:
		await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://assets/ui/menu/dust_battalion_map.png")
	main.quit_to_menu()
	main.queue_free()
	await get_tree().process_frame
	viewport.size = Vector2i(1024, 1024)
	viewport.transparent_bg = true
	var world := Node3D.new()
	viewport.add_child(world)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.65, 0.72, 0.77)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.environment = env
	world.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-24, -35, 0)
	light.light_color = Color(1, 0.67, 0.34)
	light.light_energy = 2.3
	world.add_child(light)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-15, 125, 0)
	fill.light_color = Color(0.48, 0.65, 0.8)
	fill.light_energy = 0.5
	world.add_child(fill)
	var soldier := ModelFactory.soldier(world, Color(0.19, 0.43, 0.47))
	ModelFactory.box(soldier.upper, Vector3(0.58, 0.12, 0.55), Vector3(0, 0.70, 0), Color(0.9, 0.3, 0.12))
	soldier.pose(1, 0, 1, false, false, -0.45)
	var gun := Node3D.new()
	world.add_child(gun)
	gun.position = Vector3(0.05, 1.24, 0.12)
	gun.rotation.z = -0.45
	WeaponVisual.build(gun, "shotgun")
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.1
	camera.position = Vector3(3.0, 1.9, 5.0)
	camera.look_at(Vector3(0.2, 1.10, 0))
	camera.current = true
	for i in 6:
		await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://assets/ui/menu/player_character.png")
	world.queue_free()
	viewport.queue_free()
	await get_tree().process_frame
	print("MENU_ASSETS_RENDERED: actual Dust Battalion map and SoldierVisual character")
	get_tree().quit()
