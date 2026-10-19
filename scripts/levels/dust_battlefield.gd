class_name DustBattlefield
extends Node3D
const CONCRETE := Color(0.52, 0.48, 0.37)
const BRICK := Color(0.42, 0.23, 0.15)
const STEEL := Color(0.18, 0.16, 0.13)
const SAND := Color(0.54, 0.43, 0.26)
var terminals: Array[Node3D] = []
var rng := RandomNumberGenerator.new()
var foreground: Node3D
var utility: Node3D
var city: Node3D
var cover: Node3D
var road: Node3D
var terrain: Node3D
var ground_material: ShaderMaterial
func layer(title: String) -> Node3D:
	var node := Node3D.new()
	node.name = title
	add_child(node)
	return node
func block(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mesh := ModelFactory.world_box(parent, size, pos, color)
	mesh.visibility_range_end = 95
	mesh.visibility_range_end_margin = 10
	return mesh
func build(data: LevelData) -> void:
	name = "DustBattalion"
	rng.seed = 4001 + GameManager.mission * 97
	foreground = layer("ForegroundClutter")
	road = layer("PlayableRoad")
	cover = layer("HeroCover")
	utility = layer("MidgroundUtilities")
	city = layer("BackgroundCityscape")
	terrain = layer("BackgroundTerrain")
	build_background_ground(data.length)
	# Visual road extends toward camera so the lower frame never falls into sky.
	var asphalt := block(road, Vector3(data.length + 35, 0.18, 40), Vector3(data.length / 2, -0.11, 15), Color(0.24, 0.25, 0.25))
	var asphalt_material := ground_material.duplicate() as ShaderMaterial
	asphalt_material.set_shader_parameter("asphalt", true)
	asphalt_material.set_shader_parameter("earth_color", Color(0.23, 0.24, 0.24))
	asphalt.material_override = asphalt_material
	for x in range(-12, int(data.length) + 15, 3):
		block(road, Vector3(2.75, 0.28, 0.65), Vector3(x, 0.02, -2), CONCRETE)
		if x % 6 == 0:
			block(road, Vector3(1.8, 0.018, 0.12), Vector3(x, 0.022, 1.8), Color(0.65, 0.46, 0.19))
		crack(Vector3(x + rng.randf_range(-1, 1), 0.015, rng.randf_range(-0.8, 4.5)))
		if x % 9 == 0:
			trap(foreground, Vector3(x + 2, 0.5, 4.1), 0.85)
			supply(foreground, Vector3(x - 1.0, 0.26, 4.2))
			for j in 3:
				var stone := block(road, Vector3(0.22, 0.10, 0.18), Vector3(x + j * 0.8, 0.06, 0.7), CONCRETE)
				stone.rotation.y = j * 0.7
			for i in 4:
				var rubble := block(foreground, Vector3(rng.randf_range(0.3, 0.8), rng.randf_range(0.2, 0.6), 0.5), Vector3(x + i * 0.55, 0.2, 4.2), BRICK.darkened(0.35))
				rubble.rotation = Vector3(0.1, rng.randf(), rng.randf_range(-0.3, 0.3))
	for x in range(-8, int(data.length) + 20, 14):
		facade(float(x), -11.5, rng.randf_range(5.5, 9.5), false)
		facade(float(x + 5), -24, rng.randf_range(7, 14), true)
		streetlight(float(x + 6))
		pole(float(x))
		cable(float(x), float(x + 14))
		brick_wall(Vector3(x + 5, 0, -3.6))
		sandbags(utility, Vector3(x + 9, 0, -2.6), 4)
		trap(utility, Vector3(x + 2, 0.7, -3.1), 1.1)
		wire(Vector3(x + 8, 0.7, -3.8))
		if x % 28 == 6:
			tower(Vector3(x + 9, 0, -18))
		for i in 4:
			block(utility, Vector3(0.3, 0.2, 0.28), Vector3(x + i * 0.4, 0.1, -2.5), CONCRETE)
	for i in data.platform_positions.size():
		bunker(data.platform_positions[i], data.platform_sizes[i])
	embers(data.length)
func crack(origin: Vector3) -> void:
	var point := origin
	for i in 4:
		var next := point + Vector3(rng.randf_range(0.25, 0.6), 0, rng.randf_range(-0.6, 0.6))
		ModelFactory.rod(road, point, next, 0.025, Color(0.065, 0.06, 0.05))
		if i == 2:
			ModelFactory.rod(road, point, point + Vector3(-0.4, 0, 0.55), 0.018, Color(0.07, 0.06, 0.05))
		point = next
func facade(x: float, z: float, height: float, distant: bool) -> void:
	var parent := Node3D.new()
	city.add_child(parent)
	parent.position = Vector3(x, 0, z)
	# A plinth and broad apron tie each facade to the continuous city terrain.
	block(parent, Vector3(6.25, 0.45, 2.75), Vector3(0, -0.10, 0), CONCRETE.darkened(0.25))
	block(parent, Vector3(6.7, 0.16, 1.5), Vector3(0, 0.02, 1.85), CONCRETE.darkened(0.12))
	var color := Color(0.46, 0.31, 0.21) if distant else Color(0.53, 0.38, 0.26)
	block(parent, Vector3(5.8, height - 0.6, 2.3), Vector3(0, (height - 0.6) / 2, 0), color)
	for i in 3:
		var roof_height := 0.3 + float(i % 2) * 0.4
		block(parent, Vector3(1.85, roof_height, 2.25), Vector3(-1.9 + i * 1.9, height - 0.6 + roof_height / 2, 0), color)
	if not distant:
		for row in 3:
			for col in 3 - row:
				block(parent, Vector3(0.48, 0.22, 0.10), Vector3(-2.55 + col * 0.5, 0.2 + row * 0.25, 1.2), BRICK)
		ModelFactory.rod(parent, Vector3(2.1, 3.0, 1.22), Vector3(1.8, 3.5, 1.22), 0.025, STEEL)
		ModelFactory.rod(parent, Vector3(1.8, 3.5, 1.22), Vector3(2.0, 4.2, 1.22), 0.025, STEEL)
	for y in range(1, int(height), 2):
		block(parent, Vector3(6.0, 0.12, 2.45), Vector3(0, y - 0.65, 0), color.darkened(0.15))
		for wx in [-1.8, 0.0, 1.8]:
			block(parent, Vector3(1.12, 1.35, 0.16), Vector3(wx, y + 0.15, 1.22), color.lightened(0.08))
			block(parent, Vector3(0.83, 1.08, 0.05), Vector3(wx, y + 0.17, 1.32), Color(0.11, 0.085, 0.065))
			block(parent, Vector3(1.2, 0.13, 0.35), Vector3(wx, y - 0.48, 1.3), CONCRETE.darkened(0.2))
			if rng.randf() > 0.6:
				var shutter := block(parent, Vector3(0.15, 1.1, 0.10), Vector3(wx, y + 0.1, 1.37), BRICK.darkened(0.3))
				shutter.rotation.z = 0.3
	block(parent, Vector3(6.1, 0.28, 2.5), Vector3(0, height, 0), color.darkened(0.2))
	for i in 3:
		var broken_roof := block(parent, Vector3(0.6 + i * 0.25, 0.3 + i * 0.18, 0.6), Vector3(-2.3 + i * 0.7, height + i * 0.10, 0.7), color.darkened(0.12))
		broken_roof.rotation.z = -0.12 + i * 0.1
	for i in 4:
		block(parent, Vector3(0.1, rng.randf_range(0.3, 0.85), 0.1), Vector3(-2 + i, height + 0.3, 0.5), STEEL)
	block(parent, Vector3(0.7, 3.5, 0.7), Vector3(1.5, height + 1.5, -0.4), BRICK.darkened(0.3))
	if distant:
		smoke(parent, Vector3(1.5, height + 3.2, -0.4))
func brick_wall(pos: Vector3) -> void:
	for row in 4:
		for col in (5 - row):
			block(utility, Vector3(0.64, 0.28, 0.32), pos + Vector3(col * 0.68 + (row % 2) * 0.33, 0.17 + row * 0.32, 0), BRICK.lightened(rng.randf_range(-0.08, 0.08)))
	for i in 3:
		ModelFactory.rod(utility, pos + Vector3(i * 0.4, 1.0, 0), pos + Vector3(i * 0.4 - 0.1, 1.65, 0), 0.04, STEEL)
func trap(parent: Node3D, pos: Vector3, size: float) -> void:
	for angle in [-0.75, 0.75]:
		var beam := block(parent, Vector3(0.16, size * 2, 0.18), pos, STEEL)
		beam.rotation.z = angle
	var cross := block(parent, Vector3(0.15, 0.15, size * 1.6), pos, STEEL)
	cross.rotation.y = 0.35
func sandbags(parent: Node3D, pos: Vector3, count: int) -> void:
	for row in 3:
		for i in count - row:
			var bag := ModelFactory.sphere(parent, 0.36, pos + Vector3(i * 0.63 + row * 0.28, 0.18 + row * 0.30, 0), SAND)
			bag.scale = Vector3(1.1, 0.48, 0.72)
			bag.material_override = ModelFactory.material(SAND.lightened(rng.randf_range(-0.06, 0.06)))
func supply(parent: Node3D, pos: Vector3) -> void:
	block(parent, Vector3(0.85, 0.55, 0.65), pos, Color(0.25, 0.29, 0.12))
	for x in [-0.26, 0.26]:
		block(parent, Vector3(0.07, 0.60, 0.7), pos + Vector3(x, 0, 0), Color(0.14, 0.17, 0.08))
	block(parent, Vector3(0.28, 0.08, 0.02), pos + Vector3(0, 0, 0.34), Color(0.68, 0.57, 0.26))
func bunker(pos: Vector3, size: Vector3) -> void:
	var root := Node3D.new()
	cover.add_child(root)
	root.position = Vector3(pos.x, 0, 0)
	var top := pos.y + size.y / 2
	# Cladding fills beneath the existing authored collision platform.
	block(root, Vector3(size.x - 0.12, maxf(0.2, pos.y - size.y / 2), size.z - 0.1), Vector3(0, (pos.y - size.y / 2) / 2, -0.04), CONCRETE)
	for side in [-1.0, 1.0]:
		for row in 3:
			for col in (3 - row):
				block(root, Vector3(0.45, 0.22, 0.12), Vector3(side * (size.x / 2 - 0.3 - col * 0.47), 0.15 + row * 0.25, size.z / 2), BRICK)
		block(root, Vector3(0.38, 2.65, 0.6), Vector3(side * (size.x / 2 - 0.4), top + 1.3, -0.8), CONCRETE)
	block(root, Vector3(size.x + 0.12, 0.42, 0.7), Vector3(0, top + 2.7, -0.8), CONCRETE.lightened(0.10))
	for side in [-1.0, 1.0]:
		sandbags(root, Vector3(side * (size.x / 2 + 0.2), 0, 0.7), 3)
	supply(root, Vector3(-0.6, 0.28, 1.9))
	supply(root, Vector3(0.35, 0.30, 1.85))
	var terminal := Node3D.new()
	terminal.name = "SupplyTerminal"
	root.add_child(terminal)
	terminal.position = Vector3(-0.65, top, -0.25)
	terminals.append(terminal)
	var prompt := Label3D.new()
	prompt.name = "InteractionPrompt"
	prompt.text = "E / Y • SUPPLY TERMINAL"
	prompt.font_size = 22
	prompt.pixel_size = 0.008
	prompt.position = Vector3(0, 1.65, 0)
	prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	terminal.add_child(prompt)
	block(terminal, Vector3(0.9, 0.6, 0.65), Vector3(0, 0.3, 0), Color(0.18, 0.24, 0.12))
	var head := block(terminal, Vector3(1, 0.8, 0.55), Vector3(0, 0.95, -0.06), Color(0.15, 0.24, 0.13))
	head.rotation.x = -0.12
	var screen := ModelFactory.box(terminal, Vector3(0.75, 0.51, 0.04), Vector3(0, 0.98, 0.25), Color(0.05, 0.7, 0.18))
	screen.material_override = ModelFactory.material(Color(0.025, 0.40, 0.07), 1.6)
	for i in 4:
		var line := ModelFactory.box(terminal, Vector3(0.5 - i * 0.07, 0.025, 0.012), Vector3(-0.05, 1.13 - i * 0.10, 0.28), Color(0.3, 1, 0.4))
		line.material_override = ModelFactory.material(Color(0.18, 0.75, 0.25), 1.7)
	var light := OmniLight3D.new()
	terminal.add_child(light)
	light.position = Vector3(0, 1.0, 0.5)
	light.light_color = Color(0.1, 1, 0.3)
	light.light_energy = 1.4
	light.omni_range = 3
func pole(x: float) -> void:
	block(utility, Vector3(0.18, 6.6, 0.22), Vector3(x, 3.3, -3.3), Color(0.24, 0.17, 0.1))
	block(utility, Vector3(1.15, 0.13, 0.18), Vector3(x, 6.3, -3.3), STEEL)
	for y in [1.0, 2.0, 3.0, 4.0]:
		block(utility, Vector3(0.45, 0.05, 0.2), Vector3(x, y, -3.2), STEEL)
func cable(a: float, b: float) -> void:
	for offset in [-0.22, 0.0, 0.22]:
		var path := Path3D.new()
		path.name = "CatenaryCable"
		path.curve = Curve3D.new()
		utility.add_child(path)
		var previous := Vector3(a, 6.3 + offset, -3.3 + offset)
		for i in 17:
			var t := float(i) / 16
			var point := Vector3(lerpf(a, b, t), 6.3 + offset - 1.0 * (1.0 - pow(2.0 * t - 1.0, 2)), -3.3 + offset)
			path.curve.add_point(point)
			if i > 0:
				ModelFactory.rod(path, previous, point, 0.026, STEEL)
			previous = point
func wire(pos: Vector3) -> void:
	var previous := pos
	for i in 48:
		var t := float(i) / 47
		var point := pos + Vector3(t * 4, sin(t * TAU * 5) * 0.35, cos(t * TAU * 5) * 0.22)
		if i > 0:
			ModelFactory.rod(utility, previous, point, 0.018, STEEL)
		previous = point
func streetlight(x: float) -> void:
	block(utility, Vector3(0.12, 5.0, 0.14), Vector3(x, 2.5, -2.8), STEEL)
	block(utility, Vector3(0.65, 0.12, 0.35), Vector3(x - 0.2, 5, -2.8), STEEL)
	var spot := SpotLight3D.new()
	utility.add_child(spot)
	spot.position = Vector3(x - 0.2, 4.9, -2.7)
	spot.rotation_degrees.x = -90
	spot.light_color = Color(1, 0.77, 0.43)
	spot.light_energy = 4
	spot.spot_range = 7
	spot.spot_angle = 25
	var bulb := ModelFactory.box(utility, Vector3(0.4, 0.06, 0.28), spot.position, Color(1, 0.85, 0.55))
	bulb.material_override = ModelFactory.material(Color(1, 0.85, 0.55), 3)
	var cone := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius = 0.06
	shape.bottom_radius = 1.5
	shape.height = 4.7
	shape.radial_segments = 24
	cone.mesh = shape
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/streetlight_cone.gdshader")
	cone.material_override = mat
	cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	utility.add_child(cone)
	cone.position = Vector3(x - 0.2, 2.5, -2.7)
func tower(pos: Vector3) -> void:
	for side in [-1.0, 1.0]:
		ModelFactory.rod(city, pos + Vector3(side, 0, 0), pos + Vector3(side * 0.65, 6, 0), 0.16, STEEL)
		for y in [0.0, 2.0, 4.0]:
			ModelFactory.rod(city, pos + Vector3(-1, y, 0), pos + Vector3(1, y + 2, 0), 0.09, STEEL)
			ModelFactory.rod(city, pos + Vector3(1, y, 0), pos + Vector3(-1, y + 2, 0), 0.09, STEEL)
	block(city, Vector3(2.4, 0.2, 2), pos + Vector3(0, 6, 0), STEEL)
	block(city, Vector3(2.6, 0.24, 2.2), pos + Vector3(0, 7.8, 0), STEEL)
	for x in [-0.9, 0.9]:
		block(city, Vector3(0.12, 1.8, 0.12), pos + Vector3(x, 6.9, 0.7), STEEL)
func embers(length: float) -> void:
	var particles := GPUParticles3D.new()
	particles.name = "FloatingAsh"
	add_child(particles)
	particles.amount = 180
	particles.lifetime = 8
	particles.preprocess = 4
	particles.position = Vector3(length / 2, 3, -1)
	particles.visibility_aabb = AABB(Vector3(-length / 2 - 10, -5, -8), Vector3(length + 20, 20, 16))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(length / 2, 5, 5)
	process.direction = Vector3(1, 0.7, 0)
	process.spread = 25
	process.initial_velocity_min = 0.35
	process.initial_velocity_max = 0.8
	process.gravity = Vector3(0, 0.05, 0)
	process.scale_min = 0.025
	process.scale_max = 0.06
	particles.process_material = process
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1
	mesh.radial_segments = 6
	mesh.rings = 3
	mesh.material = ModelFactory.material(Color(1, 0.45, 0.1), 3)
	particles.draw_pass_1 = mesh
func use_terminal(actor: Node3D) -> bool:
	for terminal in terminals:
		if actor.global_position.distance_to(terminal.global_position) < 2.2:
			GameManager.level.banner = "SUPPLY TERMINAL • RELOAD REQUESTED"
			GameManager.level.banner_time = 2
			actor.start_reload()
			AudioManager.play("pickup")
			return true
	return false

func smoke(parent: Node3D, pos: Vector3) -> void:
	var particles := GPUParticles3D.new()
	parent.add_child(particles)
	particles.name = "ChimneySmoke"
	particles.position = pos
	particles.amount = 12
	particles.lifetime = 9
	particles.preprocess = 5
	particles.visibility_aabb = AABB(Vector3(-8, -2, -5), Vector3(16, 20, 10))
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(-0.4, 1, 0)
	process.spread = 12
	process.initial_velocity_min = 0.6
	process.initial_velocity_max = 0.9
	process.gravity = Vector3(-0.05, 0.1, 0)
	process.scale_min = 1
	process.scale_max = 2.3
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.18, 0.14, 0.12, 0.22))
	gradient.set_color(1, Color(0.3, 0.24, 0.2, 0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = gradient
	process.color_ramp = ramp
	particles.process_material = process
	var mesh := SphereMesh.new()
	mesh.radius = 0.65
	mesh.height = 1.3
	mesh.radial_segments = 8
	mesh.rings = 4
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = mat
	particles.draw_pass_1 = mesh

func _process(_delta: float) -> void:
	var actor = GameManager.player
	for terminal in terminals:
		terminal.get_node("InteractionPrompt").visible = is_instance_valid(actor) and actor.global_position.distance_to(terminal.global_position) < 2.2

func build_background_ground(length: float) -> void:
	var noise := FastNoiseLite.new()
	noise.seed = 9301
	noise.frequency = 0.08
	noise.fractal_octaves = 4
	var image := Image.create(256, 256, false, Image.FORMAT_RGB8)
	for y in 256:
		for x in 256:
			# Periodic sampling keeps the texture repeat seam-free.
			var u := float(x) / 256.0 * TAU
			var v := float(y) / 256.0 * TAU
			var value := 0.5 + noise.get_noise_3d(cos(u) * 30, sin(u) * 30, cos(v) * 30) * 0.35
			value += sin(v * 19 + sin(u * 7)) * 0.025
			image.set_pixel(x, y, Color(value, value, value))
	image.generate_mipmaps()
	ground_material = ShaderMaterial.new()
	ground_material.shader = load("res://shaders/battlefield_ground.gdshader")
	ground_material.set_shader_parameter("surface_map", ImageTexture.create_from_image(image))
	for start_x in range(-24, int(length) + 24, 16):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		# One-metre subdivisions with shallow, deterministic terrain relief.
		for z in 38:
			for x in 16:
				for offset in [Vector2i(0,0), Vector2i(1,1), Vector2i(1,0), Vector2i(0,0), Vector2i(0,1), Vector2i(1,1)]:
					var px := float(start_x + x + offset.x)
					var pz := -2.0 - float(z + offset.y)
					var height := -0.07 + noise.get_noise_2d(px * 0.55, pz * 0.55) * 0.16
					st.set_uv(Vector2(px, pz) * 0.2)
					st.add_vertex(Vector3(px, height, pz))
		st.generate_normals()
		st.generate_tangents()
		st.index()
		var chunk := MeshInstance3D.new()
		chunk.name = "TerrainChunk%d" % start_x
		chunk.mesh = st.commit()
		chunk.material_override = ground_material
		terrain.add_child(chunk)
	# A rear service road and tiled verges bridge the utility layer and facades.
	for x in range(-18, int(length) + 24, 3):
		for z in [-8.7, -21.2]:
			var slab := block(terrain, Vector3(2.85, 0.18, 1.1), Vector3(x, 0.025, z), CONCRETE.darkened(0.18))
			slab.material_override = ground_material
		if x % 6 == 0:
			block(terrain, Vector3(1.2, 0.015, 0.10), Vector3(x, 0.055, -6), Color(0.55, 0.42, 0.22))
		for i in 2:
			var debris := block(terrain, Vector3(0.32, 0.18, 0.25), Vector3(x + i * 0.5, 0.1, -7.4), CONCRETE.darkened(0.23))
			debris.rotation.y = float(x + i) * 0.35
