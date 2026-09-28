extends Node
var voices: Array[AudioStreamPlayer] = []
var sounds: Dictionary = {}
var spatial_voices: Array[AudioStreamPlayer3D] = []
var music_player: AudioStreamPlayer
var music_path := ""
var mission_music: AudioStream
var boss_music: AudioStream
var music_cache: Dictionary = {}
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	for bus in ["Music", "SFX", "UI", "Voice"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	music_player.volume_db = -7
	add_child(music_player)
	for i in 32:
		var voice := AudioStreamPlayer3D.new()
		voice.bus = "SFX"
		voice.unit_size = 24
		voice.max_distance = 75
		voice.max_db = 0
		add_child(voice)
		spatial_voices.append(voice)
	for i in 20:
		var voice := AudioStreamPlayer.new()
		voice.bus = "SFX"
		add_child(voice)
		voices.append(voice)
	for entry in [["shot", 1300.0, 0.055], ["hit", 180.0, 0.1], ["boom", 70.0, 0.38], ["pickup", 850.0, 0.18], ["jump", 450.0, 0.09]]:
		sounds[entry[0]] = tone(entry[1], entry[2])
	for entry in [["shot_pistol", 1300.0, 0.055, 0.4], ["shot_machine", 920.0, 0.045, 0.5], ["shot_rocket", 260.0, 0.16, 0.55], ["shot_shotgun", 410.0, 0.12, 0.8], ["shot_flame", 180.0, 0.15, 0.7], ["shot_laser", 1800.0, 0.14, 0.08]]:
		sounds[entry[0]] = tone(entry[1], entry[2], entry[3])
	set_volume("Master", float(SaveManager.data.volume), false)
	for bus in ["Music", "SFX", "UI", "Voice"]:
		set_volume(bus, float(SaveManager.data.get("bus_volumes", {}).get(bus, 0.7)), false)
func tone(frequency: float, duration: float, noise_mix := 0.4) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var samples := PackedByteArray()
	samples.resize(int(duration * 22050) * 2)
	for i in samples.size() / 2:
		var t := float(i) / 22050.0
		var envelope := pow(1.0 - t / duration, 2.0)
		var sample := (sin(TAU * frequency * t * (1.0 - t)) * (1.0 - noise_mix) + randf_range(-noise_mix, noise_mix)) * envelope
		samples.encode_s16(i * 2, int(sample * 13000))
	stream.data = samples
	return stream
func play(sound: String, bus := "SFX") -> void:
	for voice in voices:
		if not voice.playing:
			voice.bus = bus
			voice.stream = sounds.get(sound, sounds.get("shot"))
			voice.pitch_scale = randf_range(0.92, 1.08)
			voice.play()
			return

func play_at(sound: String, position: Vector3) -> void:
	for voice in spatial_voices:
		if not voice.playing:
			voice.global_position = position
			voice.stream = sounds.get(sound, sounds.get("shot"))
			voice.pitch_scale = randf_range(0.92, 1.08)
			voice.play()
			return

func set_volume(bus: String, value: float, persist := true) -> void:
	value = clampf(value, 0, 1)
	var index := AudioServer.get_bus_index(bus)
	if index < 0:
		return
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(value, 0.0001)))
	AudioServer.set_bus_mute(index, value <= 0)
	if not persist:
		return
	if bus == "Master":
		SaveManager.data.volume = value
	else:
		if not SaveManager.data.has("bus_volumes"):
			SaveManager.data.bus_volumes = {}
		SaveManager.data.bus_volumes[bus] = value
	SaveManager.save()

func start_mission(track: AudioStream, boss_track: AudioStream) -> void:
	mission_music = track
	boss_music = boss_track
	play_music(track)

func play_music(track: AudioStream) -> void:
	if not track:
		stop_music()
		return
	music_path = track.resource_path
	if not music_cache.has(music_path):
		var loop := track.duplicate() as AudioStreamWAV
		if loop:
			loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
			loop.loop_begin = 0
			loop.loop_end = loop.data.size() / (2 if loop.format == AudioStreamWAV.FORMAT_16_BITS else 1) / (2 if loop.stereo else 1)
		music_cache[music_path] = loop if loop else track
	music_player.stop()
	music_player.stream = music_cache[music_path]
	music_player.play()

func start_boss() -> void:
	play_music(boss_music)

func stop_music() -> void:
	for voice in voices:
		if voice.bus == "SFX":
			voice.stop()
	music_player.stop()
	music_path = ""
	for voice in spatial_voices:
		voice.stop()
