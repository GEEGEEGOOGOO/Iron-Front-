extends CharacterBody3D
var health: HealthComponent
var driver: CharacterBody3D
var facing := 1.0
var cooldown := 0.0
var cannon_cooldown := 0.0
var gun: Node3D
var label: Label3D
var wrecked := false
var ram_cooldown := 0.0
var ram_shape := BoxShape3D.new()
var ram_query := PhysicsShapeQueryParameters3D.new()
var machine_gun: WeaponData = preload("res://data/weapons/machine_gun.tres")
var cannon: WeaponData = preload("res://data/weapons/rocket.tres")
func _ready() -> void:
	ram_shape.size = Vector3(0.8, 1.5, 1.3)
	ram_query.shape = ram_shape
	ram_query.collision_mask = 16 | 256
	ram_query.collide_with_areas = true
	collision_layer = 512
	collision_mask = 1
	ModelFactory.collider(self, Vector3(2.9, 1.8, 1.5), Vector3(0, 0.9, 0))
	ModelFactory.box(self, Vector3(3.1, 0.6, 1.7), Vector3(0, 0.45, 0), Color(0.12, 0.15, 0.17))
	ModelFactory.box(self, Vector3(2.7, 0.9, 1.4), Vector3(0, 1.0, 0), Color(0.28, 0.4, 0.32))
	ModelFactory.box(self, Vector3(1.6, 0.7, 1.1), Vector3(0, 1.7, 0), Color(0.38, 0.51, 0.4))
	for x in [-1.0, -0.5, 0.0, 0.5, 1.0]:
		ModelFactory.sphere(self, 0.28, Vector3(x, 0.45, 0.88), Color(0.3, 0.32, 0.3))
	gun = Node3D.new()
	add_child(gun)
	gun.position.y = 1.8
	ModelFactory.box(gun, Vector3(2, 0.25, 0.3), Vector3(1, 0, 0), Color(0.24, 0.3, 0.26))
	health = HealthComponent.new()
	add_child(health)
	health.reset(18)
	health.mercy_time = 0.3
	health.died.connect(destroy)
	label = Label3D.new()
	label.position.y = 3.0
	label.text = "IRON MULE • E / Y TO ENTER"
	label.font_size = 28
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
func _physics_process(delta: float) -> void:
	if wrecked or GameManager.state != GameManager.State.PLAYING:
		return
	ram_cooldown = maxf(0, ram_cooldown - delta)
	velocity.y -= 25 * delta
	velocity.x = 0
	velocity.z = 0
	if driver:
		cooldown -= delta
		cannon_cooldown -= delta
		var axis := Input.get_axis("move_left", "move_right")
		velocity.x = axis * 4.8
		if absf(axis) > 0.1:
			facing = signf(axis)
		driver.facing = facing
		gun.rotation.y = 0 if facing > 0 else PI
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = 8
		var origin := firing_origin()
		if Input.is_action_pressed("fire") and cooldown <= 0:
			Combat.fire(self, origin, Vector3(facing, 0, 0), machine_gun, true)
			cooldown = 0.09
		if Input.is_action_just_pressed("fire_secondary") and cannon_cooldown <= 0:
			Combat.fire(self, origin, Vector3(facing, 0, 0), cannon, true)
			cannon_cooldown = 0.9
		label.text = "ARMOR %d / 18 • E TO EXIT" % ceili(health.current_health)
	move_and_slide()
	try_ram()
	position.z = 0
	if driver:
		position.x = clampf(position.x, GameManager.level.rig.position.x - 14, GameManager.level.rig.position.x + 14)
		if GameManager.level.encounter:
			position.x = minf(position.x, GameManager.level.data.waves[GameManager.level.wave_index].arena_center + 10)
func enter_vehicle(player: CharacterBody3D) -> void:
	if wrecked or driver:
		return
	driver = player
	player.vehicle = self
	player.state = player.State.VEHICLE
	player.hide()
func firing_origin() -> Vector3:
	var breech := global_position + Vector3(0, 1.8, 0)
	return Combat.muzzle_origin(self, breech, breech + Vector3(facing * 2.1, 0, 0), Vector3(facing, 0, 0), true)
func exit_vehicle() -> void:
	if not driver:
		return
	var player := driver
	driver = null
	player.vehicle = null
	player.position = position + Vector3(-facing * 2, 1, 0)
	player.velocity = Vector3(0, 5, 0)
	player.health.invulnerability = 2
	player.state = player.State.FALL
	player.show()
	label.text = "IRON MULE • E / Y TO ENTER"
func take_damage(amount: float, source: Node = null) -> bool:
	if not driver or wrecked:
		return false
	return health.take_damage(amount, source)
func destroy() -> void:
	exit_vehicle()
	wrecked = true
	collision_layer = 0
	Combat.explode(self, position + Vector3.UP, 4, 0, true)
	label.text = "DISABLED"
	for child in get_children():
		if child is MeshInstance3D:
			child.material_override.albedo_color = Color(0.12, 0.11, 0.1)

func try_ram() -> int:
	if not driver or wrecked or absf(velocity.x) < 3 or ram_cooldown > 0:
		return 0
	ram_query.transform.origin = global_position + Vector3(signf(velocity.x) * 1.7, 0.85, 0)
	var count := 0
	for hit in get_world_3d().direct_space_state.intersect_shape(ram_query, 16):
		if Combat.damage(hit.collider, 4, self):
			count += 1
	if count > 0:
		ram_cooldown = 0.45
		EventBus.shake_requested.emit(0.12, 0.12)
		AudioManager.play_at("hit", global_position)
	return count
