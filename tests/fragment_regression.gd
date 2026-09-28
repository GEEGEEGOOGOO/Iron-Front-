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
	var piece = PoolManager.acquire("fragment")
	piece.activate(Vector3(4, 3, 0), Vector3.ONE * 0.2, Color.WHITE, Vector3.ZERO, 4)
	for i in 90:
		await get_tree().physics_frame
	check(piece.position.y < 1, "Fragment must fall under physics gravity")
	check(piece.position.y > 0, "Fragment must collide with the floor")
	check(piece.collision_layer == 0 and piece.collision_mask == 1, "Fragments must only interact with world geometry")
	PoolManager.release(piece)
	check(piece.freeze and piece.collision_mask == 0, "Recycled fragments must stop physics")
	var total := PoolManager.get_child_count()
	var borrowed: Array[Node] = []
	for i in 160:
		var fragment = PoolManager.acquire("fragment")
		check(fragment != null, "Every preallocated fragment must be available")
		if fragment:
			fragment.activate(Vector3(5, 2, 0), Vector3.ONE * 0.1, Color.WHITE, Vector3.UP, 0.1)
			borrowed.append(fragment)
	check(PoolManager.acquire("fragment") == null, "Exhausted cosmetic pool must not allocate")
	check(PoolManager.get_child_count() == total, "Burst must keep scene node count fixed")
	for i in 15:
		await get_tree().physics_frame
	check(PoolManager.pools.fragment.size() == 160, "Expired fragments must all return to pool")
	main.quit_to_menu()
	await get_tree().create_timer(0.1).timeout
	print("FRAGMENT REGRESSION ", "PASS" if failures == 0 else "FAIL")
	get_tree().quit(0 if failures == 0 else 1)
