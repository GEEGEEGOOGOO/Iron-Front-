extends Node
var failures := 0
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("run")
func run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	main.start_mission(2)
	GameManager.god_mode = true
	var level = main.level
	level.wave_index = level.data.waves.size()
	var lift = level.elevators[0]
	var player = GameManager.player
	player.position = lift.position + Vector3(0, 0.2, 0)
	level.rig.position.x = lift.position.x
	level.rig.frontier = lift.position.x
	for i in 210:
		await get_tree().physics_frame
	check(player.position.y > 4.4, "Elevator must carry player upward")
	check(absf(player.position.z) < 0.001, "Riding must preserve lane")
	var y: float = lift.position.y
	GameManager.state = GameManager.State.PAUSED
	get_tree().paused = true
	for i in 10:
		await get_tree().process_frame
	check(is_equal_approx(lift.position.y, y), "Paused elevator must hold position")
	get_tree().paused = false
	GameManager.state = GameManager.State.PLAYING
	for i in 245:
		await get_tree().physics_frame
	check(lift.position.y < 0.3 and player.position.y < 0.7, "Elevator must carry player back down")
	main.quit_to_menu()
	await get_tree().create_timer(0.15).timeout
	print("ELEVATOR REGRESSION ", "PASS" if failures == 0 else "FAIL")
	get_tree().quit(0 if failures == 0 else 1)
