extends Node3D
var remaining := 0.0
var duration := 0.0
var drift := Vector3.ZERO
var model: MeshInstance3D
func _ready() -> void:
	model = ModelFactory.box(self, Vector3.ONE, Vector3.ZERO, Color(1, 0.7, 0.15))
func activate(pos: Vector3, size: Vector3, color: Color, time: float, motion := Vector3.ZERO) -> void:
	global_position = pos
	rotation = Vector3.ZERO
	scale = size
	model.scale = Vector3.ONE
	model.material_override.albedo_color = color
	remaining = time
	duration = time
	drift = motion
func _physics_process(delta: float) -> void:
	remaining -= delta
	position += drift * delta
	model.scale = Vector3.ONE * maxf(0.05, remaining / duration)
	if remaining <= 0:
		PoolManager.release(self)
