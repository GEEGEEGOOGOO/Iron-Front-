extends Node
var failures := 0
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _ready() -> void:
	call_deferred("run")
func run() -> void:
	seed(1701)
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	main.start_mission(0)
	GameManager.god_mode = true
	main.level.wave_index = main.level.data.waves.size()
	GameManager.player.position = Vector3(15, 0.1, 0)
	main.level.rig.position.x = 20
	main.level.rig.frontier = 20
	for i in 48:
		main.level.spawn_enemy("heavy", Vector3(18 + (i % 12) * 0.5, 1, 0))
	await get_tree().physics_frame
	var nodes := PoolManager.get_child_count()
	var peak_borrowed := PoolManager.borrowed.size()
	var physics_ms: Array[float] = []
	var denied := 0
	var warmup_ms: Array[float] = []
	for frame in 480:
		for i in 12:
			var bullet = PoolManager.acquire("projectile")
			if bullet:
				bullet.activate(GameManager.player, Vector3(25, 6 + i * 0.1, 0), Vector3(-12, 0, 0), 1, false, 1.5, 0, false)
			else:
				denied += 1
		if frame % 10 == 0:
			for i in 16:
				Combat.fragment(Vector3(20, 4, 0), Vector3.ONE * 0.15, Color.GRAY, Vector3(randf_range(-3, 3), 4, 0), 1.5)
		await get_tree().physics_frame
		var sample := Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000
		if frame < 120:
			warmup_ms.append(sample)
		else:
			physics_ms.append(sample)
		peak_borrowed = maxi(peak_borrowed, PoolManager.borrowed.size())
		check(PoolManager.get_child_count() == nodes, "Combat load must not grow the pool scene tree")
	physics_ms.sort()
	var report := {
		"mode": "headless; excludes GPU/rendering cost",
		"frames": physics_ms.size(),
		"warmup_frames": warmup_ms.size(),
		"warmup_monitor_max_ms": warmup_ms.max(),
		"sampling_note": "Godot physics monitor readings; repeated monitor values are not independent per-frame timings",
		"enemies": 48,
		"peak_borrowed": peak_borrowed,
		"pool_nodes": nodes,
		"projectile_requests_denied_at_capacity": denied,
		"physics_ms_median": physics_ms[physics_ms.size() / 2],
		"physics_ms_p95": physics_ms[int(physics_ms.size() * 0.95)]
	}
	DirAccess.make_dir_recursive_absolute("res://test-results")
	var file := FileAccess.open("res://test-results/stress_metrics.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print(JSON.stringify(report))
	check(denied > 0, "Test must exercise pool saturation")
	main.quit_to_menu()
	check(PoolManager.borrowed.is_empty(), "Leaving combat must return all pooled objects")
	await get_tree().create_timer(0.15).timeout
	print("STRESS REGRESSION ", "PASS" if failures == 0 else "FAIL")
	get_tree().quit(0 if failures == 0 else 1)
