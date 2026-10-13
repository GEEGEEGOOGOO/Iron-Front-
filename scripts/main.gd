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
	background()
	label_at("TACTICAL RUN & GUN / 01", Vector2(90, 60.0), 16, Color(0.65, 0.74, 0.77))
	label_at("IRON FRONT", Vector2(84, 125), 76)
	label_at("OPERATION ASHFALL", Vector2(90, 220), 23, Color(1, 0.54, 0.23))
	label_at("Three fronts. One soldier. Keep moving.", Vector2(90, 270), 20)
	for i in 3:
		var data: LevelData = load("res://data/levels/mission_%d.tres" % (i + 1))
		var index := i
		button("%02d  /  %s" % [i + 1, data.mission_name], 330 + i * 59, func(): start_mission(index))
		label_at("BEST %07d" % int(SaveManager.data.high_scores.get(str(i), 0)), Vector2(520, 343 + i * 59), 17, Color(0.75, 0.82, 0.8))
	button("OPTIONS", 520, show_options)
	button("QUIT", 579, func(): get_tree().quit())
	label_at("FIELD MANUAL", Vector2(720, 340), 20, Color(1, 0.54, 0.23))
	label_at("%s   Move left
%s   Move right
%s   Jump   •   %s   Fire
%s   Grenade   •   %s   Interact
%s   Switch weapon
%s   Pause

Change keys in Options → Controls." % [InputManager.key_label("move_left"), InputManager.key_label("move_right"), InputManager.key_label("jump"), InputManager.key_label("fire"), InputManager.key_label("fire_secondary"), InputManager.key_label("interact"), InputManager.key_label("switch_weapon"), InputManager.key_label("pause")], Vector2(720, 380), 17)
	pass_focus()
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
	var band := ColorRect.new()
	band.color = Color(0.03, 0.05, 0.07, 0.88)
	band.size = Vector2(1280, 83)
	screen.add_child(band)
	weapon_icon = TextureRect.new()
	weapon_icon.position = Vector2(22, 10)
	weapon_icon.size = Vector2(90, 60)
	weapon_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	weapon_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	screen.add_child(weapon_icon)
	hud = label_at("", Vector2(132, 17), 19)
	objective = label_at("", Vector2(320, 115), 27, Color(1, 0.7, 0.27))
	label_at("%s JUMP   %s FIRE   %s GRENADE   %s KNIFE   %s INTERACT   %s PAUSE" % [InputManager.key_label("jump"), InputManager.key_label("fire"), InputManager.key_label("fire_secondary"), InputManager.key_label("melee"), InputManager.key_label("interact"), InputManager.key_label("pause")], Vector2(100, 675), 16)
	boss_bar = ProgressBar.new()
	boss_bar.position = Vector2(350, 625)
	boss_bar.size = Vector2(580, 18)
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
		weapon_icon.texture = player.weapon.icon
		weapon_icon.tooltip_text = player.weapon.title
		var swap_hint := "    %s / LB SWITCH" % InputManager.key_label("switch_weapon") if player.reserve_weapon else ""
		hud.text = "HP %d / %d   •   LIVES %d       %s  %s       GRENADES %d
SCORE %07d     POW %d / %d     MISSION %02d%s" % [ceili(player.health.current_health), int(player.health.max_health), GameManager.lives, player.weapon.title.to_upper(), "∞" if player.ammo < 0 else str(player.ammo), player.grenades, GameManager.score, GameManager.rescued, level.pows.size(), GameManager.mission + 1, swap_hint]
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
		var item := button(action.replace("_", " ").to_upper() + "   /   " + InputManager.key_label(action), 240 + (i % 6) * 50, func():
			pending_binding = action
			binding_message = "Press a key for " + action.replace("_", " ")
			refresh_binding_message())
		item.position.x = 90 + (i / 6) * 520
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
