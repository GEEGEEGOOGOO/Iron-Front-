class_name FxAtlas
extends RefCounted
# Regions from the generated atlas, inset to exclude neighboring effects.
const SHEET = preload("res://assets/art/graphics-upgrade-v1/projectiles.png")
const REGIONS := [
	Rect2(20, 185, 423, 110), Rect2(465, 110, 385, 250),
	Rect2(885, 170, 427, 150), Rect2(1332, 175, 425, 150),
	Rect2(20, 555, 420, 160), Rect2(444, 565, 441, 130),
	Rect2(890, 520, 435, 245), Rect2(1340, 465, 410, 335)
]
static var textures: Dictionary = {}
static func texture(index: int) -> Texture2D:
	if not textures.has(index):
		var atlas := AtlasTexture.new()
		atlas.atlas = SHEET
		atlas.region = REGIONS[index]
		atlas.filter_clip = true
		textures[index] = atlas
	return textures[index]
static func sprite(parent: Node3D) -> Sprite3D:
	var result := Sprite3D.new()
	result.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	result.shaded = false
	result.double_sided = true
	result.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(result)
	return result
static func setup(sprite_node: Sprite3D, index: int) -> void:
	sprite_node.texture = texture(index)
	var rect: Rect2 = REGIONS[index]
	sprite_node.pixel_size = 1.0 / rect.size.x
	# Normalize the artwork to a unit square; caller supplies world dimensions.
	sprite_node.scale = Vector3(1, rect.size.x / rect.size.y, 1)
	sprite_node.modulate = Color.WHITE
