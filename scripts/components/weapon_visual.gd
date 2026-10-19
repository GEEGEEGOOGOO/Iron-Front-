class_name WeaponVisual
extends RefCounted
const METAL := Color(0.16, 0.20, 0.21)
const TEAL := Color(0.18, 0.40, 0.43)
const OLIVE := Color(0.38, 0.41, 0.25)
static func part(root: Node3D, size: Vector3, pos: Vector3, color := METAL) -> MeshInstance3D:
	return ModelFactory.detail_box(root, size, pos + Vector3(0, 0, 0.20), color)
static func build(root: Node3D, kind: String) -> void:
	if BlenderWeapon.PATHS.has(kind):
		var imported := BlenderWeapon.new()
		root.add_child(imported)
		imported.configure(kind)
		return
	var long_gun := kind != "pistol"
	part(root, Vector3(0.65 if long_gun else 0.52, 0.23 if long_gun else 0.16, 0.24), Vector3(0.48, 0, 0))
	var grip := part(root, Vector3(0.16, 0.30, 0.20), Vector3(0.32, -0.18, 0), TEAL)
	grip.rotation.z = -0.18
	part(root, Vector3(0.22, 0.045, 0.23), Vector3(0.48, -0.16, 0))
	if long_gun and kind != "rocket":
		part(root, Vector3(0.32, 0.13, 0.22), Vector3(0.02, -0.01, 0), OLIVE)
		part(root, Vector3(0.08, 0.26, 0.25), Vector3(-0.17, -0.06, 0))
	# Sight, receiver seam, fasteners and selector remain visible from either side.
	part(root, Vector3(0.12, 0.075, 0.16), Vector3(0.55, 0.16, 0))
	for side in [-1.0, 1.0]:
		part(root, Vector3(0.18, 0.045, 0.02), Vector3(0.49, 0.02, side * 0.13), OLIVE)
		part(root, Vector3(0.04, 0.04, 0.02), Vector3(0.28, 0.02, side * 0.13), Color(0.6, 0.63, 0.58))
	match kind:
		"pistol":
			part(root, Vector3(0.64, 0.08, 0.25), Vector3(0.55, 0.10, 0), OLIVE)
			part(root, Vector3(0.14, 0.15, 0.21), Vector3(0.90, 0.01, 0))
			for x in [0.33, 0.40, 0.47]:
				part(root, Vector3(0.025, 0.08, 0.27), Vector3(x, 0.09, 0))
		"machine_gun":
			part(root, Vector3(0.40, 0.32, 0.27), Vector3(0.57, -0.26, 0), OLIVE)
			part(root, Vector3(0.38, 0.20, 0.29), Vector3(0.98, 0, 0), TEAL)
			part(root, Vector3(0.38, 0.10, 0.12), Vector3(1.30, 0, 0))
			for x in [0.85, 0.96, 1.07]:
				part(root, Vector3(0.04, 0.08, 0.31), Vector3(x, 0.03, 0))
			part(root, Vector3(0.12, 0.15, 0.17), Vector3(1.43, 0, 0))
		"shotgun":
			for y in [-0.06, 0.07]:
				part(root, Vector3(0.60, 0.09, 0.14), Vector3(0.95, y, 0))
			part(root, Vector3(0.30, 0.16, 0.23), Vector3(0.84, -0.07, 0), TEAL)
			for x in [0.73, 0.81, 0.89, 0.97]:
				part(root, Vector3(0.025, 0.18, 0.25), Vector3(x, -0.07, 0))
		"rocket":
			part(root, Vector3(1.05, 0.35, 0.37), Vector3(0.53, 0.1, 0), OLIVE)
			for x in [0.05, 0.44, 0.91, 1.14]:
				part(root, Vector3(0.09, 0.42, 0.44), Vector3(x, 0.1, 0), TEAL if x == 0.44 else METAL)
			part(root, Vector3(0.02, 0.29, 0.30), Vector3(1.20, 0.1, 0), Color(0.025, 0.03, 0.03))
			part(root, Vector3(0.14, 0.16, 0.12), Vector3(0.54, 0.36, 0))
		"flame":
			part(root, Vector3(0.65, 0.13, 0.18), Vector3(0.86, 0, 0))
			for side in [-1.0, 1.0]:
				part(root, Vector3(0.24, 0.48, 0.18), Vector3(0.04, 0.05, side * 0.23), OLIVE)
				part(root, Vector3(0.25, 0.07, 0.20), Vector3(0.04, 0.08, side * 0.23), TEAL)
				ModelFactory.rod(root, Vector3(0.03, -0.19, 0.20 + side * 0.23), Vector3(0.46, -0.28, 0.20 + side * 0.12), 0.065, METAL)
			for x in [0.89, 1.02, 1.14]:
				part(root, Vector3(0.045, 0.23, 0.26), Vector3(x, 0, 0))
			var pilot := part(root, Vector3(0.07, 0.06, 0.07), Vector3(1.16, -0.11, 0), Color(1, 0.42, 0.07))
			pilot.material_override = ModelFactory.material(Color(1, 0.42, 0.07), 2)
		"laser":
			part(root, Vector3(0.38, 0.23, 0.29), Vector3(0.79, 0, 0), TEAL)
			for y in [-0.12, 0.12]:
				part(root, Vector3(0.55, 0.09, 0.23), Vector3(1.18, y, 0), TEAL)
			for x in [0.90, 1.02, 1.14]:
				part(root, Vector3(0.045, 0.36, 0.27), Vector3(x, 0, 0))
			for side in [-1.0, 1.0]:
				var core := part(root, Vector3(0.25, 0.11, 0.025), Vector3(0.77, 0, side * 0.16), Color(0.2, 0.85, 1))
				core.material_override = ModelFactory.material(Color(0.2, 0.85, 1), 2)
			var emitter := part(root, Vector3(0.08, 0.10, 0.16), Vector3(1.46, 0, 0), Color(0.2, 0.85, 1))
			emitter.material_override = ModelFactory.material(Color(0.2, 0.85, 1), 2)
