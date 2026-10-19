class_name CombatHUDLayout
extends RefCounted
# Drawing and mouse targets share these edge-anchored rectangles.
static func rects(view: Vector2) -> Dictionary:
	var x := view.x - 276.0
	var y := view.y - 72.0
	return {
		"switch": Rect2(x, view.y - 152, 124, 70),
		"reload": Rect2(x + 128, view.y - 136, 116, 54),
		"dash": Rect2(140, view.y - 82, 184, 54),
		"pistol": Rect2(x, y, 78, 34),
		"shotgun": Rect2(x + 84, y, 78, 34),
		"flame": Rect2(x + 168, y, 78, 34),
	}
