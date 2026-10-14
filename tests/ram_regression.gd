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
	main.start_mission(0)
	GameManager.god_mode = true
	var tank = main.level.tank
	tank.set_physics_process(false)
	tank.position = Vector3(6, 0.1, 0)
	var enemy = main.level.spawn_enemy("heavy", Vector3(7.8, 0.1, 0))
	enemy.set_physics_process(false)
	await get_tree().create_timer(0.1).timeout
	tank.velocity.x = 4.8
	check(tank.try_ram() == 0, "Unoccupied tank must not ram")
	tank.enter_vehicle(GameManager.player)
	tank.velocity.x = 0
	check(tank.try_ram() == 0, "Stationary tank must not ram")
	tank.velocity.x = 4.8
	check(tank.try_ram() == 1, "Moving tank must hit forward enemy")
	check(enemy.health.current_health == 4, "Ram must deal four damage")
	check(tank.try_ram() == 0 and enemy.health.current_health == 4, "Ram cooldown must prevent repeat damage")
	tank.ram_cooldown = 0
	tank.velocity.x = -4.8
	check(tank.try_ram() == 0, "Reversing must not hit the previous forward target")
	tank.velocity.x = 4.8
	check(tank.try_ram() == 1 and enemy.health.current_health == 0, "A later ram may finish the target")
	var wall := StaticBody3D.new()
	main.level.add_child(wall)
	wall.position = tank.position + Vector3(1.8, 1.8, 0)
	ModelFactory.collider(wall, Vector3(0.2, 1, 2), Vector3.ZERO)
	await get_tree().create_timer(0.05).timeout
	check(tank.firing_origin().x < wall.position.x, "Tank cannon must start before cover inside barrel reach")
	wall.queue_free()
	await get_tree().create_timer(0.05).timeout
	check(is_equal_approx(tank.firing_origin().x, tank.position.x + 2.1), "Unobstructed tank cannon must use its muzzle")
	var obstacle = PoolManager.acquire("wreck")
	obstacle.activate(tank.position + Vector3(3.5, 0, 0))
	await get_tree().physics_frame
	check(tank.test_move(tank.global_transform, Vector3(2, 0, 0)), "Intact destructible wreck must block tank motion")
	PoolManager.release(obstacle)
	await get_tree().physics_frame
	check(not tank.test_move(tank.global_transform, Vector3(2, 0, 0)), "Recycled wreck must stop blocking tank motion")
	tank.position = Vector3(22, 0.1, 0)
	var hostile_tank = main.level.spawn_enemy("tank", tank.position + Vector3(3.8, 0, 0))
	hostile_tank.set_physics_process(false)
	await get_tree().create_timer(0.05).timeout
	check(tank.test_move(tank.global_transform, Vector3(2, 0, 0)), "Enemy tank hull must block player tank motion")
	check(hostile_tank.test_move(hostile_tank.global_transform, Vector3(-2, 0, 0)), "Player tank hull must block approaching enemy tanks")
	check(hostile_tank.body_shape.shape.size.x > 3, "Enemy tank movement collider must fit its hull")
	var player = GameManager.player
	tank.exit_vehicle()
	player.set_physics_process(false)
	main.level.rig.set_physics_process(false)
	hostile_tank.position = Vector3(50, 0.1, 0)
	player.position = hostile_tank.position + Vector3(-4, 0, 0)
	await get_tree().create_timer(0.05).timeout
	check(player.test_move(player.global_transform, Vector3(3, 0, 0)), "On-foot character must be blocked by enemy tank from the left")
	player.position = hostile_tank.position + Vector3(4, 0, 0)
	await get_tree().create_timer(0.05).timeout
	check(player.test_move(player.global_transform, Vector3(-3, 0, 0)), "On-foot character must be blocked by enemy tank from the right")
	player.position = tank.position + Vector3(-3, 0, 0)
	await get_tree().create_timer(0.05).timeout
	check(player.test_move(player.global_transform, Vector3(2, 0, 0)), "On-foot character must be blocked by the drivable tank")
	tank.enter_vehicle(player)
	check(player.vehicle == tank and not player.visible, "Vehicle entry must still work with solid tank hulls")
	player.set_physics_process(true)
	main.level.rig.set_physics_process(true)
	hostile_tank.position = tank.position + Vector3(3.2, 0, 0)
	await get_tree().create_timer(0.05).timeout
	tank.health.reset(18)
	tank.ram_cooldown = 0
	tank.velocity.x = 4.8
	check(tank.try_ram() == 1, "Tank impact must strike an enemy hull")
	check(hostile_tank.health.current_health == 16 and tank.health.current_health == 14, "Tank impact must deal four damage to both vehicles")
	check(tank.try_ram() == 0 and tank.health.current_health == 14, "Impact cooldown must prevent repeated armor damage")
	var boss_config: EnemyData = load("res://data/enemies/boss.tres")
	hostile_tank.activate(boss_config, tank.position + Vector3(4.5, 0, 0))
	hostile_tank.set_physics_process(false)
	tank.health.reset(18)
	tank.ram_cooldown = 0
	await get_tree().create_timer(0.05).timeout
	check(tank.try_ram() == 1 and tank.health.current_health == 14, "Ramming the tank boss must also damage player armor")
	tank.health.reset(4)
	tank.ram_cooldown = 0
	check(tank.try_ram() == 1 and tank.wrecked and tank.driver == null, "Fatal collision recoil must destroy the tank and eject its driver")
	PoolManager.release(hostile_tank)
	var reused_soldier = main.level.spawn_enemy("grunt", Vector3(20, 0, 0))
	reused_soldier.set_physics_process(false)
	check(reused_soldier == hostile_tank and reused_soldier.body_shape.shape.size.x < 1, "Pooled soldier must restore its smaller movement collider")
	PoolManager.release(reused_soldier)
	await get_tree().physics_frame
	check(not tank.test_move(tank.global_transform, Vector3(2, 0, 0)), "Recycled enemy tank must stop blocking movement")
	tank.destroy()
	check(tank.driver == null and GameManager.player.visible, "Destroyed tank must eject its driver")
	check(PoolManager.pools["wreck"].size() == 2, "Destroyed tank must borrow one wreck")
	tank.destroy()
	check(PoolManager.pools["wreck"].size() == 2, "Repeated destruction must not create another wreck")
	var wreck: Node
	for item in PoolManager.borrowed:
		if PoolManager.borrowed[item] == "wreck":
			wreck = item
	check(wreck != null, "Tank destruction must leave a wreck")
	if wreck:
		check(wreck.collision_layer == 256 and wreck.health.current_health == 6, "Wreck must block movement and have six health")
		wreck.take_damage(6)
		check(not PoolManager.borrowed.has(wreck) and wreck.collision_layer == 0, "Destroyed wreck must return to pool without collision")
		var reused = PoolManager.acquire("wreck")
		reused.activate(Vector3(12, 0, 0))
		check(reused.health.current_health == 6, "Reused wreck must restore health")
	main.quit_to_menu()
	await get_tree().create_timer(0.15).timeout
	check(PoolManager.pools["wreck"].size() == 3, "Menu must recycle all wrecks")
	print("RAM REGRESSION ", "PASS" if failures == 0 else "FAIL")
	get_tree().quit(0 if failures == 0 else 1)
