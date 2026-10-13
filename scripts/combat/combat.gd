class_name Combat
extends RefCounted
static func effect(pos: Vector3, size: Vector3, color: Color, duration: float, drift := Vector3.ZERO) -> void:
	var fx = PoolManager.acquire("effect")
	if fx:
		fx.activate(pos, size, color, duration, drift)
static func damage(target: Object, amount: float, source: Node) -> bool:
	if target and target.has_method("take_damage"):
		return target.take_damage(amount, source)
	return false
static func muzzle_origin(source: Node3D, breech: Vector3, muzzle: Vector3, direction: Vector3, friendly: bool) -> Vector3:
	var mask := 1 | 256 | (16 if friendly else 4 | 512)
	var query := PhysicsRayQueryParameters3D.create(breech, muzzle, mask)
	query.collide_with_areas = true
	var obstruction := source.get_world_3d().direct_space_state.intersect_ray(query)
	return obstruction.position - direction * 0.025 if not obstruction.is_empty() else muzzle
static func fire(source: Node3D, origin: Vector3, direction: Vector3, weapon: WeaponData, friendly: bool) -> void:
	if weapon.attack_mode == "cone":
		flame(source, origin, direction, weapon, friendly)
		return
	AudioManager.play_at(weapon.sfx_fire, origin)
	effect(origin, Vector3(0.5, 0.25, 0.2), Color(1, 0.87, 0.3), 0.07)
	fragment(origin, Vector3(0.12, 0.06, 0.06), Color(0.8, 0.6, 0.2), Vector3(-direction.x * 2, 3, 1.4), 1.5)
	for i in weapon.pellets:
		var aim := direction.rotated(Vector3.FORWARD, randf_range(-weapon.spread_angle, weapon.spread_angle))
		if friendly:
			GameManager.shots += 1
		if weapon.is_hitscan:
			var end := origin + aim * weapon.range_meters
			var hit_any := false
			var excluded: Array[RID] = []
			for pierce in weapon.pierce_count:
				var query := PhysicsRayQueryParameters3D.create(origin, end, 1 | 16 | 256 if friendly else 1 | 4 | 256)
				query.collide_with_areas = true
				query.exclude = excluded
				var hit := source.get_world_3d().direct_space_state.intersect_ray(query)
				if hit.is_empty():
					break
				if damage(hit.collider, weapon.damage, source) and friendly:
					hit_any = true
				if weapon.pierce_count == 1 or hit.collider is StaticBody3D:
					end = hit.position
					break
				excluded.append(hit.rid)
			if hit_any:
				GameManager.hits += 1
			var center := (origin + end) * 0.5
			var tracer = PoolManager.acquire("effect")
			if tracer:
				tracer.activate(center, Vector3(origin.distance_to(end), 0.045, 0.045), weapon.color, 0.07)
				tracer.rotation.z = atan2(aim.y, aim.x)
		else:
			var bullet = PoolManager.acquire("projectile")
			if bullet:
				bullet.activate(source, origin, aim * weapon.speed, weapon.damage, friendly, weapon.lifetime, weapon.explosion_radius, false)
static func grenade(source: Node3D, origin: Vector3, direction: float, friendly: bool, damage_value := -1.0) -> void:
	var bullet = PoolManager.acquire("projectile")
	if bullet:
		if friendly:
			GameManager.shots += 1
		var power := damage_value if damage_value >= 0 else (9.0 if friendly else 1.0)
		bullet.activate(source, origin, Vector3(direction * 10, 9, 0), power, friendly, 2.0, 3.4, true)
static func explode(source: Node3D, pos: Vector3, radius: float, power: float, friendly: bool, track_accuracy := false) -> void:
	AudioManager.play_at("boom", pos)
	EventBus.shake_requested.emit(0.3, 0.3)
	EventBus.hitstop_requested.emit(0.045)
	var core = PoolManager.acquire("burst")
	if core:
		core.activate(pos, radius * 1.8, false, Vector3.ZERO)
	for i in 5:
		var cloud = PoolManager.acquire("burst")
		if cloud:
			cloud.activate(pos + Vector3(randf_range(-0.5, 0.5), randf_range(0, 0.5), -0.25), radius * randf_range(0.5, 0.9), true, Vector3(randf_range(-0.8, 0.8), randf_range(1, 2), -0.1))
	for i in 12:
		fragment(pos, Vector3.ONE * randf_range(0.12, 0.4), Color(0.3, 0.28, 0.25), Vector3(randf_range(-5, 5), randf_range(1, 7), randf_range(-2, 2)), 2.0)
	var shape := SphereShape3D.new()
	shape.radius = radius
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform.origin = pos
	query.collision_mask = 16 | 256 if friendly else 4 | 256 | 512
	query.collide_with_areas = true
	var touched: Array[Object] = []
	var hit_any := false
	for hit in source.get_world_3d().direct_space_state.intersect_shape(query, 64):
		var target: Node3D = hit.collider
		if target in touched:
			continue
		touched.append(target)
		var falloff := clampf(1.0 - target.global_position.distance_to(pos) / radius, 0.25, 1)
		if damage(target, power * falloff, source):
			hit_any = true
	if friendly and track_accuracy and hit_any:
		GameManager.hits += 1

# Resolve centers from collision shapes rather than actor feet for vertical aim.
static func target_center(target: Node3D) -> Vector3:
	for child in target.get_children():
		if child is CollisionShape3D:
			return child.global_position
	return target.global_position

static func visible_target(source: Node3D, origin: Vector3, target: Node3D) -> bool:
	var ray := PhysicsRayQueryParameters3D.create(origin, target_center(target), 1)
	return source.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

static func cone_targets(source: Node3D, origin: Vector3, direction: Vector3, reach: float, half_angle: float, mask: int) -> Array[Node3D]:
	var sphere := SphereShape3D.new()
	sphere.radius = reach
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.transform.origin = origin
	query.collision_mask = mask
	query.collide_with_areas = true
	var targets: Array[Node3D] = []
	for hit in source.get_world_3d().direct_space_state.intersect_shape(query, 64):
		var target: Node3D = hit.collider
		var offset := target_center(target) - origin
		if offset.length() <= reach and offset.normalized().dot(direction) >= cos(half_angle) and visible_target(source, origin, target):
			if target not in targets:
				targets.append(target)
	return targets

static func flame(source: Node3D, origin: Vector3, direction: Vector3, weapon: WeaponData, friendly: bool) -> void:
	var hit_any := false
	if friendly:
		GameManager.shots += 1
	for target in cone_targets(source, origin, direction, weapon.range_meters, weapon.cone_half_angle, 16 | 256 if friendly else 4 | 256 | 512):
		if damage(target, weapon.damage, source):
			hit_any = true
	if hit_any and friendly:
		GameManager.hits += 1
	for i in 5:
		var flame_direction := direction.rotated(Vector3.FORWARD, randf_range(-weapon.cone_half_angle, weapon.cone_half_angle))
		var distance := randf_range(0.4, weapon.range_meters)
		effect(origin + flame_direction * distance, Vector3.ONE * (0.16 + distance * 0.14), Color(1, randf_range(0.3, 0.7), 0.05), 0.16, flame_direction * 3)
	AudioManager.play_at(weapon.sfx_fire, origin)

static func melee(source: Node3D, origin: Vector3, facing: float) -> int:
	var count := 0
	for target in cone_targets(source, origin, Vector3(facing, 0, 0), 1.9, 0.9, 16 | 256):
		if damage(target, 4, source):
			count += 1
	effect(origin + Vector3(facing * 0.8, 0, 0), Vector3(1.4, 0.12, 0.18), Color(0.85, 0.95, 1), 0.12)
	if count > 0:
		AudioManager.play_at("hit", origin)
	return count

static func fragment(pos: Vector3, size: Vector3, color: Color, motion: Vector3, lifetime: float) -> void:
	var piece = PoolManager.acquire("fragment")
	if piece:
		piece.activate(pos, size, color, motion, lifetime)
