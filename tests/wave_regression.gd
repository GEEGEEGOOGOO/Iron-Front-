extends Node
func _ready() -> void:
	call_deferred("run")
func run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	main.start_mission(0)
	await get_tree().create_timer(0.1).timeout
	var level = main.level
	var wave := WaveData.new()
	wave.trigger_x = 20
	level.player.position.x = 10
	assert(not level.can_start_wave(wave), "Position trigger must wait for player")
	level.player.position.x = 21
	assert(level.can_start_wave(wave), "Position trigger must activate at threshold")
	wave.trigger_condition = "level_start"
	assert(level.can_start_wave(wave), "Level-start wave must be eligible immediately")
	wave.trigger_condition = "timer"
	wave.trigger_delay = 10
	GameManager.elapsed = 9
	assert(not level.can_start_wave(wave), "Timer trigger must wait")
	GameManager.elapsed = 10
	assert(level.can_start_wave(wave), "Timer trigger must activate at deadline")
	wave.trigger_condition = "previous_cleared"
	wave.trigger_delay = 2
	assert(not level.can_start_wave(wave), "Chained wave must require a cleared wave")
	level.previous_wave_cleared_at = 9
	assert(not level.can_start_wave(wave), "Chained wave must respect delay")
	GameManager.elapsed = 11
	assert(level.can_start_wave(wave), "Chained wave must activate after clear delay")
	level.reset_encounter()
	assert(not level.can_start_wave(wave), "Reset must clear stale wave completion")
	level.wave_index = 1
	level.player.position.x = 41
	level._physics_process(1.0 / 60.0)
	assert(level.checkpoint_wave_index == 1, "Checkpoint must capture the currently pending wave")
	assert(GameManager.checkpoint.x == 40, "Checkpoint must record its world position")
	assert(level.checkpoint_labels.size() == level.data.checkpoint_positions.size(), "Every authored checkpoint must have a visible marker")
	assert(level.checkpoint_labels[1].text == "CHECKPOINT SECURED", "Activated checkpoint marker must change state")
	assert(level.checkpoint_labels[2].text == "CHECKPOINT", "Future checkpoint must remain inactive")
	level.checkpoint_wave_index = 2
	GameManager.elapsed = 20
	level.reset_encounter()
	assert(level.wave_index == 2, "Checkpoint must restore the wave reached when it was secured")
	assert(not level.can_start_wave(wave), "Chained wave must wait after checkpoint restart")
	GameManager.elapsed = 22
	assert(level.can_start_wave(wave), "Chained wave must resume after its delay")
	level.checkpoint_wave_index = 0
	level.data.waves[0].trigger_condition = "timer"
	level.data.waves[0].trigger_x = 1
	GameManager.checkpoint.x = 40
	level.reset_encounter()
	assert(level.wave_index == 0, "An unplayed timer wave must not be skipped by its X value")
	main.quit_to_menu()
	await get_tree().create_timer(0.15).timeout
	print("WAVE REGRESSION PASS")
	get_tree().quit()
