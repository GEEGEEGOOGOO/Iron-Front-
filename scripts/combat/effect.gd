extends Node3D
var remaining := 0.0
var duration := 0.0
var drift := Vector3.ZERO
var model: MeshInstance3D
var artwork: Sprite3D
func _ready() -> void:
	model = ModelFactory.box(self, Vector3.ONE, Vector3.ZERO, Color(1, 0.7, 0.15))
	artwork = FxAtlas.sprite(self)
	artwork.hide()
func activate(pos: Vector3, size: Vector3, color: Color, time: float, motion := Vector3.ZERO) -> void:
	model.show()
	artwork.hide()
	global_position = pos
	rotation = Vector3.ZERO
	scale = size
	model.scale = Vector3.ONE
	model.material_override.albedo_color = color
	remaining = time
	duration = time
	drift = motion
func activate_art(pos: Vector3, size: Vector3, index: int, time: float, angle := 0.0, tint := Color.WHITE) -> void:
	activate(pos, size, Color.WHITE, time)
	model.hide()
	FxAtlas.setup(artwork, index)
	artwork.modulate = tint
	artwork.show()
	rotation.z = angle
func _physics_process(delta: float) -> void:
	remaining -= delta
	position += drift * delta
	model.scale = Vector3.ONE * maxf(0.05, remaining / duration)
	artwork.modulate.a = clampf(remaining / duration, 0.0, 1.0)
	if remaining <= 0:
		PoolManager.release(self)
