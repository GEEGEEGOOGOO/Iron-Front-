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
	var previous_save: Dictionary = SaveManager.data.duplicate(true)
	for mission in 3:
		main.start_mission(mission)
		GameManager.god_mode = true
		var level = main.level
		await get_tree().physics_frame
		for wave_number in level.data.waves.size():
			var wave: WaveData = level.data.waves[wave_number]
			level.player.position.x = wave.trigger_x + 0.5
			level._physics_process(1.0 / 60.0)
			check(level.encounter, "Mission %d wave %d must start at its trigger" % [mission + 1, wave_number + 1])
			for frame in 480:
				for enemy in level.enemies:
					if enemy.active and enemy.state != enemy.State.DEAD:
						enemy.take_damage(999, level.player)
				await get_tree().physics_frame
				if level.wave_index > wave_number:
					break
			check(level.wave_index == wave_number + 1 and not level.encounter, "Mission %d wave %d must clear" % [mission + 1, wave_number + 1])
		level.player.position.x = level.data.boss_trigger_x + 0.5
		level._physics_process(1.0 / 60.0)
		check(level.boss_started and is_instance_valid(level.boss), "Mission %d boss must start after all waves" % (mission + 1))
		if is_instance_valid(level.boss):
			level.boss.take_damage(999, level.player)
		for frame in 450:
			await get_tree().physics_frame
			if GameManager.state == GameManager.State.COMPLETE:
				break
		check(GameManager.state == GameManager.State.COMPLETE, "Mission %d must reach its result" % (mission + 1))
		check(GameManager.rescued == 1 and level.boss_prisoner.rescued, "Mission %d must rescue the commander" % (mission + 1))
		print("CAMPAIGN FLOW MISSION ", mission + 1, " PASS")
	main.quit_to_menu()
	SaveManager.data = previous_save
	SaveManager.save()
	await get_tree().create_timer(0.15).timeout
	print("CAMPAIGN FLOW ", "PASS" if failures == 0 else "FAIL")
	get_tree().quit(0 if failures == 0 else 1)
