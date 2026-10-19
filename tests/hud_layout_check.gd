extends SceneTree
# Geometry-only check: no mission or game scene is instantiated.
func _initialize() -> void:
	var errors := 0
	for view in [Vector2(1280, 720), Vector2(1920, 1080), Vector2(1600, 900), Vector2(1280, 960)]:
		var rects := preload("res://scripts/ui/hud_layout.gd").rects(view)
		var viewport := Rect2(Vector2.ZERO, view)
		for key in rects:
			if not viewport.encloses(rects[key]):
				push_error("HUD input area is offscreen: " + key)
				errors += 1
		for pair in [["pistol", "shotgun"], ["shotgun", "flame"], ["reload", "switch"], ["dash", "pistol"]]:
			if rects[pair[0]].intersects(rects[pair[1]]):
				push_error("HUD click targets overlap")
				errors += 1
		if rects.flame.end.x != view.x - 30 or rects.flame.end.y != view.y - 38:
			push_error("Weapon strip must remain anchored to the safe margin")
			errors += 1
	print("HUD LAYOUT CHECK ", "PASS" if errors == 0 else "FAIL")
	quit(0 if errors == 0 else 1)
