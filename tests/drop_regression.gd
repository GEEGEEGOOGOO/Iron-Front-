extends Node
func _ready() -> void:
	call_deferred("run")
func run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	main.start_mission(0)
	await get_tree().create_timer(0.1).timeout
	var before: int = PoolManager.pools.pickup.size()
	var enemy = main.level.spawn_enemy("tank", Vector3(25, 0, 0))
	enemy.take_damage(999, GameManager.player)
	assert(PoolManager.pools.pickup.size() == before - 1, "Tank must drop a weapon")
	var score := GameManager.score
	enemy.die()
	assert(PoolManager.pools.pickup.size() == before - 1, "Repeated death must not duplicate drops")
	assert(GameManager.score == score, "Repeated death must not duplicate score")
	var found := false
	for item in PoolManager.borrowed:
		if PoolManager.borrowed[item] == "pickup" and item.position.x == 25:
			found = item.kind in ["rocket", "laser"]
	assert(found, "Tank drop must come from its configured table")
	main.quit_to_menu()
	await get_tree().create_timer(0.15).timeout
	print("DROP REGRESSION PASS")
	get_tree().quit()
