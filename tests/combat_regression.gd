extends Node
var main: Node
var failures := 0
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _ready() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	call_deferred("run")
func settle() -> void:
	for i in 3:
		await get_tree().physics_frame
func run() -> void:
	main.start_mission(0)
	GameManager.god_mode = true
	await settle()
	var player = GameManager.player
	player.position = Vector3(5, 0.1, 0)
	var front = main.level.spawn_enemy("heavy", Vector3(6.4, 0.1, 0))
	var rear = main.level.spawn_enemy("heavy", Vector3(3.6, 0.1, 0))
	front.set_physics_process(false)
	rear.set_physics_process(false)
	await settle()
	var before: float = rear.health.current_health
	var struck := Combat.melee(player, Vector3(5, 1.25, 0), 1)
	check(struck == 1, "Knife must only strike the forward target")
	check(rear.health.current_health == before, "Knife must not damage behind the player")
	check(front.health.current_health == 4, "Knife must apply four damage once")
	front.health.reset(8)
	var flame: WeaponData = load("res://data/weapons/flame.tres")
	Combat.fire(player, Vector3(5, 1.25, 0), Vector3.RIGHT, flame, true)
	check(front.health.current_health < 8, "Flame cone must deal damage immediately")
	check(rear.health.current_health == before, "Flame must not damage behind the muzzle")
	var wall := StaticBody3D.new()
	main.level.add_child(wall)
	wall.position = Vector3(5.8, 1.2, 0)
	ModelFactory.collider(wall, Vector3(0.2, 2.4, 2), Vector3.ZERO)
	await settle()
	before = front.health.current_health
	Combat.fire(player, Vector3(5, 1.25, 0), Vector3.RIGHT, flame, true)
	check(is_equal_approx(front.health.current_health, before), "World cover must block flame damage")
	player.equip(load("res://data/weapons/laser.tres"))
	player.gun.rotation.z = 0
	player.aim = Vector3.RIGHT
	var clipped_origin: Vector3 = player.firing_origin()
	check(clipped_origin.x < wall.position.x, "Long muzzle must stop before nearby cover")
	Combat.fire(player, clipped_origin, Vector3.RIGHT, player.weapon, true)
	check(is_equal_approx(front.health.current_health, before), "Long weapon must not fire through nearby cover")
	wall.queue_free()
	await settle()
	PoolManager.release(front)
	PoolManager.release(rear)
	var first = main.level.spawn_enemy("heavy", Vector3(6, 0.1, 0))
	var second = main.level.spawn_enemy("heavy", Vector3(8, 0.1, 0))
	first.set_physics_process(false)
	second.set_physics_process(false)
	await settle()
	GameManager.shots = 0
	GameManager.hits = 0
	var laser: WeaponData = load("res://data/weapons/laser.tres")
	Combat.fire(player, Vector3(5, 1.1, 0), Vector3.RIGHT, laser, true)
	check(first.health.current_health < 8 and second.health.current_health < 8, "Laser must pierce both targets")
	check(GameManager.hits == 1 and GameManager.shots == 1, "Piercing accuracy must count shots, not victims")
	first.health.reset(8)
	second.health.reset(8)
	GameManager.hits = 0
	Combat.explode(player, Vector3(7, 1, 0), 3, 4, true, true)
	check(first.health.current_health < 8 and second.health.current_health < 8, "Blast must damage both targets")
	check(GameManager.hits == 1, "Explosive accuracy must count one hit for a multi-target blast")
	GameManager.shots = 0
	Combat.grenade(player, Vector3(5, 1, 0), 1, true)
	check(GameManager.shots == 1, "Thrown grenade must count as a shot")
	var ceiling := StaticBody3D.new()
	main.level.add_child(ceiling)
	ceiling.position = player.position + Vector3(0, 1.5, 0)
	ModelFactory.collider(ceiling, Vector3(2, 0.3, 2), Vector3.ZERO)
	await settle()
	check(not player.can_stand(), "Low ceiling must prevent standing")
	player.equip(laser)
	player.aim = Vector3.UP
	player.gun.rotation.z = PI / 2
	check(player.firing_origin().y < ceiling.position.y - 0.15, "Upward muzzle must stop below a low ceiling")
	ceiling.queue_free()
	await settle()
	check(player.can_stand(), "Standing must be permitted after clearing the ceiling")
	player.position.x = first.position.x + 3
	check(first.firing_origin(player).x > first.position.x, "Enemy muzzle must face a target on the right")
	var enemy_cover := StaticBody3D.new()
	main.level.add_child(enemy_cover)
	enemy_cover.position = first.position + Vector3(0.4, 1.25, 0)
	ModelFactory.collider(enemy_cover, Vector3(0.1, 2, 2), Vector3.ZERO)
	await settle()
	check(first.firing_origin(player).x < enemy_cover.position.x - 0.05, "Enemy muzzle must stop before close cover")
	enemy_cover.queue_free()
	player.position.x = first.position.x - 3
	await settle()
	check(first.firing_origin(player).x < first.position.x, "Enemy muzzle must face a target on the left")
	player.position.x = 5
	player.aim = Vector3.LEFT
	player.gun.rotation.z = PI
	var left_wall := StaticBody3D.new()
	main.level.add_child(left_wall)
	left_wall.position = player.position + Vector3(-0.8, 1.25, 0)
	ModelFactory.collider(left_wall, Vector3(0.2, 2, 2), Vector3.ZERO)
	await settle()
	player.aim = Vector3.LEFT
	player.gun.rotation.z = PI
	check(player.firing_origin().x > left_wall.position.x + 0.1, "Leftward muzzle must stop on the player's side of cover")
	left_wall.queue_free()
	var component := HealthComponent.new()
	add_child(component)
	component.reset(3)
	check(not component.take_damage(0), "Cosmetic explosions must not register zero damage")
	var configured: EnemyData = load("res://data/enemies/rusher.tres").duplicate()
	configured.damage = 2.5
	first.activate(configured, player.position + Vector3.RIGHT)
	first.set_physics_process(false)
	GameManager.god_mode = false
	player.health.reset(3)
	first.attack(player)
	check(is_equal_approx(player.health.current_health, 0.5), "Rusher must apply authored melee damage")
	GameManager.god_mode = true
	for behavior in ["grunt", "grenadier", "tank"]:
		for item in PoolManager.borrowed.keys():
			if PoolManager.borrowed[item] == "projectile":
				PoolManager.release(item)
		configured.behavior = behavior
		first.activate(configured, player.position + Vector3.RIGHT * 3)
		first.set_physics_process(false)
		first.attack(player)
		var found_payload := false
		for item in PoolManager.borrowed.keys():
			if PoolManager.borrowed[item] == "projectile" and item.source == first:
				found_payload = true
				check(is_equal_approx(item.power, 2.5), behavior + " projectile must carry authored damage")
		check(found_payload, behavior + " attack must emit a projectile")
	main.quit_to_menu()
	await get_tree().create_timer(0.15).timeout
	print("COMBAT REGRESSION ", "PASS" if failures == 0 else "FAIL: %d" % failures)
	get_tree().quit(0 if failures == 0 else 1)
