class_name RewardTable
extends Resource
@export var items := PackedStringArray(["health", "grenades", "rocket", "flame", "score", "life"])
@export var weights := PackedFloat32Array([3, 3, 2, 2, 2, 1])
@export var score_bonus := 1000
func choose(roll: float = -1.0) -> String:
	var total := 0.0
	for i in mini(items.size(), weights.size()):
		total += maxf(0, weights[i])
	if total <= 0:
		return "score"
	var value := (randf() if roll < 0 else clampf(roll, 0, 0.999999)) * total
	for i in mini(items.size(), weights.size()):
		value -= maxf(0, weights[i])
		if value < 0:
			return items[i]
	return "score"
