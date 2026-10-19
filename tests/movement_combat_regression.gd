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
	main.level.wave_index = main.level.data.waves.size()
	var player = GameManager.player
	player.set_physics_process(false)
	main.level.rig.set_physics_process(false)
	player.position = Vector3(20, 0.1, 0)
	var gun: WeaponData = load("res://data/weapons/machine_gun.tres")
	player.equip(gun)
	player.magazines[gun] = 2
	Input.action_press("fire")
	player._physics_process(0.016)
	Input.action_release("fire")
	var total: int = player.ammo
	check(player.magazine_rounds() == 1, "Firing must consume one magazine round")
	player.start_reload()
	Input.action_press("fire")
	player.cooldown = 0
	player._physics_process(0.2)
	Input.action_release("fire")
	check(player.ammo == total and player.magazine_rounds() == 1, "Reloading must block firing without consuming reserve ammo")
	player._physics_process(gun.reload_duration)
	check(player.ammo == total and player.magazine_rounds() == gun.magazine_size, "Reload must refill magazine without creating total ammunition")
	player.magazines[gun] = 0
	Input.action_press("fire")
	player._physics_process(0.016)
	Input.action_release("fire")
	check(player.reload_remaining > 0 and player.ammo == total, "Empty magazine must trigger automatic reload")
	player.switch_weapon()
	check(player.reload_remaining == 0, "Weapon switching must cancel reload")
	player.switch_weapon()
	check(player.magazine_rounds() == 0, "Weapon switching must not bypass reload")
	player.model.pose(0.2, 0, 1, false, false, 0, true)
	check(player.model.knees[0].rotation.z > 1 and player.model.upper.position.y < 0.7, "Crouch must bend knees and lower the torso")
	check(player.model.scale == Vector3.ONE, "Crouch must retain character proportions")
	player.model.pose(0.2, 0, 1, true, false, 0, false, 9)
	var rising: float = player.model.knees[0].rotation.z
	player.model.pose(0.2, 0, 1, true, false, 0, false, -5)
	check(player.model.knees[0].rotation.z < rising, "Falling pose must extend knees from rising tuck")
	player.model.reset_pose()
	player.position = Vector3(20, 0.1, 0)
	var wall := StaticBody3D.new()
	main.level.add_child(wall)
	wall.position = Vector3(21, 1.5, 0)
	ModelFactory.collider(wall, Vector3(0.2, 3, 2), Vector3.ZERO)
	await get_tree().create_timer(0.05).timeout
	Input.action_press("dash")
	player._physics_process(0.1)
	Input.action_release("dash")
	check(player.dash_recharge > 0, "Dash must spend its rechargeable charge")
	check(player.position.x < 20.7, "Dash must respect world collision")
	player._physics_process(player.DASH_RECHARGE)
	check(player.dash_recharge == 0, "Dash must recharge over time")
	player.position = Vector3(20, 5, 0)
	player.velocity = Vector3(0, -8, 0)
	player.start_dash()
	var start_x: float = player.position.x
	player._physics_process(0.05)
	check(player.position.x > start_x and player.velocity.x > 12, "Air dash must move faster than running")
	check(player.velocity.y == 0, "Air dash must suspend falling during the burst")
	var charge: float = player.dash_recharge
	player.start_dash()
	check(player.dash_recharge == charge, "Cooldown must block repeated dash activation")
	player.model.pose(0.1, 20, 1, true, false, 0, false, 0, -1, true)
	check(player.model.upper.rotation.z < -0.4, "Dash must lean the torso into the air stream")
	main.quit_to_menu()
	main.queue_free()
	await get_tree().create_timer(0.1).timeout
	print("MOVEMENT COMBAT REGRESSION ", "PASS" if failures == 0 else "FAIL")
	get_tree().quit(0 if failures == 0 else 1)
