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
	for mission in 3:
		main.start_mission(mission)
		GameManager.god_mode = true
		var level = main.level
		level.wave_index = level.data.waves.size()
		var ladder = level.ladders[0]
		var player = GameManager.player
		player.position = ladder.position + Vector3(0, 0.1, 0)
		level.rig.position.x = ladder.position.x
		level.rig.frontier = ladder.position.x
		Input.action_press("aim_up")
		for i in 130:
			await get_tree().physics_frame
		Input.action_release("aim_up")
		check(player.state == player.State.CLIMB, "Player must enter climb state")
		check(player.position.y >= ladder.height - 0.15, "Player must reach ladder top")
		check(absf(player.position.z) < 0.001, "Climbing must preserve gameplay lane")
		check(level.rig.position.y > 0.4, "Camera must track the elevated route")
		var height: float = player.position.y
		for i in 5:
			await get_tree().physics_frame
		check(absf(player.position.y - height) < 0.1, "Released climb input must hold position")
		Input.action_press("move_right")
		for i in 18:
			await get_tree().physics_frame
		Input.action_release("move_right")
		check(player.ladder == null, "Horizontal dismount must release ladder")
		for i in 70:
			await get_tree().physics_frame
		check(player.is_on_floor() and player.position.y >= ladder.height - 0.15, "Dismount must reach raised platform")
		print("TRAVERSAL PASS ", mission + 1)
	main.quit_to_menu()
	await get_tree().create_timer(0.1).timeout
	print("TRAVERSAL REGRESSION ", "PASS" if failures == 0 else "FAIL")
	get_tree().quit(0 if failures == 0 else 1)
