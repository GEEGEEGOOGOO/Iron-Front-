extends Node3D
var mesh: MeshInstance3D
var duration := 1.0
var remaining := 0.0
var drift := Vector3.ZERO
var smoke := false
var tint := Color.WHITE
func _ready() -> void:
	mesh = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1
	sphere.radial_segments = 12
	sphere.rings = 6
	mesh.mesh = sphere
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)
func activate(pos: Vector3, diameter: float, is_smoke: bool, motion: Vector3) -> void:
	position = pos
	scale = Vector3.ONE * diameter
	smoke = is_smoke
	duration = 1.2 if smoke else 0.24
	remaining = duration
	drift = motion
	tint = Color(0.22, 0.23, 0.24, 0.65) if smoke else Color(1, 0.7, 0.18, 0.95)
	mesh.scale = Vector3.ONE * (0.5 if smoke else 0.2)
	mesh.material_override.albedo_color = tint
func _physics_process(delta: float) -> void:
	remaining -= delta
	var age := clampf(1 - remaining / duration, 0, 1)
	position += drift * delta
	mesh.scale = Vector3.ONE * (lerpf(0.5, 1.5, age) if smoke else sin(age * PI))
	var color := tint
	color.a *= 1 - age
	mesh.material_override.albedo_color = color
	if remaining <= 0:
		PoolManager.release(self)
