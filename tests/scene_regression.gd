extends Node
var failures := 0
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _ready() -> void:
	call_deferred("run")
func run() -> void:
	for mission in 3:
		var entry = load("res://scenes/levels/mission_%d.tscn" % (mission + 1)).instantiate()
		add_child(entry)
		await get_tree().create_timer(0.15).timeout
		check(GameManager.state == GameManager.State.PLAYING, "Standalone scene must enter gameplay")
		check(GameManager.mission == mission, "Standalone scene must select the correct mission")
		check(entry.level.scene_file_path == entry.level.data.level_scene_path, "World must load the authored scene")
		check(is_instance_valid(GameManager.player), "Standalone scene must create the player")
		check(entry.hud != null, "Standalone scene must create the HUD")
		check(is_equal_approx(entry.level.tank.position.x, entry.level.data.tank_position.x), "Tank must use the mission X placement")
		check(entry.level.boss_prisoner.position == entry.level.data.commander_position, "Commander must use the mission placement")
		check(entry.level.data.supply_positions.size() == entry.level.data.supply_kinds.size(), "Supply positions and kinds must match")
		entry.level.wave_index = entry.level.data.waves.size()
		entry.level.player.position.x = entry.level.data.boss_trigger_x + 0.1
		entry.level._physics_process(1.0 / 60.0)
		check(entry.level.boss_started, "Boss must trigger at the mission threshold")
		check(entry.level.boss.position == entry.level.data.boss_spawn_position, "Boss must use the mission spawn point")
		check(entry.level.rig.lock_x == entry.level.data.boss_arena_x, "Camera must lock to the mission boss arena")
		entry.quit_to_menu()
		remove_child(entry)
		entry.queue_free()
		await get_tree().process_frame
	print("SCENE REGRESSION ", "PASS" if failures == 0 else "FAIL")
	await get_tree().create_timer(0.15).timeout
	get_tree().quit(0 if failures == 0 else 1)
