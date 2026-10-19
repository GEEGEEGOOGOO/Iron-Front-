extends Node
## Headless UI structure and signal checks; never starts a mission.
var deployed_index := -1

func _ready() -> void:
	var menu := preload("res://scripts/ui/campaign_menu.gd").new()
	add_child(menu)
	assert(menu.home_page.visible)
	assert(not menu.missions_page.visible)
	assert(not menu.cards[0].is_visible_in_tree())
	menu.deployed.connect(func(index: int): deployed_index = index)
	menu.play_button.pressed.emit()
	assert(menu.missions_page.visible)
	assert(not menu.home_page.visible)
	assert(deployed_index == -1)
	assert(menu.cards.size() == 3)
	assert(menu.selected == 1)
	assert(menu.pictures[1].texture == menu.DUST_MAP)
	assert(menu.pictures[0].texture.atlas == menu.ASHFALL_MAP)
	assert(menu.pictures[2].texture.atlas == menu.FOUNDRY_MAP)
	for i in 3:
		assert(menu.pictures[i].visible)
		assert(menu.pictures[i].size == Vector2(138, 76))
		assert(menu.pictures[i].position == Vector2(3, 3))
		assert(menu.cards[i].position.x == menu.cards[0].position.x)
		assert(menu.cards[i].size == Vector2(432, 82))
		if i > 0:
			assert(menu.cards[i].position.y >= menu.cards[i-1].position.y + menu.cards[i-1].size.y + 10)
	assert(menu.cards[2].position.y + menu.cards[2].size.y < menu.best_label.position.y)
	assert(menu.best_label.position.y + menu.best_label.size.y < menu.deploy_button.position.y)
	menu.select_mission(2)
	assert(deployed_index == -1)
	menu.deploy_button.pressed.emit()
	assert(deployed_index == 2)
	menu.select_mission(0)
	assert(menu.selected == 0)
	menu.back_button.pressed.emit()
	assert(menu.home_page.visible)
	assert(not menu.missions_page.visible)
	menu.play_button.pressed.emit()
	assert(menu.selected == 0)
	menu._unhandled_input(_cancel_event())
	assert(menu.home_page.visible)
	menu.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	for viewport_size in [Vector2(1280, 720), Vector2(1920, 1080), Vector2(1024, 768)]:
		menu.size = viewport_size
		menu.update_layout()
		assert(menu.content.position.x >= -0.01)
		assert(menu.content.position.y >= -0.01)
		assert(menu.content.position.x + menu.BASE_SIZE.x * menu.content.scale.x <= viewport_size.x + 0.01)
		assert(menu.content.position.y + menu.BASE_SIZE.y * menu.content.scale.y <= viewport_size.y + 0.01)
	print("CAMPAIGN MENU CHECK PASS: thumbnails, selection, deploy signal, responsive composition")
	get_tree().quit()

func _cancel_event() -> InputEventAction:
	var event := InputEventAction.new()
	event.action = "ui_cancel"
	event.pressed = true
	return event
