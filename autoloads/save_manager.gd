extends Node
var save_path := "user://save.json"
var data: Dictionary = {"high_scores": {}, "unlocked": 1, "volume": 0.7, "arcade": false, "bindings": {}}
func _ready() -> void:
	if OS.is_debug_build():
		for argument in OS.get_cmdline_user_args():
			if argument.begins_with("--save-path="):
				save_path = argument.trim_prefix("--save-path=")
	load_save()
func load_save() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(save_path)) == OK and parser.data is Dictionary:
		data = sanitize(parser.data)
func sanitize(source: Dictionary) -> Dictionary:
	var clean := {"high_scores": {}, "unlocked": 1, "volume": 0.7, "arcade": false, "bindings": {}, "bus_volumes": {}}
	if numeric(source.get("volume")):
		clean.volume = clampf(float(source.volume), 0, 1)
	if numeric(source.get("unlocked")):
		clean.unlocked = clampi(int(source.unlocked), 1, 3)
	if source.get("arcade") is bool:
		clean.arcade = source.arcade
	if source.get("high_scores") is Dictionary:
		for key in source.high_scores:
			if str(key) in ["0", "1", "2"] and numeric(source.high_scores[key]):
				clean.high_scores[str(key)] = maxi(0, int(source.high_scores[key]))
	if source.get("bus_volumes") is Dictionary:
		for bus in ["Music", "SFX", "UI", "Voice"]:
			if numeric(source.bus_volumes.get(bus)):
				clean.bus_volumes[bus] = clampf(float(source.bus_volumes[bus]), 0, 1)
	if source.get("bindings") is Dictionary:
		for action in source.bindings:
			if action is String and numeric(source.bindings[action]):
				var code := int(source.bindings[action])
				if code > 0 and code < 33554432:
					clean.bindings[action] = code
	return clean
func numeric(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))
func save() -> void:
	var temporary := save_path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if not file:
		push_warning("Unable to write save: " + str(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		push_warning("Unable to finish save: " + str(error))
		return
	error = DirAccess.rename_absolute(temporary, save_path)
	if error != OK:
		push_warning("Unable to replace save: " + str(error))
func record(mission: int, score: int) -> void:
	var key := str(mission)
	data.high_scores[key] = maxi(int(data.high_scores.get(key, 0)), score)
	data.unlocked = mini(3, maxi(int(data.unlocked), mission + 2))
	save()
