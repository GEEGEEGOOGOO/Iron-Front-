class_name ModelFactory
extends RefCounted
static func material(color: Color, glow := 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.82
	if glow > 0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = glow
	return mat
static func box(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = material(color)
	parent.add_child(mesh)
	mesh.position = pos
	return mesh
static func sphere(parent: Node3D, radius: float, pos: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := SphereMesh.new()
	shape.radius = radius
	shape.height = radius * 2
	mesh.mesh = shape
	mesh.material_override = material(color)
	parent.add_child(mesh)
	mesh.position = pos
	return mesh
static func collider(parent: CollisionObject3D, size: Vector3, pos: Vector3) -> CollisionShape3D:
	var collision := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	collision.shape = box_shape
	parent.add_child(collision)
	collision.position = pos
	return collision
static func soldier(parent: Node3D, tint: Color) -> Node3D:
	var model := SoldierVisual.new()
	parent.add_child(model)
	model.build(tint)
	return model

static func armored_machine(parent: Node3D) -> Node3D:
	var model := Node3D.new()
	parent.add_child(model)
	var armor := Color(0.26, 0.32, 0.3)
	box(model, Vector3(3.4, 0.7, 1.65), Vector3(0, 0.4, 0), Color(0.1, 0.12, 0.13))
	box(model, Vector3(3.1, 1.0, 1.45), Vector3(0, 1.15, 0), armor)
	box(model, Vector3(1.9, 0.9, 1.2), Vector3(0.35, 2.05, 0), armor.lightened(0.13))
	box(model, Vector3(2.5, 0.28, 0.35), Vector3(-1.65, 2.1, 0), Color(0.14, 0.18, 0.18))
	box(model, Vector3(0.5, 0.45, 0.55), Vector3(-2.8, 2.1, 0), Color(0.12, 0.14, 0.15))
	for x in [-1.3, -0.65, 0.0, 0.65, 1.3]:
		sphere(model, 0.32, Vector3(x, 0.45, 0.87), Color(0.3, 0.32, 0.29))
		box(model, Vector3(0.42, 0.13, 0.15), Vector3(x, 0.45, 1.13), Color(0.12, 0.14, 0.14))
	for x in [-0.65, -0.25, 0.15, 0.55]:
		box(model, Vector3(0.18, 0.48, 0.08), Vector3(x, 1.2, 0.78), Color(0.12, 0.16, 0.16))
	var core := sphere(model, 0.25, Vector3(-0.85, 1.9, 0.68), Color(1, 0.28, 0.05))
	core.material_override = material(Color(1, 0.25, 0.04), 2)
	box(model, Vector3(0.12, 1.1, 0.12), Vector3(1.1, 2.6, -0.3), Color(0.16, 0.18, 0.17))
	for variant in ["bulwark", "mortar", "reactor"]:
		var equipment := Node3D.new()
		equipment.name = variant
		model.add_child(equipment)
		equipment.hide()
		match variant:
			"bulwark":
				for y in [0.8, 1.35, 1.9]:
					var plate := box(equipment, Vector3(0.3, 0.65, 2.1), Vector3(-1.7, y, 0), Color(0.3, 0.42, 0.42))
					plate.rotation.z = -0.25
				box(equipment, Vector3(1.2, 0.25, 1.5), Vector3(0.2, 2.6, 0), Color(0.25, 0.35, 0.36))
			"mortar":
				for z in [-0.55, 0, 0.55]:
					var barrel := box(equipment, Vector3(1.6, 0.3, 0.3), Vector3(0.25, 2.9, z), Color(0.5, 0.34, 0.19))
					barrel.rotation.z = -0.65
				box(equipment, Vector3(1.2, 0.8, 1.6), Vector3(1.1, 1.8, 0), Color(0.42, 0.3, 0.19))
			"reactor":
				for x in [-0.4, 0.2, 0.8]:
					box(equipment, Vector3(0.18, 1.0, 1.6), Vector3(x, 2.8, 0), Color(0.32, 0.27, 0.46))
				var energy := sphere(equipment, 0.42, Vector3(0.25, 2.8, 0.8), Color(0.35, 0.8, 1))
				energy.material_override = material(Color(0.25, 0.7, 1), 2.5)
	return model
