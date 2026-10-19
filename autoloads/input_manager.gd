extends Node
const DEFAULT_KEYS := {"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "aim_up": [KEY_W, KEY_UP], "crouch": [KEY_S, KEY_DOWN], "jump": [KEY_SPACE], "fire": [KEY_J], "fire_secondary": [KEY_K], "melee": [KEY_L], "interact": [KEY_E], "switch_weapon": [KEY_Q], "reload": [KEY_R], "dash": [KEY_SHIFT], "pause": [KEY_ESCAPE], "debug": [KEY_F3]}
const REBINDABLE := ["move_left", "move_right", "aim_up", "crouch", "jump", "fire", "fire_secondary", "melee", "interact", "switch_weapon", "reload", "dash", "pause"]
const WEAPON_KEYS := {"select_pistol": KEY_1, "select_shotgun": KEY_2, "select_flame": KEY_3}
func _ready() -> void:
	for action in WEAPON_KEYS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var key_event := InputEventKey.new()
		key_event.physical_keycode = WEAPON_KEYS[action]
		InputMap.action_add_event(action, key_event)

	for action in DEFAULT_KEYS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.22)
		for key in DEFAULT_KEYS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
	var buttons := {"jump": JOY_BUTTON_A, "fire": JOY_BUTTON_X, "fire_secondary": JOY_BUTTON_B, "interact": JOY_BUTTON_Y, "melee": JOY_BUTTON_RIGHT_SHOULDER, "switch_weapon": JOY_BUTTON_LEFT_SHOULDER, "reload": JOY_BUTTON_LEFT_STICK, "dash": JOY_BUTTON_RIGHT_STICK, "pause": JOY_BUTTON_START}
	for action in buttons:
		var event := InputEventJoypadButton.new()
		event.button_index = buttons[action]
		InputMap.action_add_event(action, event)
	for entry in [["move_left", JOY_AXIS_LEFT_X, -1.0], ["move_right", JOY_AXIS_LEFT_X, 1.0], ["aim_up", JOY_AXIS_LEFT_Y, -1.0], ["crouch", JOY_AXIS_LEFT_Y, 1.0]]:
		var event := InputEventJoypadMotion.new()
		event.axis = entry[1]
		event.axis_value = entry[2]
		InputMap.action_add_event(entry[0], event)

	apply_saved_bindings()

func apply_saved_bindings() -> void:
	var saved = SaveManager.data.get("bindings", {})
	if not saved is Dictionary:
		return
	for action in REBINDABLE:
		var key = saved.get(action, 0)
		if (key is int or key is float) and int(key) > 0:
			var previous := keyboard_key(action)
			for other in REBINDABLE:
				if other == action:
					continue
				var removed := false
				for event in InputMap.action_get_events(other):
					if event is InputEventKey and event.physical_keycode == int(key):
						InputMap.action_erase_event(other, event)
						removed = true
				if removed and keyboard_key(other) == 0 and previous > 0 and previous != int(key):
					set_keyboard_binding(other, previous)
			set_keyboard_binding(action, int(key))

func keyboard_key(action: String) -> int:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return event.physical_keycode
	return 0

func set_keyboard_binding(action: String, key: int) -> void:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			InputMap.action_erase_event(action, event)
	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action, event)

func rebind(action: String, key: int) -> String:
	if action not in REBINDABLE or key <= 0:
		return "Invalid control."
	if key in [KEY_F3, KEY_F4, KEY_F5, KEY_F6, KEY_F7]:
		return "F3–F7 are reserved for debug tools."
	if key in [KEY_1, KEY_2, KEY_3]:
		return "1–3 are reserved for the Blender weapon loadout."
	for other in REBINDABLE:
		if other == action:
			continue
		for event in InputMap.action_get_events(other):
			if event is InputEventKey and event.physical_keycode == key:
				return "%s is already assigned to %s." % [OS.get_keycode_string(key), other.replace("_", " ")]
	set_keyboard_binding(action, key)
	SaveManager.data.bindings[action] = key
	SaveManager.save()
	return ""

func reset_bindings() -> void:
	for action in REBINDABLE:
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				InputMap.action_erase_event(action, event)
		for key in DEFAULT_KEYS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
	SaveManager.data.bindings = {}
	SaveManager.save()

func key_label(action: String) -> String:
	var names := PackedStringArray()
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			names.append(OS.get_keycode_string(event.physical_keycode))
	return " / ".join(names)
