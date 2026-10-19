extends Node
@export_range(-1, 2) var auto_start_mission := -1
var level: Node3D
var ui: CanvasLayer
var screen: Control
var hud: Label
var weapon_icon: TextureRect
var objective: Label
var boss_bar: ProgressBar
var last_state := -1
var pending_binding := ""
var selected_menu_mission := 1
var binding_message := ""
var debug_label: Label
var mission_card: ColorRect
var mission_card_time := 0.0
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	PoolManager.register_pool("burst", func(): return preload("res://scripts/combat/burst_effect.gd").new(), 64)
	PoolManager.register_pool("wreck", func(): return preload("res://scripts/vehicles/vehicle_wreck.gd").new(), 3)
	PoolManager.register_pool("fragment", func(): return preload("res://scripts/combat/physical_fragment.gd").new(), 160)
	PoolManager.register_pool("pickup", func(): return preload("res://scripts/levels/pickup.gd").new(), 48)
	PoolManager.register_pool("effect", func(): return preload("res://scripts/combat/effect.gd").new(), 200)
	PoolManager.register_pool("projectile", func(): return preload("res://scripts/combat/projectile.gd").new(), 256)
	PoolManager.register_pool("enemy", func(): return preload("res://scripts/enemies/enemy.gd").new(), 48)
	ui = CanvasLayer.new()
	add_child(ui)
	if auto_start_mission >= 0:
		start_mission(auto_start_mission)
	else:
		show_menu()
func clear_ui() -> void:
	pending_binding = ""
	mission_card = null
	if is_instance_valid(screen):
		screen.queue_free()
	screen = Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(screen)
func background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.035, 0.055, 0.075, 0.96)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(bg)
	var stripe := ColorRect.new()
	stripe.color = Color(0.93, 0.4, 0.15)
	stripe.position = Vector2(90, 105)
	stripe.size = Vector2(64, 5)
	screen.add_child(stripe)
func label_at(text: String, pos: Vector2, size: int, color := Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	screen.add_child(label)
	return label
func button(text: String, y: float, callback: Callable) -> Button:
	var item := Button.new()
	item.text = text
	item.position = Vector2(90, y)
	item.size = Vector2(410, 48)
	item.add_theme_font_size_override("font_size", 20)
	item.pressed.connect(func(): AudioManager.play("pickup", "UI"))
	item.pressed.connect(callback)
	screen.add_child(item)
	return item
func show_menu() -> void:
	AudioManager.stop_music()
	get_tree().paused = false
	GameManager.state = GameManager.State.MENU
	last_state = GameManager.state
	clear_ui()
	var menu := preload("res://scripts/ui/campaign_menu.gd").new()
	menu.name = "CampaignMenu"
	menu.selected = selected_menu_mission
	menu.deployed.connect(start_mission)
	menu.mission_selected.connect(func(index: int): selected_menu_mission = index)
	menu.options_requested.connect(show_options)
	menu.controls_requested.connect(show_controls)
	menu.quit_requested.connect(func(): get_tree().quit())
	screen.add_child(menu)
func pass_focus() -> void:
	for child in screen.get_children():
		if child is Button:
			child.grab_focus()
			break
func start_mission(index: int) -> void:
	get_tree().paused = false
	PoolManager.release_all()
	if is_instance_valid(level):
		remove_child(level)
		level.queue_free()
	GameManager.begin(index)
	var mission_data: LevelData = load("res://data/levels/mission_%d.tres" % (index + 1))
	level = load(mission_data.level_scene_path).instantiate()
	level.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(level)
	mission_card_time = 2.0
	show_hud()
	last_state = GameManager.state
func show_hud() -> void:
	clear_ui()
	weapon_icon = TextureRect.new()
	weapon_icon.position = Vector2(22, 10)
	weapon_icon.size = Vector2(90, 60)
	weapon_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	weapon_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	screen.add_child(weapon_icon)
	weapon_icon.hide()
	hud = label_at("", Vector2(132, 8), 16)
	hud.hide()
	var status_visual = preload("res://scripts/ui/combat_status.gd").new()
	status_visual.size = Vector2(1280, 720)

	var actions = preload("res://scripts/ui/action_controls.gd").new()
	actions.position = Vector2.ZERO
	screen.add_child(actions)
	screen.add_child(status_visual)
	objective = label_at("", Vector2(400, 80), 18, Color(1, 0.8, 0.5))
	objective.anchor_left = 0.5
	objective.anchor_right = 0.5
	objective.offset_left = -240
	objective.offset_right = 240
	objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	boss_bar = ProgressBar.new()
	boss_bar.anchor_left = 0.5
	boss_bar.anchor_right = 0.5
	boss_bar.anchor_top = 1.0
	boss_bar.anchor_bottom = 1.0
	boss_bar.offset_left = -220
	boss_bar.offset_right = 220
	boss_bar.offset_top = -36
	boss_bar.offset_bottom = -28
	boss_bar.show_percentage = false
	screen.add_child(boss_bar)
	debug_label = label_at("", Vector2(30, 150), 16)
	debug_label.hide()
	if mission_card_time > 0:
		show_mission_card()
func show_mission_card() -> void:
	mission_card = ColorRect.new()
	mission_card.color = Color(0.025, 0.045, 0.06, 0.92)
	mission_card.position = Vector2(190, 225)
	mission_card.size = Vector2(900, 245)
	mission_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(mission_card)
	var stripe := ColorRect.new()
	stripe.color = Color(1, 0.4, 0.13)
	stripe.position = Vector2(0, 0)
	stripe.size = Vector2(12, 245)
	mission_card.add_child(stripe)
	var mission_number := Label.new()
	mission_number.name = "MissionNumber"
	mission_number.text = "MISSION %02d" % (GameManager.mission + 1)
	mission_number.position = Vector2(50, 25)
	mission_number.add_theme_font_size_override("font_size", 34)
	mission_number.add_theme_color_override("font_color", Color(1, 0.52, 0.22))
	mission_card.add_child(mission_number)
	var title := Label.new()
	title.name = "MissionTitle"
	title.text = level.data.mission_name.to_upper()
	title.position = Vector2(48, 82)
	title.add_theme_font_size_override("font_size", 54)
	mission_card.add_child(title)
	var subtitle := Label.new()
	subtitle.name = "MissionObjective"
	subtitle.text = level.data.subtitle
	subtitle.position = Vector2(51, 174)
	subtitle.add_theme_font_size_override("font_size", 22)
	subtitle.add_theme_color_override("font_color", Color(0.75, 0.82, 0.84))
	mission_card.add_child(subtitle)
func show_pause() -> void:
	clear_ui()
	background()
	label_at("MISSION PAUSED", Vector2(90, 140), 48)
	button("RESUME", 280, resume_game).grab_focus()
	button("RESTART CHECKPOINT", 340, func():
		restart_checkpoint())
	button("OPTIONS", 400, show_options)
	button("QUIT TO MENU", 460, quit_to_menu)
func resume_game() -> void:
	get_tree().paused = false
	GameManager.state = GameManager.State.PLAYING
	last_state = GameManager.state
	show_hud()
func quit_to_menu() -> void:
	PoolManager.release_all()
	if is_instance_valid(level):
		remove_child(level)
		level.queue_free()
	GameManager.player = null
	GameManager.level = null
	show_menu()
func show_options() -> void:
	clear_ui()
	background()
	label_at("FIELD SETTINGS", Vector2(90, 140), 48)
	for i in 5:
		var bus: String = ["Master", "Music", "SFX", "UI", "Voice"][i]
		var volume := HSlider.new()
		volume.position = Vector2(290, 245 + i * 55)
		volume.size = Vector2(350, 30)
		volume.value = (float(SaveManager.data.volume) if bus == "Master" else float(SaveManager.data.get("bus_volumes", {}).get(bus, 0.7))) * 100
		volume.value_changed.connect(func(value: float): AudioManager.set_volume(bus, value / 100.0))
		screen.add_child(volume)
		label_at(bus.to_upper(), Vector2(90, 245 + i * 55), 18)
	var controls := button("CONTROLS", 260, show_controls)
	controls.position.x = 750
	var difficulty := CheckButton.new()
	difficulty.text = "ARCADE MODE • 1 HP (next respawn / mission)"
	difficulty.position = Vector2(90, 530)
	difficulty.button_pressed = SaveManager.data.arcade
	difficulty.toggled.connect(func(value: bool):
		SaveManager.data.arcade = value
		SaveManager.save())
	screen.add_child(difficulty)
	button("BACK", 590, func():
		if GameManager.state == GameManager.State.PAUSED:
			show_pause()
		else:
			show_menu()).grab_focus()
func show_result() -> void:
	AudioManager.stop_music()
	clear_ui()
	background()
	if GameManager.state == GameManager.State.COMPLETE:
		label_at("CAMPAIGN COMPLETE" if GameManager.mission == 2 else "MISSION COMPLETE", Vector2(90, 130), 52)
		label_at("RANK " + GameManager.rank(), Vector2(840, 220), 90, Color(1, 0.6, 0.2))
		var tally := GameManager.score_breakdown
		label_at("COMBAT & PICKUPS   %07d
RESCUE BONUS         +%d
TIME BONUS              +%d
TOTAL SCORE          %07d" % [tally.get("combat_and_pickups", 0), tally.get("rescue_bonus", 0), tally.get("time_bonus", 0), GameManager.score], Vector2(90, 240), 26)
		label_at("POWs %d / %d  •  TIME %02d:%02d  •  ACCURACY %d%%" % [GameManager.rescued, level.pows.size(), int(GameManager.elapsed) / 60, int(GameManager.elapsed) % 60, int(GameManager.accuracy() * 100)], Vector2(90, 405), 20)
		if GameManager.mission < 2:
			button("NEXT MISSION", 470, func(): start_mission(GameManager.mission + 1)).grab_focus()
	else:
		label_at("TRANSMISSION LOST", Vector2(90, 140), 52)
		label_at("No lives remaining. Return to the front.", Vector2(90, 240), 23)
		button("RETRY MISSION", 400, func(): start_mission(GameManager.mission)).grab_focus()
	button("MISSION SELECT", 540, quit_to_menu)
	pass_focus()
func _process(delta: float) -> void:
	if GameManager.state == GameManager.State.PLAYING and mission_card_time > 0:
		mission_card_time = maxf(0, mission_card_time - delta)
	if is_instance_valid(mission_card):
		mission_card.visible = mission_card_time > 0
		mission_card.modulate.a = minf(1.0, mission_card_time * 1.25)
	if GameManager.state != last_state:
		last_state = GameManager.state
		if GameManager.state in [GameManager.State.GAME_OVER, GameManager.State.COMPLETE]:
			show_result()
	if GameManager.state == GameManager.State.PLAYING and is_instance_valid(GameManager.player) and is_instance_valid(hud):
		var player := GameManager.player
		var status: String
		var hint := ""
		if is_instance_valid(player.vehicle):
			var vehicle = player.vehicle
			weapon_icon.texture = vehicle.machine_gun.icon
			weapon_icon.tooltip_text = "Mounted machine gun and cannon"
			status = "IRON MULE • MOUNTED WEAPONS"
			hint = "    %s / Y EXIT" % InputManager.key_label("interact")
		else:
			weapon_icon.texture = player.weapon.icon
			weapon_icon.tooltip_text = player.weapon.title
			status = player.weapon.title.to_upper()
			if player.reserve_weapon:
				hint = "    %s / LB SWITCH" % InputManager.key_label("switch_weapon")
		hud.text = "%s\nSCORE %07d     POW %d / %d     MISSION %02d%s" % [status, GameManager.score, GameManager.rescued, level.pows.size(), GameManager.mission + 1, hint]
		objective.text = level.banner if level.banner_time > 0 and mission_card_time <= 0 else ""
		boss_bar.visible = is_instance_valid(level.boss) and level.boss.active
		if boss_bar.visible:
			boss_bar.value = 100 * level.boss.health.current_health / level.boss.health.max_health
		if debug_label.visible:
			debug_label.text = "F4 GOD: %s   F5 WEAPON   F6 SPAWN GRUNT   F7 SKIP
FPS %d   PHYSICS %.2f ms   DRAW CALLS %d
ACTIVE POOL %d   X %.1f   Z %.3f" % [GameManager.god_mode, Engine.get_frames_per_second(), Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)), PoolManager.borrowed.size(), player.position.x, player.position.z]
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if GameManager.state == GameManager.State.PLAYING:
			GameManager.state = GameManager.State.PAUSED
			get_tree().paused = true
			show_pause()
		elif GameManager.state == GameManager.State.PAUSED:
			resume_game()
	if OS.is_debug_build() and GameManager.state == GameManager.State.PLAYING:
		if event.is_action_pressed("debug"):
			debug_label.visible = not debug_label.visible
		if event is InputEventKey and event.pressed and not event.echo:
			match event.physical_keycode:
				KEY_F4: GameManager.god_mode = not GameManager.god_mode
				KEY_F5: GameManager.player.equip(load("res://data/weapons/" + ["machine_gun", "rocket", "shotgun", "flame", "laser"].pick_random() + ".tres"))
				KEY_F6: level.spawn_enemy("grunt", GameManager.player.position + Vector3(8, 1, 0))
				KEY_F7: GameManager.finish()

func show_controls() -> void:
	clear_ui()
	background()
	label_at("CONTROLS", Vector2(90, 125), 48)
	label_at("Select an action, then press a key. Escape cancels capture. Controller bindings stay available.", Vector2(90, 194), 17)
	for i in InputManager.REBINDABLE.size():
		var action: String = InputManager.REBINDABLE[i]
		var item := button(action.replace("_", " ").to_upper() + "   /   " + InputManager.key_label(action), 240 + (i % 7) * 43, func():
			pending_binding = action
			binding_message = "Press a key for " + action.replace("_", " ")
			refresh_binding_message())
		item.position.x = 90 + (i / 7) * 520
	label_at(binding_message, Vector2(90, 540), 18, Color(1, 0.7, 0.3)).name = "BindingMessage"
	button("RESTORE DEFAULTS", 590, func():
		InputManager.reset_bindings()
		binding_message = "Default keyboard controls restored."
		show_controls())
	var back := button("BACK", 590, show_options)
	back.position.x = 610
	pass_focus()

func refresh_binding_message() -> void:
	var message := screen.get_node_or_null("BindingMessage") as Label
	if message:
		message.text = binding_message

func _input(event: InputEvent) -> void:
	if pending_binding.is_empty():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		if event.physical_keycode == KEY_ESCAPE:
			pending_binding = ""
			binding_message = "Binding cancelled."
		else:
			var result := InputManager.rebind(pending_binding, event.physical_keycode)
			if result.is_empty():
				binding_message = "Control saved."
				pending_binding = ""
			else:
				binding_message = result
		show_controls()

func restart_checkpoint() -> void:
	GameManager.player.respawn()
	if GameManager.state == GameManager.State.GAME_OVER:
		get_tree().paused = false
		last_state = GameManager.state
		show_result()
	else:
		resume_game()
