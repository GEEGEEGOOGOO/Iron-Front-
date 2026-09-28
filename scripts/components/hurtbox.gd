extends Area3D
func take_damage(amount: float, source: Node = null) -> bool:
	return get_parent().take_damage(amount, source)
