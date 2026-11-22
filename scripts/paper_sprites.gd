extends RefCounted
## Recortes das pranchas enviadas pelo usuário. Roupas e bonecas usam sempre
## as mesmas coordenadas de montagem (540x640): não dependem da tela Android.

const Catalog = preload("res://scripts/catalog.gd")
const FOLDER := "res://assets/paper/"
const DOLL_RECT := Rect2(120, 64, 300, 520)
const TOP_RECT := Rect2(200, 351, 140, 118)
const SHORTS_RECT := Rect2(215, 440, 110, 72)
const PANTS_RECT := Rect2(216, 439, 108, 129)
const DRESS_RECT := Rect2(180, 347, 180, 204)
const FOOT_BASELINE := 584.0

static var _cache: Dictionary = {}
# Cache missing resources too: draw loops must not recheck disk every frame.


static func _texture(name: String) -> Texture2D:
	if _cache.has(name):
		return _cache[name]
	var path := FOLDER + name + ".png"
	var result: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_cache[name] = result
	return result


static func _sprite_name(item: Dictionary) -> String:
	var id := str(item.get("id", ""))
	if id.begins_with("pro_"):
		var parts := id.split("_")
		if parts.size() == 3:
			var category := parts[1]
			var index := int(parts[2]) + 4
			var count := 6 if category == "shoes" else 8
			return "%s_%02d" % [category, index % count]
	return id


static func _fit_centered(canvas: CanvasItem, name: String, rect: Rect2, color: Color = Color.WHITE) -> bool:
	var texture := _texture(name)
	if texture == null:
		return false
	var original := texture.get_size()
	var factor := minf(rect.size.x / original.x, rect.size.y / original.y)
	var displayed := original * factor
	var at := rect.position + (rect.size - displayed) * 0.5
	canvas.draw_texture_rect(texture, Rect2(at, displayed), false, color)
	return true


static func _fit_top(canvas: CanvasItem, name: String, rect: Rect2, color: Color = Color.WHITE) -> bool:
	var texture := _texture(name)
	if texture == null:
		return false
	var original := texture.get_size()
	var factor := minf(rect.size.x / original.x, rect.size.y / original.y)
	var displayed := original * factor
	canvas.draw_texture_rect(texture, Rect2(Vector2(rect.get_center().x - displayed.x * 0.5, rect.position.y), displayed), false, color)
	return true


static func draw_stage(canvas: CanvasItem, state: Object) -> void:
	var name := "model_%d" % clampi(int(state.model_index), 0, 3)
	var outfit: Dictionary = state.outfit
	var shoes := Catalog.by_id(str(outfit.get("shoes", "")))
	var hair := Catalog.by_id(str(outfit.get("hair", "")))
	# Alongamentos de cabelo passam atrás do rosto. Os detalhes de cada
	# penteado entram DEPOIS do modelo, para não desaparecerem sob a imagem.
	if not hair.is_empty() and str(hair.get("style", "")) != "coques":
		_draw_hair_back(canvas, hair, int(state.model_index))
	_fit_centered(canvas, name + ("_bare" if not shoes.is_empty() else ""), DOLL_RECT)
	var color_variant := int(state.color_variant)
	var dress := Catalog.by_id(str(outfit.get("dress", "")))
	if not dress.is_empty():
		draw_item_on_doll(canvas, dress, color_variant)
	else:
		for slot in ["top", "bottom"]:
			var piece := Catalog.by_id(str(outfit.get(slot, "")))
			if not piece.is_empty():
				draw_item_on_doll(canvas, piece, color_variant)
	if not shoes.is_empty():
		draw_item_on_doll(canvas, shoes, color_variant)
	var accessory := Catalog.by_id(str(outfit.get("accessory", "")))
	if not accessory.is_empty():
		draw_item_on_doll(canvas, accessory, color_variant)
	if not hair.is_empty():
		_draw_hair_front(canvas, hair, int(state.model_index))


static func _draw_hair_back(canvas: CanvasItem, item: Dictionary, model_index: int) -> void:
	# A arte de origem contém o penteado-base; extensões não cobrem olhos nem
	# modificam a cor da pele. Este é um complemento, não uma peruca integral.
	var hair: Color = Catalog.MODEL_HAIR[clampi(model_index, 0, 3)]
	var shine := hair.lightened(0.21)
	match str(item.get("style", "")):
		"solto":
			for side in [-1.0, 1.0]:
				var x: float = 270.0 + side * 101.0
				var strand := PackedVector2Array([Vector2(x, 195), Vector2(x + side * 8, 252),
					Vector2(x + side * 6, 314), Vector2(x + side * 4, 351)])
				canvas.draw_polyline(strand, hair, 29, true)
				canvas.draw_polyline(strand, shine, 4, true)
				canvas.draw_circle(strand[-1], 14, hair)
		"trancas":
			for side in [-1.0, 1.0]:
				var x: float = 270.0 + side * 104.0
				for i in range(7):
					var at := Vector2(x + side * (i % 2) * 5, 223 + i * 18)
					canvas.draw_circle(at, 11, hair)
					canvas.draw_circle(at + Vector2(-3, -4), 2.4, shine)
		"cacheado":
			for side in [-1.0, 1.0]:
				for i in range(6):
					var at := Vector2(270 + side * (101 + (i % 2) * 7), 224 + i * 20)
					canvas.draw_circle(at, 12, hair)
					canvas.draw_arc(at, 8, PI * 1.1, PI * 1.9, 12, shine, 2.5)


static func _draw_hair_front(canvas: CanvasItem, item: Dictionary, model_index: int) -> void:
	# O cabelo da prancha é parte da imagem original: não desenhar ondas e
	# arcos genéricos sobre a franja. Na v5 eles pareciam riscos/brancos no rosto.
	match str(item.get("style", "")):
		"coques":
			for x in [189.0, 351.0]:
				canvas.draw_circle(Vector2(x, 120), 7, Color("e6a6c2"))
				canvas.draw_circle(Vector2(x, 120), 3, Color("fff2f7"))
		"trancas":
			for side in [-1.0, 1.0]:
				canvas.draw_circle(Vector2(270 + side * 107, 341), 6, Color("e6a6c2"))
		# Solto e cacheado usam apenas as extensões atrás do rosto.


static func _tint(variant: int) -> Color:
	# Tinta translúcida leve: modifica a roupa, mas preserva os desenhos e motivos.
	return [Color.WHITE, Color("ffe2d9"), Color("e8dbff"), Color("d7ffe4"), Color("ffe0f1")][clampi(variant, 0, 4)]


static func _shoe_rect_for_style(style: String) -> Rect2:
	var height := 57.0 if style in ["bota", "tenis"] else 37.0
	return Rect2(202, FOOT_BASELINE - height, 136, height)


static func draw_item_on_doll(canvas: CanvasItem, item: Dictionary, variant: int = 0) -> void:
	var slot := str(item["slot"])
	var name := _sprite_name(item)
	var tint := _tint(variant)
	match slot:
		"top": _fit_top(canvas, name, TOP_RECT, tint)
		"bottom":
			# Fit by source cutout, not by inconsistent catalog style.
			var is_long := name in ["bottom_01", "bottom_04", "bottom_05", "bottom_07"]
			_fit_top(canvas, name, PANTS_RECT if is_long else SHORTS_RECT, tint)
		"dress": _fit_top(canvas, name, DRESS_RECT, tint)
		"shoes":
			# O corte do modelo preserva as pernas, mas retira as sandálias de
			# origem. Todos os calçados terminam no MESMO piso (y=584); botas
			# cobrem os tornozelos, sapatilhas começam na altura do pé.
			_fit_centered(canvas, name, _shoe_rect_for_style(str(item["style"])), tint)
		"accessory":
			var style := str(item["style"])
			var region: Rect2
			match style:
				"oculos": region = Rect2(205, 215, 130, 70)
				"bolsa": region = Rect2(340, 370, 94, 100)
				"chapeu": region = Rect2(188, 70, 164, 90)
				"colar": region = Rect2(236, 333, 68, 58)
				_: region = Rect2(208, 104, 124, 76)
			if not _fit_centered(canvas, name, region, tint):
				# Nove acessórios são vetoriais; antes a ausência de PNG fazia
				# com que eles aparecessem no card, mas NÃO na boneca.
				var Art = load("res://scripts/doll_art.gd")
				var at := Vector2(270, 320)
				match style:
					"bolsa": at = Vector2(270, 330)
					"oculos": at = Vector2(270, 270)
					"chapeu", "gorro", "coroa", "laco", "tiara": at = Vector2(270, 209)
					"cachecol": at = Vector2(270, 329)
				Art.draw_item(canvas, item, at, 0.85, variant)


static func draw_item_thumbnail(canvas: CanvasItem, item: Dictionary, center: Vector2, size: Vector2) -> void:
	var name := _sprite_name(item)
	if not _fit_centered(canvas, name, Rect2(center - size * 0.5, size)):
		# Cabelos e acessórios sem recorte continuam identificáveis no catálogo.
		var Art = load("res://scripts/doll_art.gd")
		Art.draw_item(canvas, item, center, 0.56)


static func draw_model_preview(canvas: CanvasItem, model_index: int, rect: Rect2) -> void:
	_fit_centered(canvas, "model_%d" % model_index, rect)
