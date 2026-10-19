class_name WeaponData
extends Resource
@export var title := "Sidearm"
@export var damage := 1.0
@export var fire_rate := 5.0
@export var speed := 30.0
@export var max_ammo := -1
@export var starting_ammo := -1
@export var spread_angle := 0.0
@export var pellets := 1
@export var is_hitscan := false
@export var is_explosive := false
@export var explosion_radius := 0.0
@export var lifetime := 1.5
@export var color := Color(1, 0.8, 0.2)
@export_enum("projectile", "cone") var attack_mode := "projectile"
@export var range_meters := 32.0
@export var pierce_count := 1
@export var cone_half_angle := 0.45
@export var icon: Texture2D
@export_enum("pistol", "machine_gun", "rocket", "shotgun", "flame", "laser") var model_kind := "pistol"
@export var muzzle_distance := 1.0
@export var sfx_fire := "shot"
@export var muzzle_flash_color := Color(1, 0.87, 0.3)
@export var muzzle_flash_size := Vector3(0.5, 0.25, 0.2)
@export_range(0.01, 0.3, 0.01) var muzzle_flash_duration := 0.07

@export_range(1, 60, 1) var magazine_size := 12
@export_range(0.2, 4, 0.1) var reload_duration := 1.0
