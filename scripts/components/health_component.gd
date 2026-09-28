class_name HealthComponent
extends Node
signal died
signal changed
var max_health := 3.0
var current_health := 3.0
var invulnerability := 0.0
var mercy_time := 0.0
func reset(value: float) -> void:
	max_health = value
	current_health = value
	invulnerability = 0
	changed.emit()
func _physics_process(delta: float) -> void:
	invulnerability = maxf(0, invulnerability - delta)
func take_damage(amount: float, source: Node = null) -> bool:
	if amount <= 0 or current_health <= 0 or invulnerability > 0:
		return false
	current_health = maxf(0, current_health - amount)
	invulnerability = mercy_time
	EventBus.damage_received.emit(get_parent(), amount)
	changed.emit()
	if current_health <= 0:
		died.emit()
	return true
