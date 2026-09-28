class_name SoldierVisual
extends Node3D
var legs: Array[Node3D] = []
var arms: Array[Node3D] = []
var upper: Node3D
var cycle := 0.0
func build(tint: Color) -> void:
	upper = Node3D.new()
	add_child(upper)
	upper.position.y = 1.15
	ModelFactory.box(upper, Vector3(0.62, 0.7, 0.48), Vector3(0, -0.05, 0), tint)
	ModelFactory.box(upper, Vector3(0.45, 0.42, 0.43), Vector3(0, 0.47, 0), Color(0.78, 0.58, 0.4))
	ModelFactory.box(upper, Vector3(0.55, 0.17, 0.52), Vector3(0, 0.74, 0), tint.darkened(0.2))
	ModelFactory.box(upper, Vector3(0.14, 0.15, 0.45), Vector3(0.22, 0.5, 0), Color(0.12, 0.18, 0.19))
	ModelFactory.box(upper, Vector3(0.25, 0.5, 0.55), Vector3(-0.36, -0.06, 0), tint.darkened(0.35))
	ModelFactory.box(upper, Vector3(0.65, 0.12, 0.54), Vector3(0, -0.35, 0), Color(0.22, 0.19, 0.13))
	for side in [-1.0, 1.0]:
		var leg := Node3D.new()
		add_child(leg)
		leg.position = Vector3(0, 0.75, side * 0.17)
		ModelFactory.box(leg, Vector3(0.23, 0.65, 0.24), Vector3(0, -0.32, 0), tint.darkened(0.35))
		ModelFactory.box(leg, Vector3(0.37, 0.17, 0.28), Vector3(0.07, -0.67, 0), Color(0.12, 0.13, 0.14))
		legs.append(leg)
		var arm := Node3D.new()
		upper.add_child(arm)
		arm.position = Vector3(0, 0.05, side * 0.34)
		ModelFactory.box(arm, Vector3(0.48, 0.2, 0.2), Vector3(0.23, -0.05, 0), tint)
		ModelFactory.box(arm, Vector3(0.2, 0.19, 0.19), Vector3(0.55, -0.05, 0), Color(0.78, 0.58, 0.4))
		arms.append(arm)
func pose(delta: float, speed: float, facing: float, airborne := false, climbing := false, aim_y := 0.0) -> void:
	rotation.y = 0 if facing >= 0 else PI
	cycle += delta * (9 if climbing else absf(speed) * 2.4)
	var stride := sin(cycle) * (0.6 if climbing else 0.65)
	for i in legs.size():
		var target := (stride if i == 0 else -stride) if absf(speed) > 0.1 or climbing else 0.0
		if airborne and not climbing:
			target = -0.5 if i == 0 else 0.7
		legs[i].rotation.z = lerpf(legs[i].rotation.z, target, minf(1, delta * 18))
	for i in arms.size():
		arms[i].rotation.z = (1.5 + sin(cycle + i * PI) * 0.5) if climbing else aim_y
	upper.position.y = 1.15 + absf(sin(cycle)) * 0.035 if absf(speed) > 0.1 else 1.15

func set_uniform(tint: Color) -> void:
	upper.get_child(0).material_override.albedo_color = tint
	upper.get_child(2).material_override.albedo_color = tint.darkened(0.2)
	upper.get_child(4).material_override.albedo_color = tint.darkened(0.35)
	for leg in legs:
		leg.get_child(0).material_override.albedo_color = tint.darkened(0.35)
	for arm in arms:
		arm.get_child(0).material_override.albedo_color = tint

func reset_pose() -> void:
	cycle = 0
	for limb in legs + arms:
		limb.rotation = Vector3.ZERO
	upper.position.y = 1.15
