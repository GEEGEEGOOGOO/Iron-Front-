class_name FreightElevator
extends AnimatableBody3D
@export var travel := 4.5
@export var speed := 1.8
@export var dwell := 1.2
var base_position := Vector3.ZERO
var ascending := true
var wait_time := 1.2
func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = true
	base_position = position
	ModelFactory.collider(self, Vector3(3, 0.35, 3), Vector3.ZERO)
	ModelFactory.box(self, Vector3(3, 0.35, 3), Vector3.ZERO, Color(0.38, 0.4, 0.36))
	for x in [-1.2, -0.6, 0, 0.6, 1.2]:
		ModelFactory.box(self, Vector3(0.25, 0.02, 3.05), Vector3(x, 0.185, 0), Color(0.95, 0.64, 0.13))
func _physics_process(delta: float) -> void:
	if GameManager.state != GameManager.State.PLAYING:
		return
	if wait_time > 0:
		wait_time -= delta
		return
	var target: float = base_position.y + (travel if ascending else 0)
	position.y = move_toward(position.y, target, speed * delta)
	if is_equal_approx(position.y, target):
		ascending = not ascending
		wait_time = dwell
