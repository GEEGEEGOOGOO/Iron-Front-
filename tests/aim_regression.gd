extends Node
var failures := 0
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
func stick(axis: int, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = axis
	event.axis_value = value
	Input.parse_input_event(event)
func neutral() -> void:
	for code in [KEY_A, KEY_D, KEY_W, KEY_S]:
		key(code, false)
	stick(JOY_AXIS_LEFT_X, 0)
	stick(JOY_AXIS_LEFT_Y, 0)
	Input.flush_buffered_events()
func settle(player: Node3D) -> void:
	Input.flush_buffered_events()
	player.position = Vector3(6, 5, 0)
	player.velocity = Vector3.ZERO
	for i in 3:
		await get_tree().physics_frame
func _ready() -> void:
	call_deferred("run")
func run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	main.start_mission(0)
	GameManager.god_mode = true
	var player = GameManager.player
	for direction in [Vector2.RIGHT, Vector2(1, 1), Vector2.UP, Vector2(-1, 1), Vector2.LEFT, Vector2(-1, -1), Vector2.DOWN, Vector2(1, -1)]:
		neutral()
		if direction.x != 0:
			key(KEY_D if direction.x > 0 else KEY_A, true)
		if direction.y != 0:
			key(KEY_W if direction.y > 0 else KEY_S, true)
		await settle(player)
		var keyboard_aim: Vector3 = player.aim
		var expected := Vector3(direction.x, direction.y, 0).normalized()
		check(keyboard_aim.is_equal_approx(expected), "Keyboard direction must match " + str(expected))
		neutral()
		stick(JOY_AXIS_LEFT_X, direction.x)
		stick(JOY_AXIS_LEFT_Y, -direction.y)
		await settle(player)
		check(player.aim.is_equal_approx(keyboard_aim), "Controller direction must match keyboard " + str(expected))
	neutral()
	stick(JOY_AXIS_LEFT_X, 0.1)
	stick(JOY_AXIS_LEFT_Y, -0.1)
	await settle(player)
	check(player.velocity.x == 0, "Small stick drift must not move the player")
	check(player.aim.y == 0, "Small stick drift must not alter vertical aim")
	neutral()
	main.quit_to_menu()
	await get_tree().create_timer(0.15).timeout
	print("AIM REGRESSION ", "PASS" if failures == 0 else "FAIL")
	get_tree().quit(0 if failures == 0 else 1)
