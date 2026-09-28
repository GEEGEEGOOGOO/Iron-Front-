extends Node3D
var velocity := Vector3.ZERO
var remaining := 0.0
var power := 1.0
var radius := 0.0
var friendly := false
var ballistic := false
var source: Node3D
var mesh: MeshInstance3D
var query := PhysicsRayQueryParameters3D.new()
func _ready() -> void:
	query.collide_with_areas = true
	mesh = ModelFactory.sphere(self, 0.11, Vector3.ZERO, Color(1, 0.7, 0.1))
func activate(owner_node: Node3D, pos: Vector3, motion: Vector3, damage_value: float, player_owned: bool, lifetime: float, splash: float, arc: bool) -> void:
	source = owner_node
	position = pos
	velocity = motion
	power = damage_value
	friendly = player_owned
	query.collision_mask = (1 | 16 | 256) if friendly else (1 | 4 | 256 | 512)
	remaining = lifetime
	radius = splash
	ballistic = arc
	mesh.scale = Vector3.ONE * (2 if arc else 1)
	mesh.material_override.albedo_color = Color(1, 0.84, 0.2) if friendly else Color(1, 0.18, 0.1)
func _physics_process(delta: float) -> void:
	remaining -= delta
	if ballistic:
		velocity.y -= 19 * delta
	var next := position + velocity * delta
	query.from = position
	query.to = next
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		position = hit.position
		if radius <= 0 and Combat.damage(hit.collider, power, source) and friendly:
			GameManager.hits += 1
		impact()
		return
	position = next
	position.z = 0
	if remaining <= 0:
		impact()
func impact() -> void:
	if radius > 0:
		Combat.explode(self, position, radius, power, friendly, friendly)
	else:
		Combat.effect(position, Vector3.ONE * 0.2, Color(1, 0.7, 0.1), 0.12)
	PoolManager.release(self)
