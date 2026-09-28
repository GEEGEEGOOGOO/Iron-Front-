class_name BossData
extends Resource
@export var title := "Iron Colossus"
@export var health := 140.0
@export var tint := Color(0.3, 0.4, 0.4)
@export var patterns: Array[AttackPattern] = []
@export_enum("bulwark", "mortar", "reactor") var equipment := "bulwark"
