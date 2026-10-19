extends Node3D
var camera: Camera3D
var shake := 0.0
var shake_time := 0.0
var frontier := 10.0
var lock_x := -1.0
var max_x := 115.0
var min_x := 10.0
var vertical_bounds := Vector2(0, 6)
var half_width := 15.0
var base_fov := 32.0
var base_size := 12.5
var authored_half_width := 15.0
var encounter_blend := 0.0
var intro_remaining := 0.0
var intro_duration := 2.5
func _ready() -> void:
	camera = Camera3D.new()
	add_child(camera)
	camera.position = Vector3(0, 6.5, 20)
	camera.rotation_degrees.x = -9
	camera.fov = base_fov
	camera.current = true
	position.x = 10
	EventBus.shake_requested.connect(func(intensity: float, duration: float):
		shake = maxf(shake, intensity)
		shake_time = duration)
func _physics_process(delta: float) -> void:
	if not is_instance_valid(GameManager.player):
		return
	var player := GameManager.player
	frontier = maxf(frontier, player.position.x + player.facing * 2.0)
	var target := clampf(frontier, min_x, max_x)
	if lock_x >= 0:
		target = clampf(lock_x, min_x, max_x)
	position.x = lerpf(position.x, target, 1 - exp(-5 * delta))
	var vertical_target := clampf(player.position.y - 2.0, vertical_bounds.x, vertical_bounds.y)
	position.y = lerpf(position.y, vertical_target, 1 - exp(-3 * delta))
	intro_remaining = maxf(0, intro_remaining - delta)
	var progress := 1.0 - intro_remaining / intro_duration
	var zoom := sin(progress * PI) if intro_remaining > 0 else 0.0
	var level = GameManager.level
	var boss_visible: bool = is_instance_valid(level) and is_instance_valid(level.boss) and level.boss.active
	encounter_blend = move_toward(encounter_blend, 1.0 if boss_visible else 0.0, delta * 1.5)
	camera.fov = base_fov + encounter_blend * 8.0 - zoom * 4.0
	camera.size = base_size + encounter_blend * 3.0 - zoom * 1.5
	update_visible_bounds()
	player.position.x = clampf(player.position.x, position.x - half_width, position.x + half_width)
	shake_time -= delta
	if shake_time <= 0:
		shake = move_toward(shake, 0, delta)
	camera.h_offset = randf_range(-shake, shake)
	camera.v_offset = randf_range(-shake, shake)

func configure(data: LevelData) -> void:
	min_x = data.camera_bounds.x
	max_x = maxf(min_x, data.camera_bounds.y)
	vertical_bounds = data.camera_vertical_bounds
	authored_half_width = data.camera_player_half_width
	encounter_blend = 0.0
	base_fov = data.camera_fov
	base_size = data.camera_ortho_size
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL if data.camera_projection == "orthographic" else Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = base_fov
	camera.size = base_size
	frontier = min_x
	position.x = min_x
	update_visible_bounds()

func start_boss_intro(duration := 2.5) -> void:
	intro_duration = maxf(duration, 0.01)
	intro_remaining = intro_duration

func update_visible_bounds() -> void:
	# Use the projected lane, including aspect ratio, instead of the former fixed 15m clamp.
	var viewport_size := camera.get_viewport().get_visible_rect().size
	var y := viewport_size.y * 0.75
	var left := camera.project_position(Vector2(0, y), camera.position.z)
	var right := camera.project_position(Vector2(viewport_size.x, y), camera.position.z)
	half_width = minf(authored_half_width, maxf(2.0, (right.x - left.x) * 0.5 - 0.8))
