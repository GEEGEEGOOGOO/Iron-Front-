extends Node
## F6 here: play the real mission with direct access to the three imported guns.
var main: Node
func _ready() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	main.start_mission(0)
	# Mission HUD now exposes the real three-slot loadout directly.
	if "--capture-weapons" in OS.get_cmdline_user_args():
		capture_weapons()

func capture_weapons() -> void:
	GameManager.god_mode = true
	main.level.wave_index = main.level.data.waves.size()
	GameManager.player.position = Vector3(7, 0.1, 0)
	main.mission_card_time = 0
	for kind in ["pistol", "shotgun", "flame"]:
		GameManager.player.equip(load("res://data/weapons/" + kind + ".tres"))
		await get_tree().create_timer(0.2).timeout
		Input.action_press("fire")
		await get_tree().create_timer(0.60 if kind == "flame" else 0.025).timeout
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://test-results")
		get_viewport().get_texture().get_image().save_png("res://test-results/blender-" + kind + "-gameplay.png")
		Input.action_release("fire")
	main.quit_to_menu()
	get_tree().quit()
