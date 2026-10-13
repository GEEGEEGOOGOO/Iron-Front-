class_name LevelData
extends Resource
@export var mission_name := "Operation Ashfall"
@export var subtitle := "BREACH THE COASTAL DEFENSE"
@export var length := 125.0
@export var par_time := 240.0
@export var sky_color := Color(0.45, 0.56, 0.61)
@export var ground_color := Color(0.35, 0.36, 0.27)
@export var waves: Array[WaveData] = []
@export var checkpoint_positions := PackedFloat32Array([2, 40, 76])
@export var boss_data: BossData
@export var platform_positions := PackedVector3Array()
@export var platform_sizes := PackedVector3Array()
@export_enum("coast", "desert", "foundry") var theme := "coast"
@export var background_music: AudioStream
@export var boss_music: AudioStream
@export var pow_rewards: RewardTable = preload("res://data/rewards/pow.tres")
@export var ladder_positions := PackedVector3Array()
@export var ladder_heights := PackedFloat32Array()
@export var elevator_positions := PackedVector3Array()
@export var elevator_travel := PackedFloat32Array()
@export_file("*.tscn") var level_scene_path := ""
@export var camera_bounds := Vector2(10, 115)
@export var camera_vertical_bounds := Vector2(0, 6)
@export_enum("perspective", "orthographic") var camera_projection := "perspective"
@export var camera_fov := 42.0
@export var camera_ortho_size := 18.0
@export var camera_player_half_width := 15.0
@export_range(50, 200, 5) var decoration_visibility_distance := 80.0
@export var pow_positions := PackedVector3Array([Vector3(33, 0, 0), Vector3(69, 0, 0), Vector3(100, 0, 0)])
@export var crate_positions := PackedVector3Array([Vector3(10, 0, 0), Vector3(38, 0, 0), Vector3(96, 0, 0)])
@export var barrel_positions := PackedVector3Array([Vector3(65, 0, 0)])
@export var tank_position := Vector3(58, 0.1, 0)
@export var supply_positions := PackedVector3Array([Vector3(5, 1, 0), Vector3(44, 2, 0), Vector3(74, 2, 0), Vector3(102, 1, 0)])
@export var supply_kinds := PackedStringArray(["machine_gun", "shotgun", "laser", "health"])
@export var boss_trigger_x := 105.0
@export var boss_arena_x := 114.0
@export var boss_spawn_position := Vector3(123, 0, 0)
@export var boss_room_max_x := 125.0
@export var commander_position := Vector3(119, 0, 0)
