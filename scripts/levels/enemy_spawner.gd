class_name EnemySpawner
extends Node3D
@export var wave: WaveData
func configured_wave() -> WaveData:
	var configured := wave.duplicate() as WaveData
	configured.trigger_x = global_position.x
	var focus := get_node_or_null("CameraFocus") as Node3D
	configured.arena_center = focus.global_position.x if focus else global_position.x + 7
	return configured
func spawn_position(index: int) -> Vector3:
	var points := get_node_or_null("SpawnPoints")
	if points and points.get_child_count() > 0:
		var marker := points.get_child(index % points.get_child_count()) as Node3D
		return Vector3(marker.global_position.x, marker.global_position.y, 0)
	return global_position + Vector3(16 - index * 1.8, 1, 0)
