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
	var old_save: Dictionary = SaveManager.data.duplicate(true)
	for mission in 3:
		main.start_mission(mission)
		GameManager.god_mode = true
		var level = main.level
		level.wave_index = level.data.waves.size()
		GameManager.player.position = Vector3(108, 0.1, 0)
		level.rig.position.x = 114
		level.rig.frontier = 114
		for i in 5:
			await get_tree().physics_frame
		var boss = level.boss
		check(is_instance_valid(boss), "Mission must spawn its boss")
		if not is_instance_valid(boss):
			continue
		check(boss.boss_data == level.data.boss_data, "Mission must select its boss resource")
		check(boss.intro_time > 0, "Boss must have an intro grace period")
		boss.set_physics_process(false)
		for phase_index in 3:
			boss.health.current_health = boss.health.max_health * [1.0, 0.5, 0.2][phase_index]
			for i in boss.boss_data.patterns.size():
				boss.current_pattern = boss.next_pattern()
				check(boss.phase == phase_index + 1, "Boss phase must follow health thresholds")
				check(boss.current_pattern.minimum_phase <= boss.phase, "Locked attack must not run early")
				boss.execute_pattern(GameManager.player)
				for item in PoolManager.borrowed.keys():
					if PoolManager.borrowed[item] == "projectile":
						check(item.velocity.z == 0, "Boss projectiles must remain on the lane")
						PoolManager.release(item)
		boss.set_physics_process(true)
		boss.take_damage(999, GameManager.player)
		if mission == 0:
			for i in 250:
				if level.boss_reward_given:
					break
				await get_tree().physics_frame
			check(level.boss_reward_given and GameManager.state == GameManager.State.PLAYING, "Commander must be rescued before mission results")
			var rescues_before := GameManager.rescued
			level.reset_encounter()
			level.wave_index = level.data.waves.size()
			GameManager.player.position.x = level.data.boss_trigger_x + 1
			level._physics_process(1.0 / 60.0)
			var replay_boss = level.boss
			check(is_instance_valid(replay_boss), "Checkpoint replay must respawn boss")
			if is_instance_valid(replay_boss):
				var score_before := GameManager.score
				replay_boss.take_damage(999, GameManager.player)
				for i in 250:
					if level.boss_reward_given:
						break
					await get_tree().physics_frame
				check(GameManager.rescued == rescues_before, "Checkpoint replay must not award the commander twice")
				check(GameManager.score == score_before + replay_boss.data.score_value, "Checkpoint replay must not repeat commander score")
		for i in 410:
			await get_tree().physics_frame
		check(GameManager.state == GameManager.State.COMPLETE, "Boss death must finish the mission")
		check(level.boss_reward_given and level.boss_prisoner.rescued, "Boss defeat must free the commander")
		check(GameManager.rescued == 1, "Boss rescue must award once")
		print("BOSS PASS ", mission + 1)
	main.quit_to_menu()
	SaveManager.data = old_save
	SaveManager.save()
	await get_tree().process_frame
	print("BOSS REGRESSION ", "PASS" if failures == 0 else "FAIL")
	get_tree().quit(0 if failures == 0 else 1)
