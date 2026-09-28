extends StaticBody3D
var prisoner: CharacterBody3D
var health: HealthComponent
var opened := false
func _ready() -> void:
	collision_layer = 256
	collision_mask = 0
	ModelFactory.collider(self, Vector3(1.5, 2.2, 1.3), Vector3(0, 1.1, 0))
	for x in [-0.7, -0.35, 0, 0.35, 0.7]:
		for z in [-0.6, 0.6]:
			ModelFactory.box(self, Vector3(0.055, 2.2, 0.055), Vector3(x, 1.1, z), Color(0.3, 0.34, 0.35))
	for y in [0.12, 2.1]:
		ModelFactory.box(self, Vector3(1.55, 0.12, 1.35), Vector3(0, y, 0), Color(0.22, 0.26, 0.27))
	health = HealthComponent.new()
	add_child(health)
	health.reset(3)
	health.died.connect(open_cage)
func take_damage(amount: float, source: Node = null) -> bool:
	return health.take_damage(amount, source) if not opened else false
func open_cage() -> void:
	if opened:
		return
	opened = true
	collision_layer = 0
	hide()
	if is_instance_valid(prisoner):
		prisoner.locked = false
		prisoner.label.text = "FREE • INTERACT TO RESCUE"
	for i in 6:
		Combat.fragment(position + Vector3.UP, Vector3(0.06, 0.6, 0.06), Color(0.3, 0.34, 0.35), Vector3(randf_range(-3, 3), randf_range(2, 5), randf_range(-1, 1)), 1.8)
	AudioManager.play_at("hit", position)
