extends StaticBody3D
var health: HealthComponent
func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	ModelFactory.collider(self, Vector3(3.1, 1.2, 1.7), Vector3(0, 0.6, 0))
	ModelFactory.box(self, Vector3(3.1, 0.6, 1.7), Vector3(0, 0.35, 0), Color(0.12, 0.11, 0.1))
	ModelFactory.box(self, Vector3(2.5, 0.7, 1.4), Vector3(0, 0.85, 0), Color(0.23, 0.16, 0.12))
	var turret := ModelFactory.box(self, Vector3(1.4, 0.55, 1), Vector3(0.3, 1.3, 0), Color(0.17, 0.15, 0.12))
	turret.rotation.z = -0.25
	health = HealthComponent.new()
	add_child(health)
	health.died.connect(destroy)
func activate(pos: Vector3) -> void:
	global_position = pos
	collision_layer = 256
	health.reset(6)
func take_damage(amount: float, source: Node = null) -> bool:
	return health.take_damage(amount, source)
func destroy() -> void:
	for i in 8:
		Combat.fragment(position + Vector3.UP, Vector3(0.3, 0.2, 0.25), Color(0.2, 0.16, 0.12), Vector3(randf_range(-4, 4), randf_range(2, 5), randf_range(-2, 2)), 2)
	PoolManager.release(self)
func on_recycle() -> void:
	collision_layer = 0
