class_name ArmoredVisual
extends Node3D
# Geometry is built only when a pooled enemy actually needs this chassis.
var designs: Dictionary = {}
var turret: Node3D
var selected := ""
const ARMOR := Color(0.34, 0.40, 0.25)
const STEEL := Color(0.12, 0.16, 0.17)
const EDGE := Color(0.46, 0.49, 0.37)
func build() -> void:
	for kind in ["bulwark", "mortar", "reactor"]:
		var equipment := Node3D.new()
		equipment.name = kind
		add_child(equipment)
		equipment.hide()
		match kind:
			"bulwark":
				for y in [0.75, 1.3, 1.85]:
					var plate := ModelFactory.detail_box(equipment, Vector3(0.25, 0.6, 1.95), Vector3(-1.7, y, 0), Color(0.27, 0.4, 0.4))
					plate.rotation.z = -0.22
			"mortar":
				for z in [-0.5, 0.0, 0.5]:
					var barrel := ModelFactory.detail_box(equipment, Vector3(1.5, 0.3, 0.3), Vector3(0.2, 2.65, z), Color(0.5, 0.33, 0.18))
					barrel.rotation.z = -0.65
			"reactor":
				for x in [-0.4, 0.2, 0.8]:
					ModelFactory.detail_box(equipment, Vector3(0.18, 0.85, 1.5), Vector3(x, 2.6, 0), Color(0.3, 0.26, 0.42))
				var core := ModelFactory.box(equipment, Vector3(0.6, 0.5, 0.12), Vector3(0.2, 2.65, 0.83), Color(0.2, 0.8, 1))
				core.material_override = ModelFactory.material(Color(0.2, 0.8, 1), 2)
func configure(kind: String, tint: Color) -> void:
	if not designs.has(kind):
		var chassis := Node3D.new()
		chassis.name = kind
		add_child(chassis)
		designs[kind] = chassis
		build_design(chassis, kind)
	for key in designs:
		designs[key].visible = key == kind
	selected = kind
	turret = designs[kind].get_node("Turret")
	paint(designs[kind], tint)
func paint(root: Node, tint: Color) -> void:
	if root is MeshInstance3D and root.has_meta("armor"):
		root.material_override.albedo_color = tint
	for child in root.get_children():
		paint(child, tint)
func plate(root: Node3D, size: Vector3, pos: Vector3, tint := ARMOR) -> MeshInstance3D:
	var part := ModelFactory.detail_box(root, size, pos, tint)
	part.set_meta("armor", true)
	return part
func build_design(root: Node3D, kind: String) -> void:
	var heavy := kind == "heavy"
	var sentry := kind == "sentry"
	if sentry:
		ModelFactory.detail_box(root, Vector3(2.7, 0.3, 1.55), Vector3(0, 0.2, 0), STEEL)
		for side in [-1.0, 1.0]:
			ModelFactory.rod(root, Vector3(-1.1, 0.3, side * 0.6), Vector3(-0.45, 1.35, side * 0.35), 0.18, STEEL)
			ModelFactory.rod(root, Vector3(1.1, 0.3, side * 0.6), Vector3(0.45, 1.35, side * 0.35), 0.18, STEEL)
		plate(root, Vector3(1.1, 0.5, 1), Vector3(0, 1.15, 0))
	else:
		var length := 3.4 if heavy else 3.05
		for side in [-1.0, 1.0]:
			ModelFactory.detail_box(root, Vector3(length, 0.66, 0.36), Vector3(0, 0.43, side * 0.73), STEEL)
			var count := 6 if heavy else 4
			for i in count:
				var x := -length * 0.38 + float(i) / (count - 1) * length * 0.76
				ModelFactory.wheel(root, Vector3(x, 0.44, side * 0.94), 0.27 if heavy else 0.30)
			for i in 12:
				var x := -length * 0.46 + i * length * 0.083
				for y in [0.13, 0.77]:
					ModelFactory.detail_box(root, Vector3(0.20, 0.12, 0.43), Vector3(x, y, side * 0.73), Color(0.23, 0.26, 0.25))
		plate(root, Vector3(length - 0.25, 0.65 if heavy else 0.48, 1.38), Vector3(0, 1.0, 0))
		var nose := plate(root, Vector3(0.65, 0.2, 1.42), Vector3(-1.12, 1.22, 0))
		nose.rotation.z = 0.28
		for side in [-1.0, 1.0]:
			for i in (4 if heavy else 2):
				var x := -0.95 + i * (0.62 if heavy else 1.45)
				plate(root, Vector3(0.53, 0.42 if heavy else 0.25, 0.12), Vector3(x, 1.0, side * 0.77))
				for offset in [-0.18, 0.18]:
					ModelFactory.box(root, Vector3(0.05, 0.05, 0.035), Vector3(x + offset, 1.13, side * 0.85), EDGE)
			var lamp := ModelFactory.box(root, Vector3(0.10, 0.12, 0.18), Vector3(-1.43, 1.18, side * 0.5), Color(1, 0.55, 0.12))
			lamp.material_override = ModelFactory.material(Color(1, 0.55, 0.12), 1.3)
	var head := Node3D.new()
	head.name = "Turret"
	root.add_child(head)
	head.position = Vector3(0.12 if heavy else -0.18, 1.65, 0)
	plate(head, Vector3(1.75 if heavy else 1.1, 0.7 if heavy else 0.52, 1.30 if heavy else 0.95), Vector3.ZERO)
	plate(head, Vector3(0.65, 0.12, 0.65), Vector3(0.18, 0.41 if heavy else 0.32, 0))
	ModelFactory.detail_box(head, Vector3(1.5, 0.23, 0.24), Vector3(-1.3, 0.05, 0), STEEL)
	ModelFactory.detail_box(head, Vector3(0.28, 0.32, 0.35), Vector3(-2.02, 0.05, 0), EDGE)
	ModelFactory.box(head, Vector3(0.015, 0.16, 0.20), Vector3(-2.17, 0.05, 0), Color(0.025, 0.03, 0.03))
	if sentry:
		ModelFactory.detail_box(head, Vector3(1.65, 0.18, 0.18), Vector3(-1.35, -0.20, 0.35), STEEL)
	for side in [-1.0, 1.0]:
		var optic := ModelFactory.box(head, Vector3(0.20, 0.12, 0.04), Vector3(-0.3, 0.1, side * (0.68 if heavy else 0.5)), Color(1, 0.35, 0.08))
		optic.material_override = ModelFactory.material(Color(1, 0.35, 0.08), 1.8)
	ModelFactory.rod(head, Vector3(0.4, 0.24, -0.3), Vector3(0.4, 1.05, -0.3), 0.045, STEEL)
	if heavy:
		plate(root, Vector3(0.65, 0.8, 1.25), Vector3(1.3, 1.45, 0))
		for side in [-1.0, 1.0]:
			ModelFactory.rod(root, Vector3(1.2, 1.5, side * 0.6), Vector3(1.2, 2.5, side * 0.6), 0.18, STEEL)
			for y in [1.7, 1.85, 2.0, 2.15]:
				ModelFactory.box(root, Vector3(0.23, 0.055, 0.25), Vector3(1.2, y, side * 0.6), EDGE)
			ModelFactory.rod(root, Vector3(0.8, 1.2, side * 0.8), Vector3(0.2, 1.8, side * 0.8), 0.12, STEEL)
			ModelFactory.rod(root, Vector3(0.5, 1.5, side * 0.8), Vector3(0.2, 1.8, side * 0.8), 0.065, Color(0.62, 0.66, 0.65))
			for y in [1.38, 1.54]:
				ModelFactory.rod(root, Vector3(0.4, y, side * 0.75), Vector3(1.5, y, side * 0.75), 0.055, Color(0.1, 0.12, 0.12))
				ModelFactory.box(root, Vector3(0.10, 0.12, 0.10), Vector3(0.9, y, side * 0.75), Color(0.9, 0.4, 0.07))
		for i in 5:
			ModelFactory.box(root, Vector3(0.035, 0.45, 0.05), Vector3(1.05 + i * 0.1, 1.5, 0.67), STEEL)
