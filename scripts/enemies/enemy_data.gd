class_name EnemyData
extends Resource
@export var title := "Grunt"
@export var health := 2.0
@export var move_speed := 2.0
@export var fire_rate := 0.7
@export var detection_range := 18.0
@export var attack_range := 9.0
@export var score_value := 100
@export_enum("grunt", "heavy", "grenadier", "rusher", "turret", "tank", "boss") var behavior := "grunt"
@export var tint := Color(0.45, 0.52, 0.3)
@export var drop_table: RewardTable
@export_range(0, 1) var drop_chance := 0.0
