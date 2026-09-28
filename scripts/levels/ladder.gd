class_name ClimbLadder
extends Node3D
@export var height := 5.0
func _ready() -> void:
	for x in [-0.38, 0.38]:
		ModelFactory.box(self, Vector3(0.08, height, 0.08), Vector3(x, height * 0.5, -0.25), Color(0.65, 0.57, 0.3))
	for i in int(height / 0.35):
		ModelFactory.box(self, Vector3(0.8, 0.06, 0.1), Vector3(0, 0.2 + i * 0.35, -0.25), Color(0.7, 0.62, 0.33))
	var hint := Label3D.new()
	hint.text = "↑ CLIMB • JUMP TO DISMOUNT"
	hint.position = Vector3(0, height + 1, 0)
	hint.font_size = 24
	hint.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(hint)
func contains(feet: Vector3) -> bool:
	return absf(feet.x - global_position.x) < 0.7 and feet.y >= global_position.y - 0.2 and feet.y <= global_position.y + height + 0.2
