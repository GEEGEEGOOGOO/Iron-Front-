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
	await get_tree().create_timer(0.1).timeout
	var rig = main.level.rig
	rig.set_physics_process(false)
	var viewport_size: Vector2 = rig.camera.get_viewport().get_visible_rect().size
	var feet: Vector2 = rig.camera.unproject_position(Vector3(rig.position.x, 0, 0))
	var head: Vector2 = rig.camera.unproject_position(Vector3(rig.position.x, 1.9, 0))
	check(feet.y / viewport_size.y > 0.73 and feet.y / viewport_size.y < 0.85, "Road must sit near the lower fifth instead of leaving an empty lower third")
	check((feet.y - head.y) / viewport_size.y > 0.13, "Standing player must occupy a readable fraction of screen height")
	check(rig.half_width < 12, "Player movement bounds must tighten with the zoom")
	var config := LevelData.new()
	config.camera_bounds = Vector2(20, 40)
	config.camera_projection = "orthographic"
	rig.configure(config)
	check(rig.camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "Orthographic mode must apply")
	GameManager.player.position = Vector3(100, 20, 0)
	rig.lock_x = 100
	for i in 90:
		rig._physics_process(1.0 / 60.0)
	check(rig.position.x <= 40.001, "Boss locks must obey camera bounds")
	check(rig.position.y <= 6.001, "Vertical camera tracking must obey bounds")
	rig.start_boss_intro(2)
	rig._physics_process(1)
	check(rig.camera.size < config.camera_ortho_size, "Boss intro must change orthographic framing")
	rig._physics_process(1)
	check(is_equal_approx(rig.camera.size, config.camera_ortho_size), "Boss intro must restore framing")
	config.camera_projection = "perspective"
	rig.configure(config)
	check(rig.camera.projection == Camera3D.PROJECTION_PERSPECTIVE, "Perspective mode must apply")
	var boss = main.level.spawn_enemy("boss", Vector3(42, 0, 0))
	main.level.boss = boss
	for i in 90:
		rig._physics_process(1.0 / 60.0)
	check(rig.camera.fov > config.camera_fov, "Boss encounters must widen the tighter camera smoothly")
	main.quit_to_menu()
	await get_tree().create_timer(0.2).timeout
	print("CAMERA REGRESSION ", "PASS" if failures == 0 else "FAIL")
	get_tree().quit(0 if failures == 0 else 1)
