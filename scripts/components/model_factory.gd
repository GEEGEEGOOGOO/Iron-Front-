class_name ModelFactory
extends RefCounted
static func material(color: Color, glow := 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.82
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
	mat.rim_enabled = true
	mat.rim = 0.3
	mat.rim_tint = 0.5
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mat.next_pass = outline()
	if glow > 0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = glow
	return mat
static func box(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.mesh = beveled_mesh(size)
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

static func armored_machine(parent: Node3D) -> ArmoredVisual:
	var model := ArmoredVisual.new()
	parent.add_child(model)
	model.build()
	return model

# Shared monochrome surface maps retain per-instance tint and hit/fade materials.
static var surfaces: Dictionary = {}
static func surface(kind: String) -> Texture2D:
	if surfaces.has(kind):
		return surfaces[kind]
	var image := Image.create(64, 64, false, Image.FORMAT_RGB8)
	for y in 64:
		for x in 64:
			var u := float(x) / 63.0
			var v := float(y) / 63.0
			var value := 0.94 + sin(u * PI) * 0.035 + sin(v * PI) * 0.025
			if kind == "cloth":
				value -= 0.025 * sin(u * TAU * 2.0) * sin(v * TAU * 2.0)
			image.set_pixel(x, y, Color(value, value, value))
	image.generate_mipmaps()
	var texture := ImageTexture.create_from_image(image)
	surfaces[kind] = texture
	return texture

static func detail_box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, kind := "metal") -> MeshInstance3D:
	var mesh := box(parent, size, pos, color)
	var mat := mesh.material_override as StandardMaterial3D
	mat.albedo_texture = surface(kind)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mat.roughness = 0.96 if kind == "cloth" else 0.66
	mat.metallic = 0.0 if kind == "cloth" else 0.25
	return mesh

static func rod(parent: Node3D, a: Vector3, b: Vector3, width: float, color: Color) -> MeshInstance3D:
	var mesh := detail_box(parent, Vector3(width, a.distance_to(b), width), (a + b) * 0.5, color)
	mesh.quaternion = Quaternion(Vector3.UP, (b - a).normalized())
	return mesh

static func wheel(parent: Node3D, pos: Vector3, radius: float) -> void:
	var mesh := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = 0.13
	shape.radial_segments = 10
	mesh.mesh = shape
	mesh.material_override = material(Color(0.19, 0.23, 0.21))
	parent.add_child(mesh)
	mesh.position = pos
	mesh.rotation.x = PI * 0.5
	detail_box(parent, Vector3(radius * 0.65, radius * 0.65, 0.16), pos, Color(0.4, 0.43, 0.35))

# World-space triplanar mapping keeps grain consistent on large and small blocks.
static var world_shader: Shader
static func world_box(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mesh := box(parent, size, pos, color)
	if not world_shader:
		world_shader = load("res://shaders/world_surface.gdshader")
	var mat := ShaderMaterial.new()
	mat.shader = world_shader
	mat.set_shader_parameter("tint", color)
	mat.set_shader_parameter("metal", color.b > color.r)
	mat.next_pass = outline()
	mesh.material_override = mat
	return mesh

static var bevels: Dictionary = {}
static var ink: ShaderMaterial
static func outline() -> ShaderMaterial:
	if not ink:
		ink = ShaderMaterial.new()
		ink.shader = load("res://shaders/ink_outline.gdshader")
	return ink

# Six planar center faces and a single chamfer ring, cached by dimensions.
# Render geometry is independent of the existing box collision shapes.
static func beveled_mesh(size: Vector3) -> ArrayMesh:
	if bevels.has(size):
		return bevels[size]
	var half := size * 0.5
	var radius := minf(0.10, minf(size.x, minf(size.y, size.z)) * 0.18)
	var inner := half - Vector3.ONE * radius
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for axis in 3:
		var u_axis := (axis + 1) % 3
		var v_axis := (axis + 2) % 3
		for sign_value in [-1.0, 1.0]:
			var us := [-half[u_axis], -inner[u_axis], inner[u_axis], half[u_axis]]
			var vs := [-half[v_axis], -inner[v_axis], inner[v_axis], half[v_axis]]
			for i in 3:
				for j in 3:
					var points: Array[Vector3] = []
					var normals: Array[Vector3] = []
					for corner in [Vector2i(i,j), Vector2i(i+1,j), Vector2i(i+1,j+1), Vector2i(i,j+1)]:
						var raw := Vector3.ZERO
						raw[axis] = half[axis] * sign_value
						raw[u_axis] = us[corner.x]
						raw[v_axis] = vs[corner.y]
						var core := raw.clamp(-inner, inner)
						var normal := (raw - core).normalized()
						points.append(core + normal * radius)
						normals.append(normal)
					# Godot front faces wind clockwise as seen from the outside.
					var order := [0, 2, 1, 0, 3, 2] if sign_value > 0 else [0, 1, 2, 0, 2, 3]
					for k in order:
						st.set_normal(normals[k])
						st.set_uv(Vector2(points[k][u_axis] / size[u_axis] + 0.5, points[k][v_axis] / size[v_axis] + 0.5))
						st.add_vertex(points[k])
	st.index()
	var result := st.commit()
	bevels[size] = result
	return result
