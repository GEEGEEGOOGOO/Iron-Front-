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
		check(is_instance_valid(entry.mission_card) and entry.mission_card.visible, "Mission must open with a title card")
		check(entry.mission_card.get_node("MissionNumber").text == "MISSION %02d" % (mission + 1), "Title card must show the mission number")
		check(entry.mission_card.get_node("MissionTitle").text == entry.level.data.mission_name.to_upper(), "Title card must show the authored mission name")
		check(entry.mission_card.get_node("MissionObjective").text == entry.level.data.subtitle, "Title card must show the authored objective")
		check(is_equal_approx(entry.level.tank.position.x, entry.level.data.tank_position.x), "Tank must use the mission X placement")
		check(entry.level.boss_prisoner.position == entry.level.data.commander_position, "Commander must use the mission placement")
		check(entry.level.data.supply_positions.size() == entry.level.data.supply_kinds.size(), "Supply positions and kinds must match")
		if mission != 1:
			var ground_detail_name := "CoastalWater" if mission == 0 else "FoundryChannel"
			var ground_detail := entry.level.get_node_or_null(ground_detail_name) as MeshInstance3D
			check(ground_detail != null, "Mission must build its visual ground strip")
			if ground_detail:
				check(ground_detail.position.y > 0 and ground_detail.position.z < -3.5, "Visual ground strip must sit above and behind the lane floor")
		entry.level.wave_index = entry.level.data.waves.size()
		entry.level.player.position.x = entry.level.data.boss_trigger_x + 0.1
		entry.level._physics_process(1.0 / 60.0)
		check(entry.level.boss_started, "Boss must trigger at the mission threshold")
		check(entry.level.boss.position == entry.level.data.boss_spawn_position, "Boss must use the mission spawn point")
		check(entry.level.rig.lock_x == entry.level.data.boss_arena_x, "Camera must lock to the mission boss arena")
		entry.mission_card_time = 0
		entry._process(0)
		check(not entry.mission_card.visible, "Mission card must clear after its timer")
		entry.quit_to_menu()
		remove_child(entry)
		entry.queue_free()
		await get_tree().process_frame
	print("SCENE REGRESSION ", "PASS" if failures == 0 else "FAIL")
	await get_tree().create_timer(0.15).timeout
	get_tree().quit(0 if failures == 0 else 1)
