extends RefCounted
## Only original, licensed-for-this-project paper dolls are rendered.
## Both Free and Pro are on a shared 1024x1536 transparent source canvas.
const Catalog = preload("res://scripts/catalog.gd")
const FreeCollection = preload("res://scripts/free_collection.gd")
const KawaiiCollection = preload("res://scripts/kawaii_collection.gd")

const DOLL_RECT := Rect2(120, 64, 300, 520)
const TEXTURE_CACHE_LIMIT := 12

static var _cache: Dictionary = {}
static var _image_lru: Array[String] = []
static var _sprite_bounds: Dictionary = {}


static func _image_path(name: String) -> String:
	if name.begins_with("free_kawaii/"):
		return "res://assets/free_kawaii/" + name.trim_prefix("free_kawaii/") + ".png"
	if name.begins_with("kawaii/"):
		return "res://assets/kawaii/" + name.trim_prefix("kawaii/") + ".png"
	return ""


static func _texture(name: String) -> Texture2D:
	# Full-resolution sprites are large; no old paper sprites are fallback assets.
	if _cache.has(name):
		if _cache[name] != null:
			_image_lru.erase(name)
			_image_lru.append(name)
		return _cache[name]
	var path := _image_path(name)
	var result: Texture2D = null
	if not path.is_empty() and ResourceLoader.exists(path):
		result = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	_cache[name] = result
	if result != null:
		_image_lru.append(name)
		while _image_lru.size() > TEXTURE_CACHE_LIMIT:
			_cache.erase(_image_lru.pop_front())
	return result


static func _sprite_name(item: Dictionary) -> String:
	return str(item.get("sprite", ""))


static func _model_sprite(model_index: int) -> String:
	if model_index >= Catalog.KAWAII_MODEL_INDEX:
		var premium_index := model_index - Catalog.KAWAII_MODEL_INDEX
		if premium_index >= 0 and premium_index < KawaiiCollection.MODEL_SPRITES.size():
			return "kawaii/" + str(KawaiiCollection.MODEL_SPRITES[premium_index])
		return ""
	if model_index >= 0 and model_index < FreeCollection.MODEL_SPRITES.size():
		return "free_kawaii/" + str(FreeCollection.MODEL_SPRITES[model_index])
	return ""


static func _kawaii_model_sprite(model_index: int) -> String:
	return _model_sprite(model_index)


static func _fit_centered(canvas: CanvasItem, name: String, rect: Rect2,
		color: Color = Color.WHITE) -> bool:
	var tex := _texture(name)
	if tex == null:
		return false
	var original := tex.get_size()
	var ratio := minf(rect.size.x / original.x, rect.size.y / original.y)
	var size := original * ratio
	canvas.draw_texture_rect(tex, Rect2(rect.position + (rect.size - size) * 0.5, size), false, color)
	return true


static func draw_stage(canvas: CanvasItem, state: Object) -> void:
	var index: int = int(state.model_index)
	var model_sprite := _model_sprite(index)
	if model_sprite.is_empty():
		return
	_fit_centered(canvas, model_sprite, DOLL_RECT)
	var outfit: Dictionary = state.outfit
	var dress: Dictionary = Catalog.by_id(str(outfit.get("dress", "")))
	if not dress.is_empty() and Catalog.item_matches_model(dress, index):
		draw_item_on_doll(canvas, dress, int(state.color_variant))
	else:
		for slot in ["top", "bottom"]:
			var piece: Dictionary = Catalog.by_id(str(outfit.get(slot, "")))
			if not piece.is_empty() and Catalog.item_matches_model(piece, index):
				draw_item_on_doll(canvas, piece, int(state.color_variant))
	for slot in ["shoes", "accessory"]:
		var piece: Dictionary = Catalog.by_id(str(outfit.get(slot, "")))
		if not piece.is_empty() and Catalog.item_matches_model(piece, index):
			draw_item_on_doll(canvas, piece, int(state.color_variant))


static func draw_item_on_doll(canvas: CanvasItem, item: Dictionary, _variant: int = 0) -> void:
	var name := _sprite_name(item)
	if not name.is_empty():
		_fit_centered(canvas, name, DOLL_RECT)


static func _visible_bounds(name: String, texture: Texture2D) -> Rect2i:
	if _sprite_bounds.has(name):
		return _sprite_bounds[name]
	var image := texture.get_image()
	if image == null or image.is_empty():
		return Rect2i()
	var lo := Vector2i(image.get_width(), image.get_height())
	var hi := Vector2i(-1, -1)
	for y in range(0, image.get_height(), 8):
		for x in range(0, image.get_width(), 8):
			if image.get_pixel(x, y).a >= 0.65:
				lo.x = mini(lo.x, x)
				lo.y = mini(lo.y, y)
				hi.x = maxi(hi.x, x)
				hi.y = maxi(hi.y, y)
	if hi.x < lo.x or hi.y < lo.y:
		return Rect2i()
	var bounds := Rect2i(lo - Vector2i(12, 12), hi - lo + Vector2i(32, 32))
	bounds = bounds.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	_sprite_bounds[name] = bounds
	return bounds


static func draw_item_thumbnail(canvas: CanvasItem, item: Dictionary,
		center: Vector2, size: Vector2) -> void:
	var name := _sprite_name(item)
	var texture := _texture(name)
	if texture == null:
		return
	var used := _visible_bounds(name, texture)
	if used.size.x <= 0 or used.size.y <= 0:
		return
	var scale := minf(size.x / used.size.x, size.y / used.size.y)
	var dest := Vector2(used.size) * scale
	canvas.draw_texture_rect_region(texture, Rect2(center - dest * 0.5, dest), Rect2(used))


static func draw_model_preview(canvas: CanvasItem, model_index: int, rect: Rect2) -> void:
	var name := _model_sprite(model_index)
	if not name.is_empty():
		_fit_centered(canvas, name, rect)


static func _shoe_rect_for_style(style: String) -> Rect2:
	# Legacy helper retained for tooling, not used for full-canvas original art.
	var height := 57.0 if style in ["bota", "tenis"] else 37.0
	return Rect2(202, 584.0 - height, 136, height)
