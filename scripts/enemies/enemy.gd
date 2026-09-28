extends CharacterBody3D
enum State { IDLE, PATROL, ALERT, ATTACK, HURT, DEAD }
var state: State = State.IDLE
var data: EnemyData
var health: HealthComponent
var model: Node3D
var soldier_model: Node3D
var machine_model: Node3D
var base_scale := 1.0
var hurtbox: Area3D
var cooldown := 1.0
var telegraph := 0.0
var death_time := 0.0
var death_burst := 0.0
var hurt_time := 0.0
var phase := 1
var attack_index := 0
var active := false
var flash_material: ShaderMaterial
var flash_time := 0.0
var weapon := WeaponData.new()
var boss_data: BossData
var current_pattern: AttackPattern
var intro_time := 0.0
func _ready() -> void:
	collision_layer = 8
	collision_mask = 1
	ModelFactory.collider(self, Vector3(0.7, 1.8, 0.6), Vector3(0, 0.9, 0))
	model = ModelFactory.soldier(self, Color(0.48, 0.49, 0.29))
	ModelFactory.box(model, Vector3(0.9, 0.16, 0.2), Vector3(0.45, 1.3, 0.2), Color(0.13, 0.13, 0.15))
	soldier_model = model
	machine_model = ModelFactory.armored_machine(self)
	machine_model.hide()
	hurtbox = Area3D.new()
	hurtbox.set_script(preload("res://scripts/components/hurtbox.gd"))
	hurtbox.collision_layer = 0
	hurtbox.collision_mask = 0
	add_child(hurtbox)
	ModelFactory.collider(hurtbox, Vector3(0.85, 1.9, 0.8), Vector3(0, 0.95, 0))
	flash_material = ShaderMaterial.new()
	flash_material.shader = preload("res://shaders/hit_flash.gdshader")
	for visual in [soldier_model, machine_model]:
		apply_flash(visual)
	health = HealthComponent.new()
	add_child(health)
	health.died.connect(die)
	weapon.speed = 11
	weapon.damage = 1
	weapon.lifetime = 3
func activate(enemy_data: EnemyData, pos: Vector3) -> void:
	data = enemy_data
	boss_data = null
	current_pattern = null
	intro_time = 0
	hurt_time = 0
	death_time = 0
	death_burst = 0
	weapon.speed = 11
	position = pos
	velocity = Vector3.ZERO
	health.reset(data.health)
	state = State.ALERT
	active = true
	hurtbox.collision_layer = 16
	collision_layer = 8
	cooldown = randf_range(0.6, 1.7)
	telegraph = 0
	phase = 1
	attack_index = 0
	flash_time = 0
	flash_material.set_shader_parameter("strength", 0.0)
	set_physics_process(true)
	soldier_model.hide()
	machine_model.hide()
	for variant in ["bulwark", "mortar", "reactor"]:
		machine_model.get_node(variant).hide()
	model = machine_model if data.behavior in ["tank", "boss", "turret"] else soldier_model
	model.show()
	base_scale = {"boss": 1.65, "heavy": 1.15, "turret": 0.7}.get(data.behavior, 1.0)
	soldier_model.set_uniform(data.tint)
	soldier_model.reset_pose()
	for part in machine_model.get_children():
		if part is MeshInstance3D and not part.material_override.emission_enabled:
			part.material_override.albedo_color = data.tint
	model.position = Vector3.ZERO
	model.rotation = Vector3.ZERO
	model.scale = Vector3.ONE * base_scale
	hurtbox.scale = Vector3.ONE
	var hit_shape: CollisionShape3D = hurtbox.get_child(0)
	hit_shape.shape.size = Vector3(3.4, 2.5, 1.7) * base_scale if model == machine_model else Vector3(0.85, 1.9, 0.8) * base_scale
	hit_shape.position.y = hit_shape.shape.size.y * 0.5
func on_recycle() -> void:
	active = false
	collision_layer = 0
	hurtbox.collision_layer = 0
func _physics_process(delta: float) -> void:
	if not active or GameManager.state != GameManager.State.PLAYING:
		return
	flash_time = maxf(0, flash_time - delta)
	flash_material.set_shader_parameter("strength", flash_time / 0.12)
	if state == State.DEAD:
		death_time -= delta
		if data.behavior == "boss":
			death_burst -= delta
			if death_burst <= 0 and death_time > 0.3:
				death_burst = 0.45
				Combat.explode(self, position + Vector3(randf_range(-2, 1), randf_range(0.7, 3.5), 0), 1.6, 0, true)
		model.rotation.z = lerpf(model.rotation.z, -1.5, delta * 8)
		if death_time <= 0:
			PoolManager.release(self)
		return
	var player := GameManager.player
	if not is_instance_valid(player):
		return
	var distance := player.position.x - position.x
	if absf(distance) > 26:
		return
	hurt_time = maxf(0, hurt_time - delta)
	model.position.x = randf_range(-0.08, 0.08) if hurt_time > 0 else 0.0
	velocity.y -= 25 * delta
	velocity.x = 0
	velocity.z = 0
	if data.behavior in ["grunt", "heavy", "grenadier", "rusher", "tank"] and absf(distance) > (1.0 if data.behavior == "rusher" else data.attack_range):
		velocity.x = signf(distance) * data.move_speed
	move_and_slide()
	position.z = 0
	if model == soldier_model:
		model.pose(delta, velocity.x, signf(distance), not is_on_floor())
	if hurt_time > 0:
		return
	if intro_time > 0:
		intro_time -= delta
		return
	cooldown -= delta
	if telegraph > 0:
		telegraph -= delta
		model.scale.y = base_scale * (1 + sin(telegraph * 35) * 0.025)
		if telegraph <= 0:
			attack(player)
		return
	if cooldown <= 0 and absf(distance) < data.detection_range and player.state != player.State.DEAD:
		var query := PhysicsRayQueryParameters3D.create(position + Vector3(0, 1.3, 0), player.position + Vector3(0, 1, 0), 1)
		if get_world_3d().direct_space_state.intersect_ray(query).is_empty():
			telegraph = 0.8 if data.behavior in ["turret", "boss"] else 0.35
			if data.behavior == "boss" and boss_data:
				current_pattern = next_pattern()
				telegraph = current_pattern.telegraph
				GameManager.level.banner = boss_data.title.to_upper() + " • " + current_pattern.title.to_upper()
				GameManager.level.banner_time = telegraph
			state = State.ATTACK
			Combat.effect(position + Vector3(0, 2.5 if data.behavior != "boss" else 6, 0), Vector3(0.25, 0.5, 0.2), Color(1, 0.15, 0.1), telegraph)
			cooldown = 1.0 / data.fire_rate + randf_range(0, 0.35)
func attack(player: Node3D) -> void:
	var origin := position + Vector3(-0.6, 1.25, 0)
	var direction := (player.position + Vector3(0, 1, 0) - origin).normalized()
	match data.behavior:
		"rusher":
			if position.distance_to(player.position) < 2.0:
				player.take_damage(1, self)
		"grenadier":
			Combat.grenade(self, origin, signf(direction.x), false)
		"boss":
			if boss_data and current_pattern:
				execute_pattern(player)
		"tank":
			Combat.grenade(self, origin, signf(direction.x), false)
		_:
			Combat.fire(self, origin, direction, weapon, false)
func take_damage(amount: float, source: Node = null) -> bool:
	if not active or state == State.DEAD:
		return false
	var hit := health.take_damage(amount, source)
	if hit:
		flash_time = 0.12
		hurt_time = 0.10 if data.behavior != "boss" else 0
		Combat.effect(position + Vector3(0, 1, 0), Vector3.ONE * 0.6, Color.WHITE, 0.09)
	return hit
func die() -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	hurtbox.collision_layer = 0
	collision_layer = 0
	death_time = 0.65 if data.behavior != "boss" else 3.0
	death_burst = 0.35
	EventBus.enemy_killed.emit(data.score_value)
	if data.drop_table and randf() < data.drop_chance and is_instance_valid(GameManager.level):
		var reward := data.drop_table.choose()
		if reward == "score":
			GameManager.score += data.drop_table.score_bonus
		elif reward == "life":
			GameManager.lives += 1
		else:
			GameManager.level.add_pickup(position + Vector3.UP, reward)
		EventBus.hud_changed.emit()
	if data.behavior in ["tank", "boss"]:
		Combat.explode(self, position + Vector3(0, 2, 0), 3, 0, true)

func configure_boss(config: BossData) -> void:
	boss_data = config
	machine_model.get_node(config.equipment).show()
	for part in machine_model.get_children():
		if part is MeshInstance3D and not part.material_override.emission_enabled:
			part.material_override.albedo_color = config.tint
	health.reset(config.health)
	intro_time = 2.5
	cooldown = 0.3

func next_pattern() -> AttackPattern:
	phase = 1 + int(health.current_health < health.max_health * 0.66) + int(health.current_health < health.max_health * 0.33)
	for i in boss_data.patterns.size():
		var pattern := boss_data.patterns[attack_index % boss_data.patterns.size()]
		attack_index += 1
		if pattern.minimum_phase <= phase:
			return pattern
	return boss_data.patterns[0]

func execute_pattern(player: Node3D) -> void:
	var pattern := current_pattern
	var origin := position + Vector3(-1.5, 2.8, 0)
	weapon.speed = pattern.speed
	match pattern.kind:
		"grenades":
			for i in pattern.projectile_count:
				Combat.grenade(self, origin + Vector3(-i * 1.4, 0, 0), -1, false)
		"aimed":
			var direction := (player.position + Vector3.UP - origin).normalized()
			Combat.fire(self, origin, direction, weapon, false)
		"low_sweep":
			for i in pattern.projectile_count:
				Combat.fire(self, position + Vector3(-1.5 - i * 1.5, 0.55, 0), Vector3.LEFT, weapon, false)
		_:
			for i in pattern.projectile_count:
				var angle := (i - (pattern.projectile_count - 1) * 0.5) * pattern.spread
				Combat.fire(self, origin, Vector3.LEFT.rotated(Vector3.FORWARD, angle), weapon, false)
	cooldown = pattern.cooldown

func apply_flash(root: Node) -> void:
	if root is MeshInstance3D:
		root.material_overlay = flash_material
	for child in root.get_children():
		apply_flash(child)
