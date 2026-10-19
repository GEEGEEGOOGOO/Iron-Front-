class_name MinimalCombatHUD
extends Control
# Approved Minimal HUD. Edge-anchored layout shared with invisible input regions.
const IVORY := Color(0.96, 0.93, 0.82)
const AMBER := Color(1, 0.65, 0.20)
const RED := Color(0.95, 0.22, 0.15)
const MUTED := Color(0.65, 0.62, 0.53)
const SILHOUETTES := {
	"pistol": preload("res://assets/ui/hud/pistol.svg"),
	"shotgun": preload("res://assets/ui/hud/shotgun.svg"),
	"flame": preload("res://assets/ui/hud/flame.svg"),
}
var display_font: SystemFont
static func layout(view: Vector2) -> Dictionary:
	return preload("res://scripts/ui/hud_layout.gd").rects(view)
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	display_font = SystemFont.new()
	display_font.font_names = PackedStringArray(["DIN Condensed", "Arial Narrow", "sans-serif"])
	display_font.font_weight = 700
func _process(_delta: float) -> void:
	queue_redraw()
func text_at(pos: Vector2, title: String, color := IVORY, font_size := 18) -> void:
	draw_string(display_font, pos + Vector2(1, 2), title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, 0.7))
	draw_string(display_font, pos, title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
func centered_text(center: float, baseline: float, title: String, color: Color, font_size: int) -> void:
	var width := display_font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	text_at(Vector2(center - width * 0.5, baseline), title, color, font_size)
func chip(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	return style
func helmet(pos: Vector2, color: Color) -> void:
	draw_circle(pos + Vector2(7, 7), 5, color)
	draw_arc(pos + Vector2(7, 6), 7, PI, TAU, 12, color, 3, true)
	draw_line(pos + Vector2(0, 7), pos + Vector2(14, 7), color, 2, true)
	draw_style_box(chip(color, Color.TRANSPARENT), Rect2(pos + Vector2(2, 13), Vector2(10, 5)))
func grenade(pos: Vector2) -> void:
	draw_circle(pos + Vector2(10, 16), 9, IVORY)
	draw_rect(Rect2(pos + Vector2(6, 3), Vector2(8, 7)), IVORY)
	draw_line(pos + Vector2(9, 3), pos + Vector2(16, 3), IVORY, 2, true)
	draw_line(pos + Vector2(16, 3), pos + Vector2(20, 11), IVORY, 2, true)
	for y in [12, 18]:
		draw_line(pos + Vector2(2, y), pos + Vector2(18, y), Color(0.04, 0.03, 0.02), 1, true)
func runner(pos: Vector2, color: Color) -> void:
	draw_circle(pos + Vector2(17, 4), 4, color)
	for pair in [[Vector2(14,12),Vector2(8,23)], [Vector2(14,12),Vector2(22,17)], [Vector2(12,18),Vector2(20,25)], [Vector2(20,25),Vector2(14,33)], [Vector2(8,23),Vector2(1,30)], [Vector2(9,13),Vector2(3,17)]]:
		draw_line(pos + pair[0], pos + pair[1], color, 3, true)
func fitted_icon(art: Texture2D, rect: Rect2, color: Color) -> void:
	if not art:
		return
	var fit := art.get_size() * minf(rect.size.x / art.get_width(), rect.size.y / art.get_height())
	draw_texture_rect(art, Rect2(rect.get_center() - fit * 0.5, fit), false, color)
func _draw() -> void:
	var player = GameManager.player
	if not is_instance_valid(player) or not display_font:
		return
	var view := get_viewport_rect().size
	var driving := is_instance_valid(player.vehicle)
	var hp = player.vehicle.health if driving else player.health
	var ratio: float = clampf(hp.current_health / maxf(hp.max_health, 1), 0, 1)
	draw_rect(Rect2(30, 24, 164, 20), Color(0.04,0.035,0.025,0.5))
	draw_rect(Rect2(30, 24, 164, 20), Color(0.9,0.67,0.35,0.7), false, 1)
	draw_rect(Rect2(33, 27, 158 * ratio, 14), RED)
	text_at(Vector2(205,42), "%d%%" % roundi(ratio*100), IVORY, 23)
	draw_line(Vector2(258,25),Vector2(258,43),Color(1,0.9,0.7,0.35))
	for i in mini(GameManager.lives,5):
		helmet(Vector2(276+i*26,24),RED)
	if driving:
		text_at(Vector2(31,60),"VEHICLE ARMOR",MUTED,11)
	centered_text(view.x*0.5,35,"MISSION  %02d" % (GameManager.mission+1),AMBER,22)
	centered_text(view.x*0.5,54,GameManager.level.data.subtitle,IVORY,12)
	draw_line(Vector2(view.x*0.5-133,28),Vector2(view.x*0.5-97,28),AMBER,1)
	draw_line(Vector2(view.x*0.5+97,28),Vector2(view.x*0.5+133,28),AMBER,1)
	text_at(Vector2(view.x-318,39),"SCORE",IVORY,14)
	text_at(Vector2(view.x-264,42),"%06d" % GameManager.score,AMBER,26)
	draw_line(Vector2(view.x-159,25),Vector2(view.x-159,45),Color(1,0.9,0.7,0.35))
	var pow_pos := Vector2(view.x-137,27)
	draw_circle(pow_pos+Vector2(4,2),3,IVORY)
	draw_line(pow_pos+Vector2(4,7),pow_pos+Vector2(4,19),IVORY,5,true)
	draw_line(pow_pos+Vector2(0,11),pow_pos+Vector2(8,11),IVORY,2,true)
	text_at(Vector2(view.x-116,41),"POW  %d/%d" % [GameManager.rescued,GameManager.level.pows.size()],IVORY,19)
	grenade(Vector2(34,view.y-65))
	text_at(Vector2(70,view.y-41),str(player.grenades),IVORY,29)
	draw_line(Vector2(115,view.y-65),Vector2(115,view.y-35),Color(1,0.9,0.7,0.35))
	runner(Vector2(144,view.y-68),IVORY)
	var ready: bool = player.dash_recharge<=0
	var dash_text := "DASH READY" if ready else "DASH  %.1fs" % player.dash_recharge
	if driving:
		dash_text = "ON FOOT ONLY"
	elif player.dash_remaining>0:
		dash_text = "DASHING"
	text_at(Vector2(180,view.y-53),dash_text,AMBER if ready and not driving else MUTED,17)
	var charge: float = 0 if driving else clampf(1.0-player.dash_recharge/player.DASH_RECHARGE,0,1)
	for i in 4:
		var px := 181+i*21
		var points := PackedVector2Array([Vector2(px+4,view.y-46),Vector2(px+20,view.y-46),Vector2(px+16,view.y-38),Vector2(px,view.y-38)])
		draw_colored_polygon(points,AMBER if charge>=(i+1)/4.0 else Color(0.25,0.22,0.17))
	var x := view.x-276
	var weapon = player.vehicle.machine_gun if driving else player.weapon
	var title: String = "IRON MULE" if driving else {"pistol":"PISTOL","shotgun":"SHOTGUN","flame":"FLAMETHROWER"}.get(weapon.model_kind,weapon.title.to_upper())
	text_at(Vector2(x+2,view.y-134),title,IVORY,17)
	fitted_icon(SILHOUETTES.get(weapon.model_kind,weapon.icon),Rect2(x,view.y-126,122,42),IVORY)
	var rounds: int = player.magazine_rounds()
	var reserve := "∞" if player.ammo<0 or driving else str(maxi(0,player.ammo-rounds))
	text_at(Vector2(x+142,view.y-94),"∞" if driving else "%02d" % rounds,AMBER if rounds>0 or driving else RED,46)
	text_at(Vector2(x+205,view.y-94),"/ "+reserve,IVORY,23)
	if player.reload_remaining>0:
		text_at(Vector2(x+143,view.y-139),"RECHARGING" if weapon.model_kind=="flame" else "RELOADING",AMBER,11)
		draw_rect(Rect2(x,view.y-81,244*player.reload_progress(),2),AMBER)
	var rects := layout(view)
	var slot := 1
	for kind in ["pistol","shotgun","flame"]:
		var rect: Rect2 = rects[kind]
		var selected: bool = not driving and player.weapon.model_kind==kind
		var available: bool = player.loadout_ammo.get(kind,0)!=0
		var color := AMBER if selected else (Color(0.75,0.72,0.64) if available else MUTED.darkened(0.45))
		var hover := rect.has_point(get_local_mouse_position())
		draw_style_box(chip(Color(0.12,0.085,0.035,0.6) if selected else Color(0.03,0.03,0.025,0.25),color if selected or hover else Color(0.6,0.56,0.45,0.35)),rect)
		draw_style_box(chip(Color.TRANSPARENT,color),Rect2(rect.position+Vector2(6,8),Vector2(15,18)))
		text_at(rect.position+Vector2(10,22),str(slot),color,14)
		fitted_icon(SILHOUETTES[kind],Rect2(rect.position+Vector2(28,5),Vector2(43,24)),color)
		slot+=1
