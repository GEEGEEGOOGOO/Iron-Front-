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
	SaveManager.data.bindings = {"fire": KEY_Q}
	InputManager.apply_saved_bindings()
	check(InputManager.key_label("fire") == "Q" and InputManager.key_label("switch_weapon") == "J", "Legacy Q fire binding must move switch to the free key")
	InputManager.reset_bindings()
	check(InputManager.rebind("switch_weapon", KEY_U).is_empty(), "Switch action must be rebindable")
	var switch_key := InputEventKey.new()
	switch_key.physical_keycode = KEY_U
	switch_key.pressed = true
	InputManager.set_keyboard_binding("switch_weapon", KEY_Q)
	InputManager.apply_saved_bindings()
	check(InputMap.event_is_action(switch_key, "switch_weapon"), "Saved switch binding must reload")
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
	var shoulder := InputEventJoypadButton.new()
	shoulder.button_index = JOY_BUTTON_LEFT_SHOULDER
	shoulder.pressed = true
	check(InputMap.event_is_action(shoulder, "switch_weapon"), "Controller must map weapon switching")
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
	var player = GameManager.player
	var special: WeaponData = load("res://data/weapons/machine_gun.tres")
	player.equip(special)
	check(player.weapon == special and player.reserve_ammo == special.starting_ammo, "Pickup must equip and store special ammo")
	player.ammo = 37
	player.reserve_ammo = 37
	player.switch_weapon()
	check(player.weapon.title == "Sidearm" and player.ammo == -1, "Switch must select the unlimited sidearm")
	player.switch_weapon()
	check(player.weapon == special and player.ammo == 37, "Switch must restore stored special ammo")
	player.equip(special)
	check(player.ammo == special.max_ammo, "Same special pickup must refill stored ammo")
	player.ammo = 1
	player.reserve_ammo = 1
	player.cooldown = 0
	Input.action_press("fire")
	for i in 3:
		await get_tree().physics_frame
	Input.action_release("fire")
	check(player.weapon.title == "Sidearm" and player.reserve_weapon == null, "Empty special must fall back to sidearm")
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
