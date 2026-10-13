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
	main.quit_to_menu()
	await get_tree().create_timer(0.15).timeout
	print("RAM REGRESSION ", "PASS" if failures == 0 else "FAIL")
	get_tree().quit(0 if failures == 0 else 1)
