class_name CampaignMenu
extends Control
## Approved arcade campaign design, with honest preview provenance.
signal deployed(index: int)
signal mission_selected(index: int)
signal options_requested
signal controls_requested
signal quit_requested
const GOLD := Color(1, 0.61, 0.12)
const CREAM := Color(0.95, 0.91, 0.79)
const DIM := Color(0.57, 0.56, 0.52)
const BASE_SIZE := Vector2(1280, 720)
const BACKDROP = preload("res://assets/ui/menu/sunset_cityscape.png")
const SOLDIER = preload("res://assets/ui/menu/player_character.png")
const DUST_MAP = preload("res://assets/ui/menu/dust_battalion_map.png")
const PLACEHOLDER = preload("res://assets/ui/menu/map_placeholder.svg")
const ASHFALL_MAP = preload("res://assets/ui/menu/ashfall_concept.png")
const FOUNDRY_MAP = preload("res://assets/ui/menu/foundry_concept.png")
var selected := 1
var content: Control
var cards: Array[Button] = []
var pictures: Array[TextureRect] = []
var best_label: Label
var deploy_button: Button
var heading_font: SystemFont
var body_font: SystemFont
var home_page: Control
var missions_page: Control
var build_parent: Control
var play_button: Button
var back_button: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	heading_font = SystemFont.new()
	heading_font.font_names = PackedStringArray(["Impact", "DIN Condensed", "Arial Narrow", "sans-serif"])
	heading_font.font_weight = 800
	body_font = SystemFont.new()
	body_font.font_names = PackedStringArray(["DIN Condensed", "Arial Narrow", "sans-serif"])
	body_font.font_weight = 600
	var background := texture(self, BACKDROP, Rect2(Vector2.ZERO, BASE_SIZE))
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content = Control.new()
	content.name = "CampaignComposition"
	content.size = BASE_SIZE
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)
	# The supplied illustration already includes the hero on the right.
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(0.025,0.018,0.016,0.92), Color(0.025,0.018,0.016,0.60), Color(0.025,0.018,0.016,0)])
	gradient.offsets = PackedFloat32Array([0,0.43,1])
	var shade := GradientTexture2D.new()
	shade.gradient = gradient
	shade.fill_from = Vector2.ZERO
	shade.fill_to = Vector2.RIGHT
	texture(self, shade, Rect2(Vector2.ZERO, BASE_SIZE)).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	move_child(content, get_child_count()-1)
	label("TACTICAL RUN & GUN", Rect2(64, 64, 290, 18), 12, CREAM, false)
	var accent := ColorRect.new()
	accent.color = GOLD
	accent.position = Vector2(64, 99)
	accent.size = Vector2(48, 4)
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(accent)
	label("IRON FRONT", Rect2(58, 106, 700, 100), 86, CREAM, true)
	label("THREE FRONTS. ONE SOLDIER. KEEP MOVING.", Rect2(66, 210, 560, 24), 14, CREAM, false)
	home_page = Control.new()
	home_page.name = "HomePage"
	home_page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(home_page)
	build_parent = home_page
	play_button = footer_button("PLAY GAME  ›", Vector2(64, 290), show_missions)
	play_button.name = "PlayGame"
	play_button.size = Vector2(432, 60)
	play_button.add_theme_font_size_override("font_size", 30)
	play_button.add_theme_stylebox_override("normal", style(Color(0.05, 0.04, 0.02, 0.75), GOLD, 2))
	footer_button("OPTIONS", Vector2(64, 380), func(): options_requested.emit()).size = Vector2(432, 44)
	footer_button("CONTROLS", Vector2(64, 440), func(): controls_requested.emit()).size = Vector2(432, 44)
	footer_button("QUIT", Vector2(64, 500), func(): quit_requested.emit()).size = Vector2(432, 44)
	missions_page = Control.new()
	missions_page.name = "MissionSelectionPage"
	missions_page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(missions_page)
	build_parent = missions_page
	label("SELECT OPERATION", Rect2(66, 250, 380, 20), 12, GOLD, false)
	for i in 3:
		create_card(i)
	best_label = label("", Rect2(66, 565, 380, 22), 14, GOLD, false)
	best_label.name = "SelectedBestScore"
	deploy_button = Button.new()
	deploy_button.name = "Deploy"
	deploy_button.text = "D E P L O Y  ›"
	deploy_button.position = Vector2(64, 596)
	deploy_button.size = Vector2(432, 48)
	deploy_button.add_theme_font_override("font", heading_font)
	deploy_button.add_theme_font_size_override("font_size", 32)
	deploy_button.add_theme_color_override("font_color", Color(0.06, 0.04, 0.015))
	deploy_button.add_theme_color_override("font_hover_color", Color.BLACK)
	deploy_button.add_theme_color_override("font_pressed_color", Color.BLACK)
	deploy_button.add_theme_stylebox_override("normal", style(GOLD, GOLD, 2))
	deploy_button.add_theme_stylebox_override("hover", style(GOLD.lightened(0.13), CREAM, 2))
	deploy_button.add_theme_stylebox_override("pressed", style(GOLD.darkened(0.12), CREAM, 2))
	deploy_button.add_theme_stylebox_override("focus", style(Color.TRANSPARENT, CREAM, 2))
	deploy_button.pressed.connect(func(): deployed.emit(selected))
	missions_page.add_child(deploy_button)
	for i in 3:
		cards[i].focus_neighbor_left = cards[(i + 2) % 3].get_path()
		cards[i].focus_neighbor_right = cards[(i + 1) % 3].get_path()
		cards[i].focus_neighbor_top = cards[i - 1].get_path() if i > 0 else deploy_button.get_path()
		cards[i].focus_neighbor_bottom = cards[i + 1].get_path() if i < 2 else deploy_button.get_path()
	back_button = footer_button("‹  BACK", Vector2(64, 662), show_home)
	back_button.name = "BackToMainMenu"
	deploy_button.focus_neighbor_bottom = back_button.get_path()
	back_button.focus_neighbor_top = deploy_button.get_path()
	select_mission(selected)
	resized.connect(update_layout)
	update_layout()
	show_home()

func show_missions() -> void:
	home_page.hide()
	missions_page.show()
	cards[selected].grab_focus()

func show_home() -> void:
	missions_page.hide()
	home_page.show()
	play_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if missions_page.visible and event.is_action_pressed("ui_cancel"):
		show_home()
		get_viewport().set_input_as_handled()

func texture(parent: Node, image: Texture2D, rect: Rect2) -> TextureRect:
	var item := TextureRect.new()
	# Set sizing policy before the texture: otherwise its native minimum size
	# can enlarge the rect before EXPAND_IGNORE_SIZE takes effect.
	item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item.texture = image
	item.position = rect.position
	item.size = rect.size
	item.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(item)
	return item

func label(text: String, rect: Rect2, font_size: int, color: Color, heading: bool) -> Label:
	var item := Label.new()
	item.text = text
	item.position = rect.position
	item.size = rect.size
	item.add_theme_font_override("font", heading_font if heading else body_font)
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_color_override("font_color", color)
	item.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	item.add_theme_constant_override("shadow_offset_y", 2)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(build_parent if build_parent != null else content).add_child(item)
	return item

func style(fill: Color, border: Color, width: int) -> StyleBoxFlat:
	var item := StyleBoxFlat.new()
	item.bg_color = fill
	item.border_color = border
	item.set_border_width_all(width)
	item.set_corner_radius_all(3)
	return item

func create_card(index: int) -> void:
	var x := 64.0
	var y := 280.0 + index * 92.0
	var button := Button.new()
	button.name = "MissionCard%d" % (index + 1)
	button.position = Vector2(x, y)
	button.size = Vector2(432, 82)
	button.clip_contents = true
	button.tooltip_text = ["Military research facility — concept art", "Occupied desert city — in-game capture", "Nighttime industrial steelworks — concept art"][index]
	button.pressed.connect(func(): select_mission(index))
	button.focus_entered.connect(func(): select_mission(index))
	missions_page.add_child(button)
	cards.append(button)
	var preview: Texture2D = [ASHFALL_MAP, DUST_MAP, FOUNDRY_MAP][index]
	if index != 1:
		# Exclude the title baked into the concept sheet, without changing the asset.
		var cropped := AtlasTexture.new()
		cropped.atlas = preview
		cropped.region = Rect2(0, preview.get_height() * 0.12, preview.get_width(), preview.get_height() * 0.88)
		preview = cropped
	var picture := texture(button, preview, Rect2(3, 3, 138, 76))
	pictures.append(picture)
	var text_backing := ColorRect.new()
	text_backing.position = Vector2(143, 3)
	text_backing.size = Vector2(286, 76)
	text_backing.color = Color(0.035, 0.035, 0.03, 0.94)
	text_backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(text_backing)
	# Borders draw above the image, so hover/focus remain visible.
	var border := Panel.new()
	border.name = "SelectionBorder"
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(border)
	var num := label("%02d" % (index + 1), Rect2(x + 154, y + 9, 40, 25), 18, GOLD if index == selected else CREAM, true)
	num.name = "MissionNumber%d" % index
	var names := ["OPERATION ASHFALL", "DUST BATTALION", "MIDNIGHT FOUNDRY"]
	label(names[index], Rect2(x + 154, y + 33, 270, 25), 22, CREAM, true)
	label("IN-GAME MAP" if index == 1 else "ENVIRONMENT CONCEPT", Rect2(x + 154, y + 61, 270, 16), 10, DIM, false)

func footer_button(text: String, position: Vector2, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.position = position
	button.size = Vector2(140, 34)
	button.add_theme_font_override("font", body_font)
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_color_override("font_hover_color", GOLD)
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", style(Color(1, 0.6, 0.1, 0.08), Color.TRANSPARENT, 0))
	button.add_theme_stylebox_override("focus", style(Color.TRANSPARENT, GOLD, 1))
	button.pressed.connect(callback)
	build_parent.add_child(button)
	return button

func select_mission(index: int) -> void:
	selected = clampi(index, 0, 2)
	for i in cards.size():
		var active := i == selected
		cards[i].add_theme_stylebox_override("normal", style(Color.TRANSPARENT, GOLD if active else Color(0.42, 0.41, 0.36), 2))
		cards[i].add_theme_stylebox_override("hover", style(Color.TRANSPARENT, CREAM, 2))
		cards[i].add_theme_stylebox_override("focus", style(Color.TRANSPARENT, GOLD, 2))
		var border := cards[i].get_node("SelectionBorder") as Panel
		border.add_theme_stylebox_override("panel", style(Color.TRANSPARENT, GOLD if active else Color(0.42, 0.41, 0.36), 3 if active else 1))
		pictures[i].modulate = Color.WHITE if active else Color(0.72, 0.72, 0.72)
		var number := missions_page.get_node("MissionNumber%d" % i) as Label
		number.add_theme_color_override("font_color", GOLD if active else CREAM)
	if is_instance_valid(best_label):
		best_label.position.x = 66
		best_label.text = "BEST  %07d" % int(SaveManager.data.high_scores.get(str(selected), 0))
	if is_instance_valid(deploy_button):
		deploy_button.focus_neighbor_top = cards[selected].get_path()
	mission_selected.emit(selected)

func update_layout() -> void:
	if not content:
		return
	var factor := minf(size.x / BASE_SIZE.x, size.y / BASE_SIZE.y)
	content.scale = Vector2.ONE * factor
	content.position = (size - BASE_SIZE * factor) * 0.5
