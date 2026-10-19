extends Control
var switch_button: Button
var reload_button: Button
var dash_button: Button
var weapon_buttons: Dictionary = {}
func action_button(x: float, width: float, callback: Callable) -> Button:
	var button := Button.new()
	button.position = Vector2(x, 0)
	button.size = Vector2(width, 34)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 14)
	var invisible := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, invisible)
	button.add_theme_color_override("font_color", Color(1,1,1,0))
	button.add_theme_color_override("font_hover_color", Color(1,1,1,0))
	button.add_theme_color_override("font_disabled_color", Color(1,1,1,0))
	button.add_theme_color_override("font_pressed_color", Color(1,1,1,0))
	button.pressed.connect(callback)
	add_child(button)
	return button
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	switch_button = action_button(0, 124, func(): GameManager.player.switch_weapon())
	reload_button = action_button(0, 116, func(): GameManager.player.start_reload())
	dash_button = action_button(0, 184, func(): GameManager.player.start_dash())
	for kind in ["pistol", "shotgun", "flame"]:
		var button := action_button(0, 78, func(): GameManager.player.select_loadout(kind))
		weapon_buttons[kind] = button
	update_layout()
func update_layout() -> void:
	var rects := MinimalCombatHUD.layout(get_viewport_rect().size)
	for entry in [[switch_button, "switch"], [reload_button, "reload"], [dash_button, "dash"]]:
		var rect: Rect2 = rects[entry[1]]
		entry[0].position = rect.position
		entry[0].size = rect.size
	for kind in weapon_buttons:
		var rect: Rect2 = rects[kind]
		weapon_buttons[kind].position = rect.position
		weapon_buttons[kind].size = rect.size
func _process(_delta: float) -> void:
	update_layout()
	var player = GameManager.player
	if not is_instance_valid(player):
		return
	var unavailable: bool = GameManager.state != GameManager.State.PLAYING or player.state == player.State.DEAD or is_instance_valid(player.vehicle)
	for kind in weapon_buttons:
		var remaining: int = player.loadout_ammo.get(kind, 0)
		weapon_buttons[kind].disabled = unavailable or remaining == 0
		weapon_buttons[kind].modulate = Color(1, 0.8, 0.3) if player.weapon.model_kind == kind else Color.WHITE
		weapon_buttons[kind].tooltip_text = ("%s — unlimited reserve" % kind.capitalize()) if remaining < 0 else "%s — %d rounds remaining" % [kind.capitalize(), remaining]
	var has_special: bool = player.reserve_weapon != null and player.reserve_ammo > 0
	switch_button.disabled = unavailable or not has_special
	var target: String = "SIDEARM" if player.weapon == player.reserve_weapon else (player.reserve_weapon.title.to_upper() if has_special else "FIND A WEAPON")
	switch_button.tooltip_text = "%s / LB  SWITCH → %s" % [InputManager.key_label("switch_weapon"), target]
	var full: bool = player.magazine_rounds() >= (mini(player.weapon.magazine_size, player.ammo) if player.ammo >= 0 else player.weapon.magazine_size)
	reload_button.disabled = unavailable or full or player.reload_remaining > 0
	reload_button.tooltip_text = "%s / L3  %s" % [InputManager.key_label("reload"), "RELOADING…" if player.reload_remaining > 0 else ("MAGAZINE FULL" if full else "RELOAD")]
	dash_button.disabled = unavailable or player.dash_recharge > 0 or is_instance_valid(player.ladder)
	var dash_state := "AIR DASH" if player.dash_recharge <= 0 else "READY IN %.1fs" % player.dash_recharge
	if player.dash_remaining > 0:
		dash_state = "DASHING »"
	dash_button.tooltip_text = "%s / R3  %s" % [InputManager.key_label("dash"), dash_state]
