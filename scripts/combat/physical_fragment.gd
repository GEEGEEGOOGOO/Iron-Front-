extends RigidBody3D
var remaining := 0.0
var mesh: MeshInstance3D
var shape: CollisionShape3D
func _ready() -> void:
	freeze = true
	collision_layer = 0
	collision_mask = 0
	mass = 0.08
	linear_damp = 0.25
	angular_damp = 0.6
	var material := PhysicsMaterial.new()
	material.bounce = 0.3
	material.friction = 0.7
	physics_material_override = material
	mesh = ModelFactory.box(self, Vector3.ONE, Vector3.ZERO, Color(0.7, 0.5, 0.2))
	shape = ModelFactory.collider(self, Vector3.ONE, Vector3.ZERO)
func activate(pos: Vector3, size: Vector3, color: Color, motion: Vector3, lifetime: float) -> void:
	freeze = true
	global_transform = Transform3D(Basis.IDENTITY, pos)
	mesh.scale = size
	shape.shape.size = size
	mesh.material_override.albedo_color = color
	remaining = lifetime
	collision_mask = 1
	linear_velocity = motion
	angular_velocity = Vector3(randf_range(-8, 8), randf_range(-8, 8), randf_range(-8, 8))
	sleeping = false
	freeze = false
func _physics_process(delta: float) -> void:
	remaining -= delta
	mesh.visible = remaining > 0.3 or fmod(remaining, 0.08) < 0.04
	if remaining <= 0 or position.y < -12:
		PoolManager.release(self)
func on_recycle() -> void:
	freeze = true
	collision_mask = 0
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	mesh.show()
