extends Area3D
var kind := "machine_gun"
var elapsed := 0.0
var base_y := 0.0
var label: Label3D
func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	ModelFactory.collider(self, Vector3(1.5, 2, 1.5), Vector3.ZERO)
	ModelFactory.box(self, Vector3(0.65, 0.65, 0.65), Vector3.ZERO, Color(0.95, 0.67, 0.12))
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
