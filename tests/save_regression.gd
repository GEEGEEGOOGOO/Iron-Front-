extends Node
func _ready() -> void:
	var original: Dictionary = SaveManager.data.duplicate(true)
	var clean: Dictionary = SaveManager.sanitize({"volume": 9, "unlocked": 99, "arcade": "true", "high_scores": {"0": -5, "1": "bad", "2": 300}, "bindings": [], "bus_volumes": {"Music": -1, "SFX": "loud"}})
	assert(clean.volume == 1 and clean.unlocked == 3, "Numeric settings must be bounded")
	assert(clean.arcade == false, "Malformed difficulty must use default")
	assert(clean.high_scores["0"] == 0 and clean.high_scores["2"] == 300, "Scores must preserve valid entries")
	assert(not clean.high_scores.has("1"), "Malformed score must be discarded")
	assert(clean.bindings is Dictionary and clean.bindings.is_empty(), "Malformed mappings must reset safely")
	assert(clean.bus_volumes.Music == 0, "Bus volume must clamp")
	SaveManager.data = clean
	SaveManager.save()
	assert(FileAccess.file_exists(SaveManager.save_path), "Save must be written")
	assert(not FileAccess.file_exists(SaveManager.save_path + ".tmp"), "Successful save must replace the temporary file")
	SaveManager.data = {}
	SaveManager.load_save()
	assert(SaveManager.data.high_scores["2"] == 300, "Saved score must reload")
	var file := FileAccess.open(SaveManager.save_path, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	SaveManager.load_save()
	assert(SaveManager.data.high_scores["2"] == 300, "Malformed file must not replace valid in-memory data")
	SaveManager.data = original
	SaveManager.save()
	print("SAVE REGRESSION PASS")
	get_tree().quit()
