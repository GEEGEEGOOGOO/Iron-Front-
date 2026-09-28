extends CharacterBody3D
var rescued := false
var locked := false
var cage: StaticBody3D
var escape_time := 0.0
var model: Node3D
var label: Label3D
func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	ModelFactory.collider(self, Vector3(0.5, 1.8, 0.5), Vector3(0, 0.9, 0))
	model = ModelFactory.soldier(self, Color(0.8, 0.73, 0.52))
	label = Label3D.new()
	label.text = "POW • INTERACT / KNIFE"
	label.position.y = 2.6
	label.font_size = 28
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
func rescue() -> bool:
	if rescued or locked:
		return false
	rescued = true
	escape_time = 4
	label.text = "THANK YOU!"
	return true
func _physics_process(delta: float) -> void:
	if not rescued or not visible or GameManager.state != GameManager.State.PLAYING:
		return
	escape_time -= delta
	velocity = Vector3(-6, velocity.y - 25 * delta, 0)
	move_and_slide()
	position.z = 0
	model.pose(delta, velocity.x, -1, not is_on_floor())
	if escape_time <= 0:
		hide()
		set_physics_process(false)
