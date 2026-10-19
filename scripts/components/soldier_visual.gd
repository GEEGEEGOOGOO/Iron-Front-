class_name SoldierVisual
extends Node3D
var legs: Array[Node3D] = []
var arms: Array[Node3D] = []
var knees: Array[Node3D] = []
var shins: Array[MeshInstance3D] = []
var landing := 0.0
var was_airborne := false
var upper: Node3D
var cycle := 0.0
func build(tint: Color) -> void:
	upper = Node3D.new()
	add_child(upper)
	upper.position.y = 1.15
	ModelFactory.detail_box(upper, Vector3(0.62, 0.7, 0.48), Vector3(0, -0.05, 0), tint, "cloth")
	ModelFactory.box(upper, Vector3(0.45, 0.42, 0.43), Vector3(0, 0.47, 0), Color(0.78, 0.58, 0.4))
	var helmet := ModelFactory.sphere(upper, 0.32, Vector3(0, 0.69, 0), tint.darkened(0.2))
	helmet.scale = Vector3(1.0, 0.68, 0.95)
	ModelFactory.detail_box(upper, Vector3(0.14, 0.15, 0.45), Vector3(0.22, 0.5, 0), Color(0.12, 0.18, 0.19))
	ModelFactory.detail_box(upper, Vector3(0.25, 0.5, 0.55), Vector3(-0.36, -0.06, 0), tint.darkened(0.35))
	ModelFactory.detail_box(upper, Vector3(0.65, 0.12, 0.54), Vector3(0, -0.35, 0), Color(0.22, 0.19, 0.13))
	for side in [-1.0, 1.0]:
		var leg := Node3D.new()
		add_child(leg)
		leg.position = Vector3(0, 0.75, side * 0.17)
		ModelFactory.detail_box(leg, Vector3(0.23, 0.36, 0.24), Vector3(0, -0.18, 0), tint.darkened(0.35), "cloth")
		var knee := Node3D.new()
		leg.add_child(knee)
		knee.position.y = -0.36
		knees.append(knee)
		shins.append(ModelFactory.detail_box(knee, Vector3(0.21, 0.31, 0.23), Vector3(0, -0.155, 0), tint.darkened(0.35), "cloth"))
		ModelFactory.detail_box(knee, Vector3(0.37, 0.14, 0.28), Vector3(0.07, -0.33, 0), Color(0.12, 0.13, 0.14))
		ModelFactory.detail_box(knee, Vector3(0.10, 0.17, 0.27), Vector3(0.13, -0.04, 0), Color(0.39, 0.42, 0.28))
		legs.append(leg)
		var arm := Node3D.new()
		upper.add_child(arm)
		arm.position = Vector3(0, 0.05, side * 0.34)
		ModelFactory.detail_box(arm, Vector3(0.48, 0.2, 0.2), Vector3(0.23, -0.05, 0), tint, "cloth")
		ModelFactory.box(arm, Vector3(0.2, 0.19, 0.19), Vector3(0.55, -0.05, 0), Color(0.78, 0.58, 0.4))
		ModelFactory.detail_box(arm, Vector3(0.25, 0.12, 0.25), Vector3(0.12, 0.08, 0), Color(0.38, 0.42, 0.28))
		ModelFactory.detail_box(arm, Vector3(0.14, 0.22, 0.22), Vector3(0.45, -0.05, 0), Color(0.11, 0.14, 0.15))
		arms.append(arm)
	# Gear follows the animated upper body rather than floating beside it.
	for side in [-1.0, 1.0]:
		ModelFactory.detail_box(upper, Vector3(0.54, 0.42, 0.075), Vector3(0.03, -0.02, side * 0.28), Color(0.35, 0.39, 0.26))
		for x in [-0.18, 0.05, 0.24]:
			ModelFactory.detail_box(upper, Vector3(0.16, 0.21, 0.09), Vector3(x, -0.20, side * 0.35), Color(0.42, 0.43, 0.29))
			ModelFactory.box(upper, Vector3(0.08, 0.035, 0.02), Vector3(x, -0.16, side * 0.405), Color(0.15, 0.18, 0.16))
		ModelFactory.detail_box(upper, Vector3(0.09, 0.50, 0.065), Vector3(-0.16, 0.02, side * 0.32), Color(0.17, 0.21, 0.18))
		ModelFactory.detail_box(upper, Vector3(0.19, 0.20, 0.07), Vector3(-0.09, 0.52, side * 0.25), Color(0.15, 0.21, 0.21))
		ModelFactory.box(upper, Vector3(0.045, 0.075, 0.02), Vector3(0.19, 0.51, side * 0.23), Color(0.04, 0.06, 0.06))
		ModelFactory.box(upper, Vector3(0.56, 0.055, 0.04), Vector3(0, 0.66, side * 0.27), Color(0.9, 0.36, 0.08))
	ModelFactory.detail_box(upper, Vector3(0.16, 0.46, 0.42), Vector3(-0.43, -0.03, 0), Color(0.3, 0.34, 0.23))
	ModelFactory.detail_box(upper, Vector3(0.07, 0.24, 0.30), Vector3(-0.54, -0.04, 0), Color(0.4, 0.41, 0.27))
func pose(delta: float, speed: float, facing: float, airborne := false, climbing := false, aim_y := 0.0, crouched := false, vertical_speed := 0.0, reload_progress := -1.0, dashing := false) -> void:
	rotation.y = 0 if facing >= 0 else PI
	if was_airborne and not airborne:
		landing = 0.16
	was_airborne = airborne
	landing = maxf(0, landing - delta)
	cycle += delta * (9 if climbing else absf(speed) * 2.4)
	var blend := 1.0 - exp(-20 * delta)
	var compression := sin(landing / 0.16 * PI) * 0.16
	for i in legs.size():
		var stride := sin(cycle + i * PI)
		var thigh := stride * 0.65 if absf(speed) > 0.1 else 0.0
		var bend := maxf(0, -stride) * 0.8 if absf(speed) > 0.1 else 0.0
		var hip_height := 0.75 - compression
		if crouched:
			hip_height = 0.42
			thigh = -1.1 + stride * 0.08
			bend = 1.9
		elif airborne:
			thigh = (-0.85 if i == 0 else 0.3) if vertical_speed > 1 else (-0.25 if i == 0 else 0.2)
			bend = (1.35 if i == 0 else 0.85) if vertical_speed > 1 else 0.35
		if dashing:
			thigh = 0.85 if i == 0 else 1.2
			bend = 0.8 if i == 0 else 1.4
		if climbing:
			thigh = stride * 0.7
			bend = 0.6
		legs[i].position.y = lerpf(legs[i].position.y, hip_height, blend)
		legs[i].rotation.z = lerp_angle(legs[i].rotation.z, thigh, blend)
		knees[i].rotation.z = lerp_angle(knees[i].rotation.z, bend, blend)
	for i in arms.size():
		var angle := (1.5 + sin(cycle + i * PI) * 0.5) if climbing else aim_y
		if dashing:
			angle = -0.35 if i == 0 else 0.9
		if reload_progress >= 0 and i == 1:
			angle = -0.9 * sin(reload_progress * PI)
		arms[i].rotation.z = lerp_angle(arms[i].rotation.z, angle, blend)
	var torso_y := 0.46 if crouched else 1.15 - compression
	upper.position.y = lerpf(upper.position.y, torso_y, blend)
	upper.rotation.z = lerp_angle(upper.rotation.z, -0.65 if dashing else (-0.12 if absf(speed) > 0.1 else 0.0), blend)

func set_uniform(tint: Color) -> void:
	upper.get_child(0).material_override.albedo_color = tint
	upper.get_child(2).material_override.albedo_color = tint.darkened(0.2)
	upper.get_child(4).material_override.albedo_color = tint.darkened(0.35)
	for leg in legs:
		leg.get_child(0).material_override.albedo_color = tint.darkened(0.35)
	for shin in shins:
		shin.material_override.albedo_color = tint.darkened(0.35)
	for arm in arms:
		arm.get_child(0).material_override.albedo_color = tint

func reset_pose() -> void:
	cycle = 0
	upper.rotation = Vector3.ZERO
	landing = 0
	was_airborne = false
	for leg in legs:
		leg.position.y = 0.75
	for limb in legs + knees + arms:
		limb.rotation = Vector3.ZERO
	upper.position.y = 1.15
