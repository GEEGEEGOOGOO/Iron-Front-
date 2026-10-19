extends Node3D
var velocity := Vector3.ZERO
var remaining := 0.0
var power := 1.0
var radius := 0.0
var friendly := false
var ballistic := false
var source: Node3D
var mesh: MeshInstance3D
var artwork: Sprite3D
var trail_clock := 0.0
var visual_kind := "bullet"
var query := PhysicsRayQueryParameters3D.new()
func _ready() -> void:
	query.collide_with_areas = true
	mesh = ModelFactory.sphere(self, 0.11, Vector3.ZERO, Color(1, 0.7, 0.1))
	mesh.hide()
	artwork = FxAtlas.sprite(self)
func activate(owner_node: Node3D, pos: Vector3, motion: Vector3, damage_value: float, player_owned: bool, lifetime: float, splash: float, arc: bool, kind := "bullet") -> void:
	visual_kind = "shell" if arc else kind
	trail_clock = 0.0
	rotation = Vector3.ZERO
	scale = Vector3.ONE
	var index: int = {"rocket": 2, "shell": 3, "plasma": 4}.get(visual_kind, 0)
	FxAtlas.setup(artwork, index)
	artwork.scale *= Vector3(0.8, 0.25, 1) if index in [2, 3] else Vector3(0.48, 0.10, 1)
	if kind == "shotgun":
		artwork.scale *= 0.65
	artwork.rotation.z = atan2(motion.y, motion.x)
	artwork.modulate = Color.WHITE if player_owned else Color(1.0, 0.40, 0.24)
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
	artwork.rotation.z = atan2(velocity.y, velocity.x)
	if visual_kind in ["rocket", "shell"]:
		trail_clock -= delta
		if trail_clock <= 0:
			trail_clock = 0.065
			Combat.effect(position - velocity.normalized() * 0.25, Vector3.ONE * 0.22, Color(0.36, 0.36, 0.33), 0.28, Vector3(0, 0.35, -0.1))
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
		Combat.art_effect(position, Vector3(0.48, 0.48, 1), 7, 0.12)
	PoolManager.release(self)
