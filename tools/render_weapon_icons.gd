extends SceneTree
func _initialize() -> void:
	call_deferred("render_icons")
func render_icons() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(320, 160)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.87, 1)
	env.ambient_light_energy = 0.8
	environment.environment = env
	viewport.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-30, -25, 0)
	light.light_energy = 2
	viewport.add_child(light)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	viewport.add_child(camera)
	camera.current = true
	for kind in ["pistol", "shotgun", "flame"]:
		var visual := BlenderWeapon.new()
		viewport.add_child(visual)
		visual.configure(kind)
		var center := Vector3(0.35 if kind == "pistol" else 0.12, -0.1, 0)
		camera.position = center + Vector3(0.5, 0.3, 5)
		camera.look_at(center)
		camera.size = 0.85 if kind == "pistol" else 1.3
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("res://assets/models/weapons/" + kind + "_icon.png")
		visual.queue_free()
		await process_frame
	quit()
