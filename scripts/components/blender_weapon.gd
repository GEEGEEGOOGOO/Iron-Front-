class_name BlenderWeapon
extends Node3D
## Portable Blender meshes; gameplay remains owned by Player and Combat.
const PATHS := {
	"pistol": "res://assets/models/weapons/pistol.glb",
	"shotgun": "res://assets/models/weapons/shotgun.glb",
	"flame": "res://assets/models/weapons/flame.glb",
}
var kind := ""
var action_part: Node3D
var trigger: Node3D
var action_home := Vector3.ZERO
var action_tween: Tween
var trigger_tween: Tween
var plume: GPUParticles3D
var fire_hold := 0.0
var fuel_lights: Array[MeshInstance3D] = []

func configure(weapon_kind: String) -> void:
	kind = weapon_kind
	name = "BlenderWeapon"
	var packed := load(PATHS[kind]) as PackedScene
	var model := packed.instantiate() as Node3D
	add_child(model)
	# glTF is Y-up. Align authored bore with the game's existing muzzle marker.
	model.position.y = {"pistol": -0.2633, "shotgun": -0.0645, "flame": -0.2179}[kind]
	set_meta("blender_asset", PATHS[kind])
	action_part = model.find_child("Slide*" if kind == "pistol" else "Pump*", true, false) as Node3D
	if action_part:
		action_home = action_part.position
	var blade := model.find_child("Trigger*", true, false) as Node3D
	if blade:
		trigger = Node3D.new()
		trigger.name = "TriggerPivot"
		model.add_child(trigger)
		trigger.position = {"pistol": Vector3(0.34, 0.10, 0), "shotgun": Vector3(-0.024, -0.158, 0), "flame": Vector3(0.102, 0.035, 0)}[kind]
		blade.reparent(trigger, false)
		blade.position = -trigger.position
	if kind == "flame":
		build_plume()
		build_fuel_gauge()

func fire() -> void:
	if trigger:
		if trigger_tween:
			trigger_tween.kill()
		trigger.rotation.z = -0.22
		trigger_tween = create_tween()
		trigger_tween.tween_property(trigger, "rotation:z", 0.0, 0.12)
	if action_part:
		if action_tween:
			action_tween.kill()
		action_tween = create_tween()
		var stroke := 0.055 if kind == "pistol" else 0.11
		if kind == "shotgun":
			action_tween.tween_interval(0.10)
		action_tween.tween_property(action_part, "position", action_home - Vector3(stroke, 0, 0), 0.035 if kind == "pistol" else 0.09)
		action_tween.tween_property(action_part, "position", action_home, 0.09 if kind == "pistol" else 0.13)
	if plume:
		fire_hold = 0.13
		if not plume.emitting:
			plume.emitting = true

func set_ammo(rounds: int, capacity: int, reloading: bool) -> void:
	for i in fuel_lights.size():
		var lit := float(i) / fuel_lights.size() < float(rounds) / maxi(capacity, 1)
		var material := fuel_lights[i].material_override as StandardMaterial3D
		material.albedo_color = Color(0.05, 0.5, 1) if reloading else (Color(0.1, 0.9, 0.25) if lit else Color(0.02, 0.035, 0.025))
		material.emission_enabled = reloading or lit
		material.emission = material.albedo_color

func _process(delta: float) -> void:
	fire_hold = maxf(0, fire_hold - delta)
	if plume:
		# Stopping emission leaves the existing waves alive until they dissipate.
		var should_emit := fire_hold > 0 and is_visible_in_tree()
		if plume.emitting != should_emit:
			plume.emitting = should_emit

func build_plume() -> void:
	plume = GPUParticles3D.new()
	plume.name = "FiniteFlamePlume"
	plume.position = Vector3(1.2, 0, 0)
	plume.emitting = false
	plume.amount = 72
	plume.lifetime = 0.48
	plume.local_coords = false
	plume.visibility_aabb = AABB(Vector3(-5, -3, -2), Vector3(10, 6, 4))
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3.RIGHT
	process.spread = 12
	process.initial_velocity_min = 5.5
	process.initial_velocity_max = 7.0
	process.gravity = Vector3(0, 0.9, 0)
	process.scale_min = 0.16
	process.scale_max = 0.28
	var growth := Curve.new()
	growth.add_point(Vector2(0, 0.2))
	growth.add_point(Vector2(0.7, 1.6))
	growth.add_point(Vector2(1, 1.8))
	var growth_texture := CurveTexture.new()
	growth_texture.curve = growth
	process.scale_curve = growth_texture
	var colors := Gradient.new()
	colors.offsets = PackedFloat32Array([0, 0.15, 0.5, 1])
	colors.colors = PackedColorArray([Color(0.2, 0.5, 1, 0.3), Color(1, 0.9, 0.2, 0.9), Color(1, 0.3, 0.02, 0.7), Color(0.8, 0.06, 0, 0)])
	var ramp := GradientTexture1D.new()
	ramp.gradient = colors
	process.color_ramp = ramp
	plume.process_material = process
	var mesh := QuadMesh.new()
	mesh.size = Vector2(1.8, 0.8)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.albedo_texture = load("res://assets/models/weapons/flame_particle.svg")
	material.no_depth_test = false
	mesh.material = material
	plume.draw_pass_1 = mesh
	add_child(plume)

func build_fuel_gauge() -> void:
	for i in 8:
		var light := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.018, 0.022, 0.012)
		light.mesh = mesh
		light.position = Vector3(-0.03 + i * 0.024, 0.22, 0.128)
		var material := StandardMaterial3D.new()
		material.emission_energy_multiplier = 1.4
		light.material_override = material
		add_child(light)
		fuel_lights.append(light)
