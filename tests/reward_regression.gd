extends Node
var failures := 0
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _ready() -> void:
	call_deferred("run")
func run() -> void:
	var table: RewardTable = load("res://data/rewards/pow.tres")
	check(table.choose(0) == "health", "First interval must select health")
	check(table.choose(0.99999) == "life", "Last interval must select an extra life")
	var empty := RewardTable.new()
	empty.weights = PackedFloat32Array([0, 0, 0, 0, 0, 0])
	check(empty.choose(0.5) == "score", "Empty weights must fall back safely")
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	main.start_mission(0)
	GameManager.god_mode = true
	await get_tree().create_timer(0.1).timeout
	var level = main.level
	var player = GameManager.player
	var caged = level.pows[1]
	check(caged.locked, "POW must begin inside a locked cage")
	caged.cage.take_damage(3, player)
	check(not caged.locked and caged.cage.opened, "Weapon damage must break the cage")
	check(GameManager.rescued == 0, "Breaking a cage alone must not grant a remote rescue")
	check(caged.cage.collision_layer == 0, "Broken cage must stop blocking movement")
	var prisoner = level.pows[0]
	player.position = prisoner.position
	level.interact(player, true)
	check(GameManager.rescued == 1 and prisoner.rescued, "Rescue must count once")
	var score := GameManager.score
	level.interact(player, true)
	check(GameManager.rescued == 1 and GameManager.score == score, "Repeated interaction must not duplicate rewards")
	var old_x: float = prisoner.position.x
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(prisoner.position.x < old_x, "Freed POW must run toward safety")
	var lives := GameManager.lives
	level.grant_pow_reward("life", Vector3.ZERO)
	check(GameManager.lives == lives + 1, "Life reward must grant one life")
	score = GameManager.score
	level.grant_pow_reward("score", Vector3.ZERO)
	check(GameManager.score == score + table.score_bonus, "Score reward must use configured amount")
	var node_count := PoolManager.get_child_count()
	var pickup = PoolManager.acquire("pickup")
	pickup.setup(Vector3(5, 1, 0), "grenades")
	var grenades: int = player.grenades
	pickup.collect(player)
	pickup.collect(player)
	check(player.grenades == grenades + 5, "Pickup must collect only once")
	await get_tree().process_frame
	await get_tree().process_frame
	check(not PoolManager.borrowed.has(pickup), "Collected pickup must return to pool")
	var reused = PoolManager.acquire("pickup")
	reused.setup(Vector3(6, 1, 0), "rocket")
	check(reused.visible and reused.kind == "rocket", "Reused pickup must reset state")
	check(reused.model.material_override.albedo_color == reused.COLORS.rocket and reused.model.scale == reused.SCALES.rocket, "Rocket pickup must show its configured cue")
	reused.setup(Vector3(6, 1, 0), "health")
	check(reused.model.material_override.albedo_color == reused.COLORS.health and reused.model.scale == reused.SCALES.health, "Pooled pickup must change color and shape for the new reward")
	check(PoolManager.get_child_count() == node_count, "Reward drops must not allocate scene nodes")
	main.quit_to_menu()
	await get_tree().create_timer(0.1).timeout
	print("REWARD REGRESSION ", "PASS" if failures == 0 else "FAIL")
	get_tree().quit(0 if failures == 0 else 1)
