extends Node
var failures := 0
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _ready() -> void:
	call_deferred("run")
func run() -> void:
	var original: Dictionary = SaveManager.data.duplicate(true)
	var paths: Array[String] = []
	for mission in 3:
		var data: LevelData = load("res://data/levels/mission_%d.tres" % (mission + 1))
		AudioManager.start_mission(data.background_music, data.boss_music)
		check(AudioManager.music_player.playing, "Mission music must start")
		check(AudioManager.music_player.bus == "Music", "Music must route to the music bus")
		check(AudioManager.music_player.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "Music must loop")
		check(AudioManager.music_player.stream.loop_end > 0, "Music loop must contain samples")
		check(AudioManager.music_path not in paths, "Every mission must use a distinct music cue")
		paths.append(AudioManager.music_path)
		await get_tree().create_timer(0.1).timeout
		AudioManager.start_boss()
		check(AudioManager.music_path == data.boss_music.resource_path, "Boss must replace mission cue")
		await get_tree().create_timer(0.1).timeout
		AudioManager.play_music(data.background_music)
		check(AudioManager.music_path == data.background_music.resource_path, "Checkpoint restart must restore mission music")
	var count := AudioManager.get_child_count()
	for i in 100:
		AudioManager.play_at("shot", Vector3(i, 1, 0))
	check(AudioManager.get_child_count() == count, "SFX bursts must reuse the fixed pool")
	check(AudioManager.spatial_voices.size() == 32, "Spatial audio pool must have 32 voices")
	AudioManager.set_volume("Music", 0)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "Zero volume must mute the bus")
	AudioManager.set_volume("Music", 0.42)
	check(not AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "Increasing volume must unmute")
	var saved = JSON.parse_string(FileAccess.get_file_as_string(SaveManager.save_path))
	check(is_equal_approx(saved.bus_volumes.Music, 0.42), "Bus volume must persist")
	AudioManager.stop_music()
	check(not AudioManager.music_player.playing, "Leaving mission must stop music")
	for voice in AudioManager.spatial_voices:
		check(not voice.playing, "Leaving mission must stop combat sound tails")
	SaveManager.data = original
	SaveManager.save()
	await get_tree().create_timer(0.2).timeout
	await get_tree().process_frame
	print("AUDIO REGRESSION ", "PASS" if failures == 0 else "FAIL")
	get_tree().quit(0 if failures == 0 else 1)
