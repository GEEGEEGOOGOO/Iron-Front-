class_name WaveData
extends Resource
@export var trigger_x := 18.0
@export var arena_center := 24.0
@export var enemy_types: Array[String] = ["grunt", "grunt", "heavy"]
@export var spawn_delay := 0.7
@export_enum("position", "level_start", "timer", "previous_cleared") var trigger_condition := "position"
@export var trigger_delay := 0.0
