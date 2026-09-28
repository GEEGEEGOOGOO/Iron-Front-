extends Node
var failures := 0
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("run")
func run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	main.start_mission(0)
	await get_tree().create_timer(0.1).timeout
	var player = GameManager.player
	var bullet = PoolManager.acquire("projectile")
	bullet.activate(player, Vector3(5, 5, 0), Vector3.RIGHT * 10, 1, true, 2, 0, false)
	GameManager.state = GameManager.State.PAUSED
	get_tree().paused = true
	main.show_pause()
	var before: Vector3 = bullet.position
	var elapsed := GameManager.elapsed
	await get_tree().create_timer(0.1, true).timeout
	check(bullet.position == before, "Pause must freeze pooled projectiles")
	check(GameManager.elapsed == elapsed, "Pause must freeze mission clock")
	main.restart_checkpoint()
	check(GameManager.state == GameManager.State.PLAYING and not get_tree().paused, "Normal checkpoint restart must resume gameplay")
	GameManager.lives = 0
	player.state = player.State.DEAD
	GameManager.state = GameManager.State.PAUSED
	get_tree().paused = true
	main.restart_checkpoint()
	check(GameManager.state == GameManager.State.GAME_OVER, "Restart with zero lives must preserve game over")
	check(not get_tree().paused, "Game over menu must remain interactive")
	main.quit_to_menu()
	await get_tree().create_timer(0.15).timeout
	print("PAUSE REGRESSION ", "PASS" if failures == 0 else "FAIL")
	get_tree().quit(0 if failures == 0 else 1)
