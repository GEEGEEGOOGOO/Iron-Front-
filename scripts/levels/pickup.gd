extends Area3D
var kind := "machine_gun"
var elapsed := 0.0
var base_y := 0.0
var label: Label3D
var model: MeshInstance3D
const COLORS := {
	"machine_gun": Color(0.95, 0.67, 0.12),
	"rocket": Color(0.84, 0.22, 0.14),
	"shotgun": Color(0.64, 0.67, 0.7),
	"flame": Color(1.0, 0.38, 0.08),
	"laser": Color(0.21, 0.82, 0.97),
	"health": Color(0.2, 0.86, 0.37),
	"grenades": Color(0.43, 0.58, 0.2),
}
const SCALES := {
	"machine_gun": Vector3(1.3, 0.7, 0.8),
	"rocket": Vector3(1.4, 0.65, 0.8),
	"shotgun": Vector3(1.1, 0.65, 0.8),
	"flame": Vector3(0.85, 1.25, 0.85),
	"laser": Vector3(1.35, 0.5, 0.65),
	"health": Vector3(0.85, 1.1, 0.85),
	"grenades": Vector3(0.8, 1.05, 0.8),
}
func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	ModelFactory.collider(self, Vector3(1.5, 2, 1.5), Vector3.ZERO)
	model = ModelFactory.box(self, Vector3(0.65, 0.65, 0.65), Vector3.ZERO, Color(0.95, 0.67, 0.12))
	label = Label3D.new()
	label.font_size = 64
	label.position = Vector3(0, 0.6, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
	body_entered.connect(collect)
func setup(pos: Vector3, item: String) -> void:
	kind = item
	position = pos
	base_y = pos.y
	elapsed = 0
	collision_layer = 128
	set_deferred("monitoring", true)
	label.text = {"machine_gun": "H", "rocket": "R", "shotgun": "S", "flame": "F", "laser": "L", "health": "+", "grenades": "G"}.get(kind, "?")
	model.scale = SCALES.get(kind, Vector3.ONE)
	model.material_override.albedo_color = COLORS.get(kind, Color(0.95, 0.67, 0.12))
func on_recycle() -> void:
	collision_layer = 0
	set_deferred("monitoring", false)
func _physics_process(delta: float) -> void:
	elapsed += delta
	position.y = base_y + sin(elapsed * 3) * 0.15
func collect(body: Node3D) -> void:
	if body != GameManager.player or not visible:
		return
	if kind == "health":
		body.health.current_health = minf(body.health.max_health, body.health.current_health + 1)
	elif kind == "grenades":
		body.grenades += 5
	else:
		body.equip(load("res://data/weapons/" + kind + ".tres"))
	AudioManager.play("pickup")
	EventBus.hud_changed.emit()
	hide()
	set_deferred("monitoring", false)
	PoolManager.call_deferred("release", self)
