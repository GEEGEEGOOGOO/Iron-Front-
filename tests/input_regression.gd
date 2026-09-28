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
	var saved: Dictionary = SaveManager.data.duplicate(true)
	InputManager.reset_bindings()
	check(InputManager.rebind("fire", KEY_R).is_empty(), "An unused key must bind")
	var r := InputEventKey.new()
	r.physical_keycode = KEY_R
	r.pressed = true
	check(InputMap.event_is_action(r, "fire"), "New key must trigger fire")
	var controller := InputEventJoypadButton.new()
	controller.button_index = JOY_BUTTON_X
	controller.pressed = true
	check(InputMap.event_is_action(controller, "fire"), "Keyboard remap must preserve controller input")
	check(not InputManager.rebind("jump", KEY_R).is_empty(), "Duplicate bindings must be rejected")
	check(not InputManager.rebind("fire", KEY_F4).is_empty(), "Debug shortcuts must remain reserved")
	var on_disk = JSON.parse_string(FileAccess.get_file_as_string(SaveManager.save_path))
	check(int(on_disk.bindings.fire) == KEY_R, "Key binding must persist to disk")
	InputManager.set_keyboard_binding("fire", KEY_J)
	InputManager.apply_saved_bindings()
	check(InputMap.event_is_action(r, "fire"), "Saved bindings must restore input mapping")
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	main.start_mission(0)
	await get_tree().create_timer(0.1).timeout
	GameManager.state = GameManager.State.PAUSED
	get_tree().paused = true
	main.show_controls()
	main.pending_binding = "jump"
	var key := InputEventKey.new()
	key.physical_keycode = KEY_T
	key.pressed = true
	main._input(key)
	check(InputMap.event_is_action(key, "jump"), "Paused control capture must save key")
	check(get_tree().paused, "Rebinding must keep the mission paused")
	main.pending_binding = "jump"
	key.physical_keycode = KEY_ESCAPE
	main._input(key)
	check(main.pending_binding.is_empty(), "Escape must cancel capture")
	check(get_tree().paused, "Capture cancellation must not resume the mission")
	InputManager.reset_bindings()
	check(InputManager.key_label("fire") == "J", "Reset must restore defaults")
	check(InputMap.event_is_action(controller, "fire"), "Reset must preserve controller input")
	main.quit_to_menu()
	SaveManager.data = saved
	InputManager.apply_saved_bindings()
	SaveManager.save()
	await get_tree().create_timer(0.1).timeout
	print("INPUT REGRESSION ", "PASS" if failures == 0 else "FAIL")
	get_tree().quit(0 if failures == 0 else 1)
