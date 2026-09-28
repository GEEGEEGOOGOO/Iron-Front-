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
	ModelFactory.box(self, Vector3(1.1, 1.2, 0.9), Vector3(0, 0.6, 0), Color(0.64, 0.18, 0.10) if barrel else Color(0.50, 0.35, 0.17))
	ModelFactory.box(self, Vector3(1.15, 0.12, 0.95), Vector3(0, 0.8, 0), Color(0.2, 0.22, 0.22))
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
