extends StaticBody3D
var health: HealthComponent
var explosive := false
var reward := "machine_gun"
func setup(pos: Vector3, barrel: bool, pickup: String) -> void:
	position = pos
	explosive = barrel
	reward = pickup
	collision_layer = 256
	collision_mask = 0
	ModelFactory.collider(self, Vector3(1.1, 1.2, 0.9), Vector3(0, 0.6, 0))
	if barrel:
		var shell := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.48
		cylinder.bottom_radius = 0.48
		cylinder.height = 1.15
		cylinder.radial_segments = 12
		shell.mesh = cylinder
		shell.material_override = ModelFactory.material(Color(0.48, 0.09, 0.045))
		add_child(shell)
		shell.position.y = 0.6
		for y in [0.18, 0.95]:
			var ring := MeshInstance3D.new()
			var band := TorusMesh.new()
			band.inner_radius = 0.44
			band.outer_radius = 0.50
			band.rings = 12
			band.ring_segments = 6
			ring.mesh = band
			ring.material_override = ModelFactory.material(Color(0.22, 0.12, 0.08))
			add_child(ring)
			ring.position.y = y
	else:
		ModelFactory.detail_box(self, Vector3(1.1, 1.2, 0.9), Vector3(0, 0.6, 0), Color(0.25, 0.28, 0.12))
		for x in [-0.36, 0.36]:
			ModelFactory.detail_box(self, Vector3(0.08, 1.23, 0.95), Vector3(x, 0.6, 0), Color(0.13, 0.16, 0.08))
		ModelFactory.box(self, Vector3(0.4, 0.15, 0.04), Vector3(0, 0.7, 0.47), Color(0.62, 0.53, 0.23))
	health = HealthComponent.new()
	add_child(health)
	health.reset(3)
	health.died.connect(destroy)
func take_damage(amount: float, source: Node = null) -> bool:
	return health.take_damage(amount, source)
func destroy() -> void:
	collision_layer = 0
	hide()
	if explosive:
		Combat.explode(self, position + Vector3(0, 0.8, 0), 3.5, 8, true)
	else:
		Combat.effect(position + Vector3.UP, Vector3.ONE * 1.4, Color(0.6, 0.4, 0.2), 0.25)
		for i in 8:
			Combat.fragment(position + Vector3.UP, Vector3(0.3, 0.12, 0.2), Color(0.6, 0.4, 0.2), Vector3(randf_range(-4, 4), randf_range(2, 6), randf_range(-2, 2)), 2.0)
	if not reward.is_empty():
		GameManager.level.add_pickup(position + Vector3(0, 1, 0), reward)
