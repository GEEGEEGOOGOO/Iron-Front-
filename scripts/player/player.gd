extends CharacterBody3D
enum State { IDLE, RUN, JUMP, FALL, CROUCH, CLIMB, HURT, DEAD, VEHICLE }
var state: State = State.IDLE
var facing := 1.0
var aim := Vector3.RIGHT
var health: HealthComponent
var model: Node3D
var gun: Node3D
var muzzle: Marker3D
var shape: CollisionShape3D
var hurt_shape: CollisionShape3D
var ground: RayCast3D
var weapon: WeaponData = preload("res://data/weapons/pistol.tres")
var ammo := -1
var reserve_weapon: WeaponData
var reserve_ammo := 0
var grenades := 8
var cooldown := 0.0
var grenade_cooldown := 0.0
var melee_cooldown := 0.0
var coyote := 0.0
var buffer := 0.0
var death_timer := 0.0
var vehicle: Node3D
var gait := 0.0
var crouching := false
var ladder: ClimbLadder
var ladder_grace := 0.0
func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 256
	shape = ModelFactory.collider(self, Vector3(0.65, 1.9, 0.65), Vector3(0, 0.95, 0))
	model = ModelFactory.soldier(self, Color(0.19, 0.43, 0.47))
	ModelFactory.box(model, Vector3(0.58, 0.12, 0.55), Vector3(0, 1.85, 0), Color(0.9, 0.3, 0.12))
	gun = Node3D.new()
	add_child(gun)
	gun.position.y = 1.25
	ModelFactory.box(gun, Vector3(0.8, 0.16, 0.18), Vector3(0.5, 0, 0.15), Color(0.12, 0.16, 0.19))
	muzzle = Marker3D.new()
	gun.add_child(muzzle)
	muzzle.position = Vector3(1, 0, 0)
	var hurtbox := Area3D.new()
	hurtbox.set_script(preload("res://scripts/components/hurtbox.gd"))
	hurtbox.collision_layer = 4
	hurtbox.collision_mask = 0
	add_child(hurtbox)
	hurt_shape = ModelFactory.collider(hurtbox, Vector3(0.65, 1.8, 0.6), Vector3(0, 0.95, 0))
	health = HealthComponent.new()
	add_child(health)
	health.mercy_time = 1.6
	health.reset(1 if SaveManager.data.arcade else 3)
	health.died.connect(die)
	health.changed.connect(func(): EventBus.hud_changed.emit())
	ground = RayCast3D.new()
	add_child(ground)
	ground.position.y = 0.2
	ground.target_position = Vector3(0, -0.35, 0)
	ground.collision_mask = 1
	GameManager.player = self
func _physics_process(delta: float) -> void:
	if GameManager.state != GameManager.State.PLAYING:
		return
	if state == State.DEAD:
		death_timer -= delta
		if death_timer <= 0:
			respawn()
		return
	if vehicle:
		global_position = vehicle.global_position
		if Input.is_action_just_pressed("interact"):
			vehicle.exit_vehicle()
		return
	cooldown -= delta
	grenade_cooldown -= delta
	melee_cooldown -= delta
	var input_x := Input.get_axis("move_left", "move_right")
	ladder_grace = maxf(0, ladder_grace - delta)
	var climb_input := Input.get_axis("crouch", "aim_up")
	if not ladder and ladder_grace <= 0 and absf(climb_input) > 0.3:
		ladder = GameManager.level.ladder_at(position)
	var climbing := is_instance_valid(ladder)
	if climbing:
		if Input.is_action_just_pressed("jump") or absf(input_x) > 0.3:
			ladder = null
			climbing = false
			ladder_grace = 0.3
			velocity.y = 8.0
		else:
			position.x = ladder.global_position.x
			velocity = Vector3(0, climb_input * 3.8, 0)
			position.y = clampf(position.y, ladder.position.y, ladder.position.y + ladder.height)
			if (position.y <= ladder.position.y and climb_input < 0) or (position.y >= ladder.position.y + ladder.height and climb_input > 0):
				velocity.y = 0
	var crouched := Input.is_action_pressed("crouch") and is_on_floor() and not climbing
	if crouching and not crouched and not can_stand():
		crouched = true
	crouching = crouched
	if absf(input_x) > 0.1:
		facing = signf(input_x)
	var aim_y := Input.get_action_strength("aim_up") - (Input.get_action_strength("crouch") if not is_on_floor() else 0.0)
	aim = Vector3(facing if absf(input_x) > 0.1 or absf(aim_y) < 0.2 else 0, signf(aim_y) if absf(aim_y) > 0.2 else 0, 0).normalized()
	gun.rotation.z = atan2(aim.y, aim.x)
	gun.position.y = 0.68 if crouched else 1.25
	model.scale.y = 0.55 if crouched else 1.0
	shape.shape.size.y = 1.0 if crouched else 1.9
	shape.position.y = shape.shape.size.y * 0.5
	hurt_shape.shape.size.y = shape.shape.size.y
	hurt_shape.position.y = shape.position.y
	coyote = 0.11 if is_on_floor() or ground.is_colliding() else maxf(0, coyote - delta)
	buffer = 0.12 if Input.is_action_just_pressed("jump") else maxf(0, buffer - delta)
	if not climbing:
		velocity.x = input_x * (2.7 if crouched else 6.8)
		velocity.y -= 25 * delta
	velocity.z = 0
	if buffer > 0 and coyote > 0 and not climbing:
		velocity.y = 10.5
		buffer = 0
		coyote = 0
		AudioManager.play("jump")
	if Input.is_action_just_released("jump") and velocity.y > 3:
		velocity.y *= 0.48
	move_and_slide()
	position.z = 0
	state = State.CROUCH if crouched else (State.RUN if absf(input_x) > 0.1 else State.IDLE)
	if not is_on_floor():
		state = State.JUMP if velocity.y > 0 else State.FALL
	if climbing:
		state = State.CLIMB
	gait += delta * absf(velocity.x) * 2
	model.pose(delta, velocity.x, facing, not is_on_floor(), climbing, atan2(aim.y, absf(aim.x)))
	model.visible = health.invulnerability <= 0 or fmod(health.invulnerability, 0.14) < 0.07
	if Input.is_action_pressed("fire") and cooldown <= 0:
		Combat.fire(self, muzzle.global_position, aim, weapon, true)
		cooldown = 1.0 / weapon.fire_rate
		if ammo > 0:
			ammo -= 1
			reserve_ammo = ammo
			if ammo == 0:
				equip(preload("res://data/weapons/pistol.tres"))
		EventBus.hud_changed.emit()
	if Input.is_action_just_pressed("fire_secondary") and grenades > 0 and grenade_cooldown <= 0:
		Combat.grenade(self, position + Vector3(0, 1.4, 0), facing, true)
		grenades -= 1
		grenade_cooldown = 0.5
		EventBus.hud_changed.emit()
	if Input.is_action_just_pressed("melee") and melee_cooldown <= 0:
		melee_cooldown = 0.35
		Combat.melee(self, position + Vector3(0, 0.7 if crouching else 1.25, 0), facing)
		GameManager.level.interact(self, true)
	if Input.is_action_just_pressed("interact"):
		GameManager.level.interact(self, false)
	if Input.is_action_just_pressed("switch_weapon"):
		switch_weapon()
	if position.y < -8:
		health.invulnerability = 0
		take_damage(99)
func equip(data: WeaponData) -> void:
	if data.max_ammo < 0:
		reserve_weapon = null
		reserve_ammo = 0
		ammo = -1
	else:
		reserve_ammo = mini(data.max_ammo, reserve_ammo + data.starting_ammo) if reserve_weapon == data and reserve_ammo > 0 else data.starting_ammo
		reserve_weapon = data
		ammo = reserve_ammo
	weapon = data
	EventBus.weapon_picked_up.emit(data.title)
	EventBus.hud_changed.emit()
func switch_weapon() -> void:
	if not reserve_weapon or reserve_ammo <= 0:
		return
	if weapon == reserve_weapon:
		reserve_ammo = ammo
		weapon = preload("res://data/weapons/pistol.tres")
		ammo = -1
	else:
		weapon = reserve_weapon
		ammo = reserve_ammo
	EventBus.hud_changed.emit()
func take_damage(amount: float, source: Node = null) -> bool:
	if GameManager.god_mode or state == State.DEAD or vehicle:
		return false
	var accepted := health.take_damage(amount, source)
	if accepted:
		AudioManager.play("hit")
		EventBus.shake_requested.emit(0.18, 0.2)
	return accepted
func die() -> void:
	state = State.DEAD
	death_timer = 1.5
	hide()
	GameManager.lives -= 1
	EventBus.player_died.emit()
	EventBus.hud_changed.emit()
func respawn() -> void:
	ladder = null
	ladder_grace = 0
	if vehicle:
		vehicle.exit_vehicle()
	if GameManager.lives <= 0:
		GameManager.state = GameManager.State.GAME_OVER
		return
	GameManager.level.reset_encounter()
	position = GameManager.checkpoint
	velocity = Vector3.ZERO
	health.reset(1 if SaveManager.data.arcade else 3)
	health.invulnerability = 2
	state = State.IDLE
	grenades = maxi(grenades, 5)
	equip(preload("res://data/weapons/pistol.tres"))
	show()

func can_stand() -> bool:
	var standing := BoxShape3D.new()
	standing.size = Vector3(0.63, 0.86, 0.63)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = standing
	query.transform.origin = global_position + Vector3(0, 1.46, 0)
	query.collision_mask = 1 | 256
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()
