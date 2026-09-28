extends Node3D
@export var data: LevelData
var player: CharacterBody3D
var rig: Node3D
var wave_index := 0
var encounter_spawners: Array[EnemySpawner] = []
var encounter := false
var previous_wave_cleared_at := -1.0
var spawn_index := 0
var spawn_timer := 0.0
var enemies: Array[Node] = []
var boss: Node
var boss_started := false
var boss_reward_given := false
var victory_timer := 0.0
var boss_prisoner: CharacterBody3D
var pows: Array[Node3D] = []
var checkpoint_index := 0
var checkpoint_wave_index := 0
var checkpoint_lamps: Array[MeshInstance3D] = []
var checkpoint_labels: Array[Label3D] = []
var tank: CharacterBody3D
var ladders: Array[ClimbLadder] = []
var elevators: Array[FreightElevator] = []
var banner := ""
var banner_time := 3.0
func _ready() -> void:
	GameManager.level = self
	var authored := get_node_or_null("Encounters")
	if authored:
		data = data.duplicate() as LevelData
		data.waves = []
		for child in authored.get_children():
			if child is EnemySpawner and child.wave:
				encounter_spawners.append(child)
				data.waves.append(child.configured_wave())
	AudioManager.start_mission(data.background_music, data.boss_music)
	build_world()
	player = preload("res://scripts/player/player.gd").new()
	add_child(player)
	player.position = Vector3(2, 0.1, 0)
	rig = preload("res://scripts/player/camera_rig.gd").new()
	add_child(rig)
	rig.configure(data)
	banner = data.mission_name.to_upper()
func build_world() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = data.sky_color
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = data.sky_color.lightened(0.3)
	env.ambient_light_energy = 0.65
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -25, 0)
	sun.light_energy = 2.0
	sun.shadow_enabled = true
	add_child(sun)
	platform(Vector3(data.length * 0.5, -0.7, 0), Vector3(data.length + 20, 1.4, 7), data.ground_color)
	build_theme_ground()
	var backdrop_random := RandomNumberGenerator.new()
	backdrop_random.seed = 1009 + GameManager.mission * 10007
	for i in range(-2, 28):
		var x := i * 5.0
		var height := backdrop_random.randf_range(3, 12)
		var backdrop := ModelFactory.box(self, Vector3(backdrop_random.randf_range(3, 6), height, 3), Vector3(x, height / 2 - 0.1, -10), data.ground_color.darkened(0.27))
		backdrop.name = "BackdropBlock%d" % i
		ModelFactory.box(self, Vector3(4, 0.2, 1), Vector3(x, 0.08, -2), data.ground_color.lightened(0.12))
		if i % 3 == 0:
			ModelFactory.box(self, Vector3(0.15, 5, 0.15), Vector3(x, 2.5, -3), Color(0.18, 0.22, 0.24))
	build_theme_props()
	build_checkpoint_markers()
	build_ladders()
	build_elevators()
	for i in data.platform_positions.size():
		platform(data.platform_positions[i], data.platform_sizes[i], data.ground_color.lightened(0.13))
	for i in data.crate_positions.size():
		var prop = preload("res://scripts/levels/prop.gd").new()
		add_child(prop)
		prop.setup(data.crate_positions[i], false, "rocket" if i == data.crate_positions.size() - 1 else "machine_gun")
	for pos in data.barrel_positions:
		var barrel = preload("res://scripts/levels/prop.gd").new()
		add_child(barrel)
		barrel.setup(pos, true, "")
	for pos in data.pow_positions:
		var pow_node = preload("res://scripts/levels/prisoner.gd").new()
		add_child(pow_node)
		pow_node.position = pos
		pows.append(pow_node)
		var cage = preload("res://scripts/levels/pow_cage.gd").new()
		cage.prisoner = pow_node
		add_child(cage)
		cage.position = pow_node.position
		pow_node.cage = cage
		pow_node.locked = true
	boss_prisoner = preload("res://scripts/levels/prisoner.gd").new()
	add_child(boss_prisoner)
	boss_prisoner.position = data.commander_position
	boss_prisoner.locked = true
	boss_prisoner.hide()
	pows.append(boss_prisoner)
	tank = preload("res://scripts/vehicles/tank.gd").new()
	add_child(tank)
	tank.position = data.tank_position
	for i in mini(data.supply_positions.size(), data.supply_kinds.size()):
		add_pickup(data.supply_positions[i], data.supply_kinds[i])
func platform(pos: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	add_child(body)
	body.position = pos
	body.collision_layer = 1
	ModelFactory.collider(body, size, Vector3.ZERO)
	ModelFactory.box(body, size, Vector3.ZERO, color)
func add_pickup(pos: Vector3, kind: String) -> void:
	var pickup = PoolManager.acquire("pickup")
	if pickup:
		pickup.setup(pos, kind)
func build_checkpoint_markers() -> void:
	for i in data.checkpoint_positions.size():
		var marker := Node3D.new()
		marker.name = "Checkpoint%d" % i
		marker.position = Vector3(data.checkpoint_positions[i], 0, -2.9)
		add_child(marker)
		ModelFactory.box(marker, Vector3(0.16, 2.2, 0.16), Vector3(0, 1.1, 0), Color(0.15, 0.2, 0.22))
		ModelFactory.box(marker, Vector3(0.7, 0.12, 0.35), Vector3(0, 2.25, 0), Color(0.15, 0.2, 0.22))
		var lamp := ModelFactory.box(marker, Vector3(0.54, 0.28, 0.25), Vector3(0, 2.0, 0.12), Color(0.95, 0.45, 0.08))
		lamp.material_override = ModelFactory.material(Color(0.95, 0.45, 0.08), 1.5)
		checkpoint_lamps.append(lamp)
		var label := Label3D.new()
		label.text = "CHECKPOINT"
		label.position = Vector3(0, 2.7, 0)
		label.font_size = 26
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		marker.add_child(label)
		checkpoint_labels.append(label)
	activate_checkpoint_marker(0)
func activate_checkpoint_marker(index: int) -> void:
	if index < 0 or index >= checkpoint_lamps.size():
		return
	checkpoint_lamps[index].material_override = ModelFactory.material(Color(0.18, 0.9, 0.55), 2.0)
	checkpoint_labels[index].text = "CHECKPOINT SECURED"
func _physics_process(delta: float) -> void:
	if GameManager.state != GameManager.State.PLAYING:
		return
	banner_time = maxf(0, banner_time - delta)
	if player.state == player.State.DEAD:
		return
	if not encounter and wave_index < data.waves.size() and can_start_wave(data.waves[wave_index]):
		encounter = true
		spawn_index = 0
		spawn_timer = 0
		rig.lock_x = data.waves[wave_index].arena_center
		banner = "AMBUSH • HOLD THE LINE"
		banner_time = 2
	if encounter:
		var wave := data.waves[wave_index]
		player.position.x = minf(player.position.x, wave.arena_center + 11)
		spawn_timer -= delta
		if spawn_index < wave.enemy_types.size() and spawn_timer <= 0:
			var point := Vector3(wave.arena_center + 9 - spawn_index * 1.8, 1, 0)
			if wave_index < encounter_spawners.size():
				point = encounter_spawners[wave_index].spawn_position(spawn_index)
			spawn_enemy(wave.enemy_types[spawn_index], point)
			spawn_index += 1
			spawn_timer = wave.spawn_delay
		if spawn_index >= wave.enemy_types.size() and living_enemies() == 0:
			encounter = false
			previous_wave_cleared_at = GameManager.elapsed
			wave_index += 1
			rig.lock_x = -1
			EventBus.wave_cleared.emit()
			banner = "SECTOR CLEAR • ADVANCE →"
			banner_time = 2
	for i in data.checkpoint_positions.size():
		if i > checkpoint_index and player.position.x >= data.checkpoint_positions[i] and not encounter:
			checkpoint_index = i
			checkpoint_wave_index = wave_index
			activate_checkpoint_marker(i)
			GameManager.checkpoint = Vector3(data.checkpoint_positions[i], 1, 0)
			banner = "CHECKPOINT SECURED"
			banner_time = 2
	if player.position.x > data.boss_trigger_x and not boss_started and wave_index >= data.waves.size():
		boss_started = true
		rig.lock_x = data.boss_arena_x
		boss = spawn_enemy("boss", data.boss_spawn_position)
		boss.configure_boss(data.boss_data)
		rig.start_boss_intro(boss.intro_time)
		AudioManager.start_boss()
		banner = "WARNING • " + data.boss_data.title.to_upper()
		banner_time = 3
	if boss_started:
		player.position.x = minf(player.position.x, data.boss_room_max_x)
		if is_instance_valid(boss) and boss.state == boss.State.DEAD:
			player.health.invulnerability = maxf(player.health.invulnerability, 0.3)
			if boss.death_time < 0.2 and not boss_reward_given:
				boss_reward_given = true
				victory_timer = 2.5
				boss_prisoner.locked = false
				boss_prisoner.show()
				if boss_prisoner.rescue():
					GameManager.rescued += 1
					GameManager.score += 500
					EventBus.pow_rescued.emit()
					EventBus.hud_changed.emit()
				banner = "COMMANDER RESCUED • MISSION SECURED"
				banner_time = 3
				for item in PoolManager.borrowed.keys():
					if PoolManager.borrowed[item] == "projectile":
						PoolManager.release(item)
			if boss_reward_given:
				victory_timer -= delta
				if victory_timer <= 0:
					GameManager.finish()
func spawn_enemy(kind: String, pos: Vector3) -> Node:
	var enemy = PoolManager.acquire("enemy")
	if enemy:
		enemy.activate(load("res://data/enemies/" + kind + ".tres"), pos)
		if enemy not in enemies:
			enemies.append(enemy)
	return enemy
func living_enemies() -> int:
	var count := 0
	for enemy in enemies:
		if enemy.active and enemy.state != enemy.State.DEAD:
			count += 1
	return count
func reset_encounter() -> void:
	AudioManager.play_music(data.background_music)
	for enemy in enemies:
		PoolManager.release(enemy)
	enemies.clear()
	for item in PoolManager.borrowed.keys():
		if PoolManager.borrowed[item] in ["projectile", "effect", "fragment", "burst"]:
			PoolManager.release(item)
	encounter = false
	boss_started = false
	previous_wave_cleared_at = GameManager.elapsed if checkpoint_wave_index > 0 else -1.0
	boss_reward_given = false
	victory_timer = 0
	boss = null
	wave_index = checkpoint_wave_index
	rig.lock_x = -1
	rig.intro_remaining = 0
	rig.shake = 0
	rig.shake_time = 0
	rig.position.y = 0
	GameManager.hitstop_until = 0
	Engine.time_scale = 1.0
	rig.frontier = clampf(GameManager.checkpoint.x, rig.min_x, rig.max_x)
	rig.position.x = rig.frontier
func interact(actor: Node3D, melee: bool) -> void:
	if not melee and tank.position.distance_to(actor.position) < 3 and not tank.wrecked:
		tank.enter_vehicle(actor)
		return
	for pow_node in pows:
		if pow_node.position.distance_to(actor.position) >= 2.5:
			continue
		if is_instance_valid(pow_node.cage):
			pow_node.cage.open_cage()
		if pow_node.rescue():
			GameManager.rescued += 1
			GameManager.score += 500
			grant_pow_reward(data.pow_rewards.choose(), pow_node.position)
			EventBus.pow_rescued.emit()
			EventBus.hud_changed.emit()
			AudioManager.play("pickup")

func grant_pow_reward(reward: String, pos: Vector3) -> void:
	match reward:
		"score":
			GameManager.score += data.pow_rewards.score_bonus
			banner = "RESCUE BONUS +%d" % data.pow_rewards.score_bonus
		"life":
			GameManager.lives += 1
			banner = "RESCUE BONUS • EXTRA LIFE"
		_:
			add_pickup(pos + Vector3.UP, reward)
			banner = "POW RESCUED • SUPPLIES DROPPED"
	banner_time = 2
	EventBus.hud_changed.emit()

func build_theme_ground() -> void:
	match data.theme:
		"coast":
			var water := ModelFactory.box(self, Vector3(data.length + 20, 0.12, 6), Vector3(data.length * 0.5, 0.02, -6.5), Color(0.12, 0.3, 0.38))
			water.name = "CoastalWater"
			water.material_override.roughness = 0.28
			for x in range(0, int(data.length), 9):
				ModelFactory.box(self, Vector3(3.0, 0.025, 0.1), Vector3(x + 1.5, 0.025, 2.45), Color(0.79, 0.75, 0.55))
				ModelFactory.box(self, Vector3(2.5, 0.02, 0.09), Vector3(x + 3, -0.78, -4.35), Color(0.72, 0.83, 0.82))
		"desert":
			for x in range(-6, int(data.length) + 12, 12):
				var dune := ModelFactory.sphere(self, 1.0, Vector3(x, -1.35, -6.2), Color(0.65, 0.44, 0.25))
				dune.scale = Vector3(5.0, 1.0, 2.2)
			for x in range(2, int(data.length), 11):
				ModelFactory.box(self, Vector3(2.2, 0.025, 0.08), Vector3(x, 0.025, 2.35), Color(0.79, 0.56, 0.32))
		"foundry":
			var furnace_channel := ModelFactory.box(self, Vector3(data.length + 20, 0.12, 6), Vector3(data.length * 0.5, 0.02, -6.5), Color(0.95, 0.16, 0.025))
			furnace_channel.name = "FoundryChannel"
			furnace_channel.material_override = ModelFactory.material(Color(0.95, 0.16, 0.025), 1.8)
			for x in range(1, int(data.length), 7):
				var warning_stripe := ModelFactory.box(self, Vector3(0.36, 0.025, 1.4), Vector3(x, 0.025, 2.4), Color(0.95, 0.61, 0.07))
				warning_stripe.rotation.y = 0.38
				ModelFactory.box(self, Vector3(0.16, 0.5, 0.18), Vector3(x, 0.25, -3.25), Color(0.16, 0.19, 0.21))

func build_theme_props() -> void:
	for x in [8.0, 39.0, 68.0, 97.0, 121.0]:
		match data.theme:
			"coast":
				# Dock crane and stacked freight, staged behind the gameplay lane.
				ModelFactory.box(self, Vector3(0.5, 8, 0.5), Vector3(x, 4, -5), Color(0.6, 0.39, 0.16))
				ModelFactory.box(self, Vector3(8, 0.4, 0.5), Vector3(x + 2, 8, -5), Color(0.6, 0.39, 0.16))
				ModelFactory.box(self, Vector3(0.06, 4, 0.06), Vector3(x + 5, 6, -5), Color(0.15, 0.18, 0.2))
				ModelFactory.box(self, Vector3(5, 2, 2.4), Vector3(x + 3, 1, -6), Color(0.25, 0.42, 0.43))
			"desert":
				for offset in [-2.0, 2.0]:
					ModelFactory.box(self, Vector3(1.3, 5, 1.5), Vector3(x + offset, 2.5, -5), Color(0.63, 0.44, 0.27))
				ModelFactory.box(self, Vector3(6.5, 0.8, 1.5), Vector3(x, 5.3, -5), Color(0.66, 0.46, 0.28))
				ModelFactory.sphere(self, 1.8, Vector3(x + 5, 0.3, -4), Color(0.52, 0.34, 0.21))
			"foundry":
				ModelFactory.box(self, Vector3(3, 6, 3), Vector3(x, 3, -6), Color(0.19, 0.22, 0.26))
				var furnace := ModelFactory.box(self, Vector3(2, 2.8, 0.1), Vector3(x, 2.4, -4.45), Color(1, 0.25, 0.04))
				furnace.material_override = ModelFactory.material(Color(1, 0.2, 0.025), 2)
				ModelFactory.box(self, Vector3(0.8, 6, 0.8), Vector3(x + 1, 8, -6), Color(0.18, 0.2, 0.23))

func build_ladders() -> void:
	for i in mini(data.ladder_positions.size(), data.ladder_heights.size()):
		var ladder := ClimbLadder.new()
		ladder.height = data.ladder_heights[i]
		add_child(ladder)
		ladder.position = data.ladder_positions[i]
		ladders.append(ladder)
		var top := ladder.position.y + ladder.height
		platform(Vector3(ladder.position.x + 2.5, top - 0.15, 0), Vector3(4, 0.3, 3), data.ground_color.lightened(0.2))
		add_pickup(Vector3(ladder.position.x + 2, top + 1, 0), "grenades")
func ladder_at(feet: Vector3) -> ClimbLadder:
	for ladder in ladders:
		if ladder.contains(feet):
			return ladder
	return null

func build_elevators() -> void:
	for i in mini(data.elevator_positions.size(), data.elevator_travel.size()):
		var lift := FreightElevator.new()
		lift.position = data.elevator_positions[i]
		lift.travel = data.elevator_travel[i]
		add_child(lift)
		elevators.append(lift)
		var top := lift.position.y + lift.travel
		platform(Vector3(lift.position.x + 3.4, top, 0), Vector3(3.5, 0.35, 3), data.ground_color.lightened(0.2))
		add_pickup(Vector3(lift.position.x + 3, top + 1, 0), "flame")
		for x in [-1.65, 1.65]:
			ModelFactory.box(self, Vector3(0.15, lift.travel + 2, 0.15), Vector3(lift.position.x + x, (lift.travel + 2) / 2, -1.8), Color(0.2, 0.24, 0.26))

func can_start_wave(wave: WaveData) -> bool:
	match wave.trigger_condition:
		"level_start":
			return true
		"timer":
			return GameManager.elapsed >= wave.trigger_delay
		"previous_cleared":
			return previous_wave_cleared_at >= 0 and GameManager.elapsed - previous_wave_cleared_at >= wave.trigger_delay
		_:
			return player.position.x >= wave.trigger_x
