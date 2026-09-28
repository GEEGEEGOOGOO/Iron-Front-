extends Node
var main: Node
func _ready() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	call_deferred("run")
func run() -> void:
	for mission in 3:
		main.start_mission(mission)
		await get_tree().physics_frame
		for i in 90:
			await get_tree().physics_frame
		assert(GameManager.player.position.y > -0.1, "Player must stand on ground")
		assert(absf(GameManager.player.position.z) < 0.001, "Player must remain on lane")
		var level = main.level
		GameManager.player.position.x = 20
		for i in 200:
			await get_tree().physics_frame
		assert(level.encounter, "Encounter must trigger")
		assert(level.living_enemies() > 0, "Wave must spawn enemies")
		for enemy in level.enemies:
			enemy.take_damage(999, GameManager.player)
		await get_tree().physics_frame
		assert(not level.encounter, "Wave must clear")
		GameManager.player.equip(load("res://data/weapons/rocket.tres"))
		Combat.fire(GameManager.player, GameManager.player.position + Vector3(0, 1, 0), Vector3.RIGHT, GameManager.player.weapon, true)
		for i in 150:
			await get_tree().physics_frame
		var tank = level.tank
		tank.enter_vehicle(GameManager.player)
		assert(GameManager.player.vehicle == tank, "Tank must accept driver")
		tank.take_damage(100)
		assert(GameManager.player.vehicle == null, "Tank destruction must eject driver")
		assert(GameManager.player.health.invulnerability > 0, "Ejection must protect player")
		GameManager.player.health.invulnerability = 0
		GameManager.player.take_damage(100)
		assert(GameManager.lives == 2, "Death must consume exactly one life")
		for i in 110:
			await get_tree().physics_frame
		assert(GameManager.player.state != GameManager.player.State.DEAD, "Player must respawn")
		assert(GameManager.player.weapon.title == "Sidearm", "Respawn must reset weapon")
		print("PASS mission ", mission + 1)
	main.quit_to_menu()
	await get_tree().create_timer(0.15).timeout
	print("SMOKE PASS")
	get_tree().quit()
