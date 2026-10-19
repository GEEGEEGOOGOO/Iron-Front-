class_name MissionBattlefield
extends DustBattlefield
## Modular 3D scenery for the laboratory and foundry missions.
var foundry := false
var doors: Array[StaticBody3D] = []
var powered: Array[bool] = []
var door_tweens: Dictionary = {}
const LAB := Color(0.56, 0.59, 0.56)
const IRON := Color(0.13, 0.17, 0.22)
const SAFETY := Color(0.72, 0.51, 0.12)

func build(data: LevelData) -> void:
	foundry = data.theme == "foundry"
	name = "MidnightFoundry" if foundry else "OperationAshfall"
	foreground = layer("ForegroundClutter")
	road = layer("PlayableRoad")
	cover = layer("HeroCover")
	utility = layer("MidgroundUtilities")
	city = layer("BackgroundCityscape")
	terrain = layer("BackgroundTerrain")
	build_background_ground(data.length)
	ground_material.set_shader_parameter("earth_color", Color(0.12,0.16,0.21) if foundry else Color(0.34,0.37,0.37))
	block(road, Vector3(data.length+35,0.16,40), Vector3(data.length/2,-0.12,15), IRON if foundry else LAB.darkened(0.5))
	for x in range(-10,int(data.length)+20,16):
		if foundry:
			furnace(Vector3(x,0,-9))
			gantry(Vector3(x+7,0,-6))
			coils(Vector3(x+5,0,-3.8))
			pipework(Vector3(x-3,0,-5))
		else:
			laboratory(Vector3(x,0,-9))
			fence(Vector3(x+7,0,-4))
			generator(Vector3(x+5,0,-3.6))
			if x % 32 == 6:
				satellite(Vector3(x+2,6,-9))
		lamp(Vector3(x+4,4,-3), Color(1,0.57,0.2) if foundry else Color(0.65,0.86,1))
		block(road,Vector3(2,0.018,0.12),Vector3(x,0.01,1.5),SAFETY)
		# Distinct distant skylines rather than residential facades.
		var distant := Node3D.new()
		city.add_child(distant)
		distant.position = Vector3(x+4,0,-24)
		block(distant,Vector3(8,7,4),Vector3(0,3.5,0),IRON if foundry else LAB.darkened(0.2))
		if foundry:
			cylinder(distant,Vector3(1,9,0),0.55,8,IRON)
			glow(distant,Vector3(0.15,0.15,0.15),Vector3(1,13,0),Color.RED)
		else:
			ModelFactory.rod(distant,Vector3(0,7,0),Vector3(0,12,0),0.12,IRON)
			for y in [8,10,12]:
				block(distant,Vector3(1.7,0.12,0.12),Vector3(0,y,0),IRON)
	for i in data.platform_positions.size():
		platform_dressing(data.platform_positions[i],data.platform_sizes[i])
	# Side-alcove doors never block the mandatory combat lane.
	for x in [17.0,52.0,91.0]:
		interactive_station(Vector3(x,0,-1.4))

func cylinder(parent: Node3D,pos: Vector3,radius: float,height: float,color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius=radius;shape.bottom_radius=radius;shape.height=height;shape.radial_segments=16
	mesh.mesh=shape;mesh.material_override=ModelFactory.material(color)
	parent.add_child(mesh);mesh.position=pos
	return mesh

func glow(parent: Node3D,dimensions: Vector3,pos: Vector3,color: Color) -> MeshInstance3D:
	var mesh := block(parent,dimensions,pos,color)
	mesh.material_override=ModelFactory.material(color,2)
	return mesh

func lamp(pos: Vector3,color: Color) -> void:
	block(utility,Vector3(0.1,pos.y,0.1),Vector3(pos.x,pos.y/2,pos.z),IRON)
	glow(utility,Vector3(0.65,0.18,0.3),pos,color)
	# Limit local lights; emissive fixtures supply the rest of the visual rhythm.
	if int(pos.x)%32==10:
		var light := OmniLight3D.new()
		utility.add_child(light);light.position=pos;light.light_color=color;light.omni_range=9;light.light_energy=2

func laboratory(pos: Vector3) -> void:
	var node := Node3D.new();utility.add_child(node);node.position=pos;node.name="Laboratory"
	block(node,Vector3(10,0.4,5),Vector3(0,0.1,0),LAB)
	block(node,Vector3(10,5.8,0.4),Vector3(0,3,-2),LAB)
	block(node,Vector3(10.5,0.35,5),Vector3(0,5.8,0),LAB)
	for x in [-4.7,0,4.7]:
		block(node,Vector3(0.3,5.5,4.8),Vector3(x,3,0),LAB)
	for x in [-3.4,-1.5,1.6,3.4]:
		block(node,Vector3(1.4,0.8,0.7),Vector3(x,0.8,0.4),LAB.darkened(0.12))
		block(node,Vector3(1.6,0.12,0.9),Vector3(x,1.3,0.4),IRON)
		block(node,Vector3(0.65,0.5,0.25),Vector3(x,1.7,0.1),IRON)
		glow(node,Vector3(0.53,0.35,0.025),Vector3(x,1.72,0.24),Color(0.18,0.58,0.67))
	for x in [-3.2,2.4]:
		glow(node,Vector3(2.2,0.08,0.4),Vector3(x,5.5,0),Color(0.65,0.9,1))
	block(node,Vector3(0.9,2.2,0.65),Vector3(3.6,1.2,-0.8),IRON)
	for y in range(7):
		block(node,Vector3(0.7,0.15,0.04),Vector3(3.6,0.4+y*0.25,-0.45),IRON.lightened(0.15))
		glow(node,Vector3(0.06,0.05,0.02),Vector3(3.85,0.4+y*0.25,-0.42),Color(0.15,0.7,0.8))
	# Glass bays retain visibility of the instrument benches.
	var glass := StandardMaterial3D.new();glass.albedo_color=Color(0.25,0.6,0.65,0.15);glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;glass.roughness=0.2
	for x in [-2.4,2.4]:
		var window := block(node,Vector3(4.3,4.6,0.04),Vector3(x,3.1,2.3),LAB)
		window.material_override=glass
	generator(pos+Vector3(1,5.9,0))

func generator(pos: Vector3) -> void:
	block(utility,Vector3(2.6,1.35,1.3),pos+Vector3(0,0.7,0),Color(0.22,0.28,0.15))
	for i in 7:
		block(utility,Vector3(0.12,0.65,0.04),pos+Vector3(-0.9+i*0.18,0.8,0.67),IRON)
	glow(utility,Vector3(0.28,0.24,0.035),pos+Vector3(0.9,0.9,0.67),Color(0.1,0.65,0.7))

func satellite(pos: Vector3) -> void:
	block(utility,Vector3(0.3,1.8,0.3),pos+Vector3(0,0.9,0),IRON)
	var dish := cylinder(utility,pos+Vector3(0,2,0),1.15,0.15,LAB)
	dish.rotation.x=PI/3
	ModelFactory.rod(utility,pos+Vector3(0,2,0),pos+Vector3(0,2.8,1),0.08,IRON)

func pipework(pos: Vector3) -> void:
	for x in [0,1.4]:
		cylinder(utility,pos+Vector3(x,2,0),0.32,4,IRON.lightened(0.12))
		for y in [0.5,2.5,3.7]:
			cylinder(utility,pos+Vector3(x,y,0),0.40,0.12,SAFETY.darkened(0.3))
	var pipe := cylinder(utility,pos+Vector3(0.7,3.8,0),0.32,1.5,IRON.lightened(0.12))
	pipe.rotation.z=PI/2
	block(utility,Vector3(0.7,1.4,0.5),pos+Vector3(2.4,0.7,0),IRON)
	glow(utility,Vector3(0.45,0.25,0.03),pos+Vector3(2.4,1,0.27),Color(0.1,0.6,0.8))

func fence(pos: Vector3) -> void:
	for i in 7:
		block(utility,Vector3(0.07,2.4,0.07),pos+Vector3(i*0.6,1.2,0),IRON)
	for y in [0.6,1.2,1.8,2.4]:
		block(utility,Vector3(4,0.035,0.035),pos+Vector3(1.8,y,0),IRON)

func furnace(pos: Vector3) -> void:
	var node := Node3D.new();node.name="Furnace";utility.add_child(node);node.position=pos
	block(node,Vector3(8,7,3),Vector3(0,3.5,0),IRON)
	block(node,Vector3(4.7,3.4,0.1),Vector3(0,2,1.56),Color(0.035,0.025,0.02))
	glow(node,Vector3(4,2.7,0.08),Vector3(0,1.9,1.65),Color(1,0.24,0.015))
	for x in [-3,3]:
		cylinder(node,Vector3(x,5.3,0),0.4,8,IRON.lightened(0.1))
	for i in 6:
		block(node,Vector3(0.18,1,0.3),Vector3(-3+i*1.2,7.5,1.8),SAFETY)
	block(node,Vector3(7,0.12,0.15),Vector3(0,8,1.8),SAFETY)
	var light := OmniLight3D.new();node.add_child(light);light.position=Vector3(0,2.4,3);light.light_color=Color(1,0.3,0.04);light.omni_range=11;light.light_energy=2
	smoke(node,Vector3(3,9.5,0))

func gantry(pos: Vector3) -> void:
	for x in [-4,4]:
		block(utility,Vector3(0.35,8,0.5),pos+Vector3(x,4,0),IRON)
	block(utility,Vector3(9,0.5,0.6),pos+Vector3(0,8,0),SAFETY)
	ModelFactory.rod(utility,pos+Vector3(0,7.8,0),pos+Vector3(0,5.4,0),0.06,IRON)
	cylinder(utility,pos+Vector3(0,4.7,0),0.7,1.3,IRON)
	glow(utility,Vector3(1,0.08,0.9),pos+Vector3(0,5.35,0),Color(1,0.28,0.02))

func coils(pos: Vector3) -> void:
	for i in 3:
		var mesh := MeshInstance3D.new();var torus := TorusMesh.new()
		torus.inner_radius=0.28;torus.outer_radius=0.75;torus.rings=16;torus.ring_segments=8
		mesh.mesh=torus;mesh.material_override=ModelFactory.material(Color(0.27,0.3,0.32));utility.add_child(mesh)
		mesh.position=pos+Vector3(i*1.1,0.8,0);mesh.rotation.x=PI/2

func platform_dressing(pos: Vector3,dimensions: Vector3) -> void:
	for x in [-dimensions.x/2+0.15,dimensions.x/2-0.15]:
		block(cover,Vector3(0.16,pos.y,0.4),Vector3(pos.x+x,pos.y/2,-0.8),IRON if foundry else LAB)
	block(cover,Vector3(dimensions.x,0.08,0.1),pos+Vector3(0,1,-1.1),SAFETY)
	for x in [-dimensions.x/2+0.15,0,dimensions.x/2-0.15]:
		block(cover,Vector3(0.08,1,0.08),pos+Vector3(x,0.5,-1.1),SAFETY)

func interactive_station(pos: Vector3) -> void:
	var terminal := Node3D.new();terminal.name="DoorTerminal";add_child(terminal);terminal.position=pos
	block(terminal,Vector3(0.45,1.1,0.35),Vector3(-1,0.55,0),IRON)
	glow(terminal,Vector3(0.32,0.25,0.04),Vector3(-1,1,0.2),Color(0.2,0.7,0.8))
	var hint := Label3D.new();hint.name="InteractionPrompt";hint.text="E • OPEN / CLOSE";hint.font_size=20;hint.pixel_size=0.008;hint.position=Vector3(0,3,0);hint.billboard=BaseMaterial3D.BILLBOARD_ENABLED;terminal.add_child(hint)
	var door := StaticBody3D.new();terminal.add_child(door);door.position=Vector3(0,1.25,-1.2);door.collision_layer=1
	ModelFactory.collider(door,Vector3(1.5,2.5,0.2),Vector3.ZERO)
	block(door,Vector3(1.5,2.5,0.2),Vector3.ZERO,IRON if foundry else LAB.darkened(0.2))
	terminals.append(terminal);doors.append(door);powered.append(false)

func use_terminal(actor: Node3D) -> bool:
	for i in terminals.size():
		if actor.global_position.distance_to(terminals[i].global_position)<2.2:
			powered[i]=not powered[i]
			doors[i].collision_layer=0 if powered[i] else 1
			if door_tweens.has(i) and door_tweens[i].is_valid():
				door_tweens[i].kill()
			var tween := create_tween()
			door_tweens[i]=tween
			tween.tween_property(doors[i],"position:y",3.9 if powered[i] else 1.25,0.6)
			GameManager.level.banner="FURNACE ACCESS OPEN" if foundry and powered[i] else ("LAB ACCESS OPEN" if powered[i] else "ACCESS CLOSED")
			GameManager.level.banner_time=2
			return true
	return false
