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
	await get_tree().create_timer(0.1).timeout
	var enemy = main.level.spawn_enemy("boss", Vector3(20, 0, 0))
	enemy.weapon.speed = 50
	enemy.hurt_time = 5
	enemy.model.position.x = 0.4
	PoolManager.release(enemy)
	var recycled = main.level.spawn_enemy("grunt", Vector3(21, 0, 0))
	check(recycled == enemy, "Test must reuse the same actor")
	check(recycled.weapon.speed == 11 and recycled.hurt_time == 0, "Enemy reuse must restore combat defaults")
	check(recycled.model.position == Vector3.ZERO, "Enemy reuse must clear visual hit displacement")
	var effect = PoolManager.acquire("effect")
	effect.activate(Vector3.ZERO, Vector3.ONE, Color.WHITE, 1)
	effect.model.scale = Vector3.ONE * 0.1
	PoolManager.release(effect)
	var reused_effect = PoolManager.acquire("effect")
	reused_effect.activate(Vector3.ZERO, Vector3.ONE, Color.WHITE, 1)
	check(reused_effect.model.scale == Vector3.ONE, "Effect activation must restore full scale")
	Combat.fragment(Vector3(3, 2, 0), Vector3.ONE * 0.1, Color.WHITE, Vector3.UP, 3)
	main.level.rig.shake = 0.5
	main.level.rig.position.y = 5
	GameManager.hitstop_until = Time.get_ticks_msec() + 1000
	Engine.time_scale = 0.12
	main.level.reset_encounter()
	for key in PoolManager.borrowed.values():
		check(key not in ["enemy", "effect", "fragment", "projectile", "burst"], "Checkpoint must clear temporary combat objects")
	check(main.level.rig.shake == 0 and main.level.rig.position.y == 0, "Checkpoint must reset camera offsets")
	check(Engine.time_scale == 1, "Checkpoint must cancel hitstop")
	main.quit_to_menu()
	await get_tree().create_timer(0.15).timeout
	print("RESET REGRESSION ", "PASS" if failures == 0 else "FAIL")
	get_tree().quit(0 if failures == 0 else 1)
