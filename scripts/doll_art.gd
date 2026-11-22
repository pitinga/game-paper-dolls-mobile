extends RefCounted
## Todas as ilustrações são vetores originais desenhados em tempo de execução.
## A composição usa uma prancheta lógica de 540 x 640 para permitir exportar sem UI.

const Catalog = preload("res://scripts/catalog.gd")


static func draw_stage(canvas: CanvasItem, state: Object) -> void:
	draw_background(canvas, int(state.background_index))
	draw_doll(canvas, int(state.model_index), state.outfit, int(state.color_variant))


static func draw_background(canvas: CanvasItem, index: int) -> void:
	var bg: Dictionary = Catalog.BACKGROUNDS[clampi(index, 0, Catalog.BACKGROUNDS.size() - 1)]
	var top: Color = bg["top"]
	var bottom: Color = bg["bottom"]
	for stripe in range(32):
		canvas.draw_rect(Rect2(0, stripe * 20, 540, 21), top.lerp(bottom, float(stripe) / 31.0))
	match index:
		1, 4:
			for x in [34.0, 492.0, 90.0]:
				canvas.draw_line(Vector2(x, 480), Vector2(x, 390), Color("749f71"), 11)
				canvas.draw_circle(Vector2(x, 381), 44, Color("8ccf9a"))
				canvas.draw_circle(Vector2(x - 22, 399), 23, Color("b1e7aa"))
			for x in [68.0, 453.0, 499.0]:
				_flower(canvas, Vector2(x, 540), 11, Color("f890b7"))
		2:
			canvas.draw_circle(Vector2(446, 100), 52, Color("ffdd75"))
			canvas.draw_rect(Rect2(0, 458, 540, 182), Color("ffe4b4"))
			for wave in range(4):
				canvas.draw_arc(Vector2(90 + wave * 110, 459), 76, PI, TAU, 24, Color("76dce0"), 5)
		3:
			for i in range(18):
				var x := float((i * 131 + 53) % 530)
				var y := float((i * 71 + 29) % 475)
				canvas.draw_circle(Vector2(x, y), 5, Color("fff7a7"))
				canvas.draw_circle(Vector2(x + 15, y + 14), 3, Color("ff97b7"))
		5:
			for i in range(26):
				_star(canvas, Vector2(float((i * 137 + 31) % 530), float((i * 79 + 47) % 490)), 4, Color("ffe6a9"))
		6:
			for x in [60.0, 420.0]:
				canvas.draw_rect(Rect2(x, 250, 67, 245), Color("e9c7a9"))
				canvas.draw_rect(Rect2(x - 12, 235, 91, 34), Color("cb88a8"))
				canvas.draw_rect(Rect2(x + 23, 285, 22, 76), Color("8ad1e6"))
		7:
			for i in range(5):
				canvas.draw_arc(Vector2(270, 484), float(175 + i * 22), PI, TAU, 42,
					[Color("ffc4d5"), Color("ffe193"), Color("b7e3b4"), Color("98daf6"), Color("d7b7fb")][i], 12)
	_ellipse(canvas, Rect2(132, 560, 276, 34), Color(0.37, 0.3, 0.41, 0.12))


static func draw_doll(canvas: CanvasItem, model: int, outfit: Dictionary, variant: int) -> void:
	var index := clampi(model, 0, 3)
	var skin: Color = Catalog.MODEL_SKIN[index]
	var hair: Color = Catalog.MODEL_HAIR[index]
	var shadow := skin.darkened(0.16)
	# Legs and feet underneath outfit.
	_round(canvas, Rect2(228, 385, 36, 172), 16, skin)
	_round(canvas, Rect2(277, 385, 36, 172), 16, skin)
	_ellipse(canvas, Rect2(208, 539, 69, 24), skin)
	_ellipse(canvas, Rect2(267, 539, 69, 24), skin)
	canvas.draw_line(Vector2(230, 462), Vector2(262, 462), shadow, 2)
	canvas.draw_line(Vector2(279, 462), Vector2(310, 462), shadow, 2)
	# Body + neck and soft arms.
	_round(canvas, Rect2(249, 230, 42, 49), 16, skin)
	_poly(canvas, [Vector2(228, 272), Vector2(313, 272), Vector2(328, 409), Vector2(216, 409)], skin)
	canvas.draw_line(Vector2(228, 283), Vector2(169, 360), skin, 27, true)
	canvas.draw_line(Vector2(310, 283), Vector2(368, 360), skin, 27, true)
	canvas.draw_circle(Vector2(166, 360), 15, skin)
	canvas.draw_circle(Vector2(370, 360), 15, skin)
	_round(canvas, Rect2(221, 307, 98, 29), 9, Color("f6d7dd"))
	_round(canvas, Rect2(226, 399, 88, 27), 8, Color("f6d7dd"))
	# The face has hair behind and in front, preserving a warm illustrated appearance.
	_ellipse(canvas, Rect2(190, 87, 159, 166), hair)
	_ellipse(canvas, Rect2(196, 112, 147, 144), skin)
	canvas.draw_circle(Vector2(198, 194), 10, skin)
	canvas.draw_circle(Vector2(341, 194), 10, skin)
	canvas.draw_arc(Vector2(236, 186), 13, 0, PI, 15, Color("513a49"), 3)
	canvas.draw_arc(Vector2(304, 186), 13, 0, PI, 15, Color("513a49"), 3)
	for x in [239.0, 303.0]:
		_ellipse(canvas, Rect2(x - 12, 186, 24, 30), Color.WHITE)
		_ellipse(canvas, Rect2(x - 9, 188, 18, 25), Color("3d3548"))
		canvas.draw_circle(Vector2(x - 4, 193), 4, Color.WHITE)
	_ellipse(canvas, Rect2(209, 212, 27, 12), Color(0.93, 0.56, 0.63, 0.35))
	_ellipse(canvas, Rect2(304, 212, 27, 12), Color(0.93, 0.56, 0.63, 0.35))
	canvas.draw_line(Vector2(268, 209), Vector2(265, 223), shadow, 2)
	canvas.draw_arc(Vector2(271, 227), 15, 0.12, PI - 0.12, 15, Color("bf6077"), 3)
	# Forehead bangs and signature look for each model.
	_poly(canvas, [Vector2(193, 160), Vector2(196, 122), Vector2(224, 99),
		Vector2(288, 97), Vector2(339, 119), Vector2(337, 157), Vector2(304, 139),
		Vector2(275, 145), Vector2(248, 129), Vector2(227, 144)], hair)
	if index == 0 or index == 3:
		for x in [206.0, 329.0]:
			canvas.draw_circle(Vector2(x, 107), 35, hair)
	else:
		canvas.draw_line(Vector2(281, 114), Vector2(232, 150), hair.lightened(0.12), 8)
		canvas.draw_arc(Vector2(271, 150), 69, PI * 1.13, PI * 1.84, 24, hair.lightened(0.10), 9)
	# Outfit slots: dresses replace top/bottom by design.
	var dress: Dictionary = Catalog.by_id(str(outfit.get("dress", "")))
	if not dress.is_empty():
		draw_item(canvas, dress, Vector2(270, 365), 1.22, variant)
	else:
		for slot in ["top", "bottom"]:
			var piece: Dictionary = Catalog.by_id(str(outfit.get(slot, "")))
			if not piece.is_empty():
				draw_item(canvas, piece, Vector2(270, 333 if slot == "top" else 421), 1.22, variant)
	var shoes: Dictionary = Catalog.by_id(str(outfit.get("shoes", "")))
	if not shoes.is_empty():
		draw_item(canvas, shoes, Vector2(271, 551), 1.10, variant)
	var new_hair: Dictionary = Catalog.by_id(str(outfit.get("hair", "")))
	if not new_hair.is_empty():
		draw_item(canvas, new_hair, Vector2(270, 110), 1.40, variant)
	var accessory: Dictionary = Catalog.by_id(str(outfit.get("accessory", "")))
	if not accessory.is_empty():
		draw_item(canvas, accessory, Vector2(270, 225), 1.25, variant)


static func draw_item(canvas: CanvasItem, item: Dictionary, at: Vector2, scale_factor: float = 1.0, variant: int = 0) -> void:
	if item.is_empty():
		return
	canvas.draw_set_transform(at, 0.0, Vector2.ONE * scale_factor)
	var color: Color = item["color"]
	# Variações de cor preservam o desenho, sem exigir dezenas de sprites.
	if variant > 0:
		var hue := fposmod(color.h + float(variant) * 0.135, 1.0)
		color = Color.from_hsv(hue, minf(color.s * 1.06, 0.90), color.v, color.a)
	var dark := color.darkened(0.18)
	var light := color.lightened(0.35)
	var slot: String = item["slot"]
	var style: String = item["style"]
	match slot:
		"top":
			var sleeves := 34 if style == "manga" or style == "casaco" else 19
			_poly(canvas, [Vector2(-32, -47), Vector2(-59, -24), Vector2(-54, sleeves - 28),
				Vector2(-34, -15), Vector2(-35, 46), Vector2(35, 46), Vector2(34, -15),
				Vector2(54, sleeves - 28), Vector2(59, -24), Vector2(32, -47)], color)
			canvas.draw_arc(Vector2(0, -45), 11, 0, PI, 14, light, 4)
			canvas.draw_line(Vector2(-35, 44), Vector2(35, 44), dark, 3)
			if style == "casaco":
				canvas.draw_line(Vector2(0, -30), Vector2(0, 44), light, 4)
				for i in range(3):
					canvas.draw_circle(Vector2(5, -12 + i * 20), 2, Color.WHITE)
		"bottom":
			if style == "saia":
				_poly(canvas, [Vector2(-35, -42), Vector2(35, -42), Vector2(53, 52), Vector2(-53, 52)], color)
				canvas.draw_line(Vector2(-35, -36), Vector2(35, -36), dark, 6)
			else:
				var length := 53 if style == "calca" else 15
				_poly(canvas, [Vector2(-37, -43), Vector2(37, -43), Vector2(34, length), Vector2(6, length),
					Vector2(0, -5), Vector2(-6, length), Vector2(-34, length)], color)
				canvas.draw_line(Vector2(-37, -39), Vector2(37, -39), dark, 5)
				canvas.draw_line(Vector2(0, -38), Vector2(0, -19), light, 3)
		"dress":
			_poly(canvas, [Vector2(-30, -62), Vector2(-57, -39), Vector2(-47, -17), Vector2(-34, -25),
				Vector2(-30, 4), Vector2(-63, 85), Vector2(63, 85), Vector2(30, 4),
				Vector2(34, -25), Vector2(47, -17), Vector2(57, -39), Vector2(30, -62)], color)
			canvas.draw_line(Vector2(-30, 5), Vector2(30, 5), dark, 6)
			canvas.draw_line(Vector2(-60, 81), Vector2(60, 81), light, 5)
			canvas.draw_arc(Vector2(0, -62), 12, 0, PI, 12, light, 5)
		"shoes":
			for x in [-29.0, 29.0]:
				_round(canvas, Rect2(x - 23, -14, 46, 28), 13, color)
				canvas.draw_line(Vector2(x - 21, 10), Vector2(x + 21, 10), Color.WHITE, 5)
				if style == "bota":
					_round(canvas, Rect2(x - 13, -25, 26, 21), 5, dark)
				if style == "tenis":
					canvas.draw_line(Vector2(x - 9, -8), Vector2(x + 11, -2), light, 3)
		"hair":
			canvas.draw_arc(Vector2(0, 11), 47, PI, TAU, 24, color, 22)
			match style:
				"coques":
					for x in [-45.0, 45.0]:
						canvas.draw_circle(Vector2(x, -15), 25, color)
				"solto":
					for x in [-46.0, 46.0]:
						_round(canvas, Rect2(x - 11, 0, 22, 69), 9, color)
				"trancas":
					for x in [-48.0, 48.0]:
						for y in range(4):
							canvas.draw_circle(Vector2(x, y * 16), 11, color)
				"cacheado":
					for i in range(9):
						canvas.draw_circle(Vector2(-50 + i * 13, -13 + (i % 2) * 8), 17, color)
		"accessory":
			match style:
				"oculos":
					for x in [-26.0, 26.0]:
						canvas.draw_arc(Vector2(x, -28), 20, 0, TAU, 24, color, 6)
					canvas.draw_line(Vector2(-6, -29), Vector2(6, -29), color, 5)
				"bolsa":
					_round(canvas, Rect2(46, 78, 49, 47), 9, color)
					canvas.draw_arc(Vector2(70, 81), 17, PI, TAU, 18, dark, 5)
				"chapeu", "gorro":
					_ellipse(canvas, Rect2(-57, -90, 114, 17), dark)
					_ellipse(canvas, Rect2(-42, -118, 84, 39), color)
				"coroa":
					_poly(canvas, [Vector2(-40, -76), Vector2(-50, -116), Vector2(-18, -94),
						Vector2(0, -128), Vector2(18, -94), Vector2(50, -116), Vector2(40, -76)], color)
				"laco", "tiara":
					_poly(canvas, [Vector2(-5, -80), Vector2(-50, -105), Vector2(-50, -67),
						Vector2(-5, -70), Vector2(50, -105), Vector2(50, -67), Vector2(5, -80)], color)
					canvas.draw_circle(Vector2(0, -78), 10, dark)
				"colar":
					canvas.draw_arc(Vector2(0, 18), 33, 0.2, PI - 0.2, 20, color, 6)
					_star(canvas, Vector2(0, 51), 10, color)
				"cachecol":
					_round(canvas, Rect2(-38, 36, 76, 17), 8, color)
					_round(canvas, Rect2(17, 40, 16, 70), 5, dark)
	if slot == "top" or slot == "dress":
		_draw_motif(canvas, str(item["motif"]), Vector2(0, -5 if slot == "top" else -12), color)
	canvas.draw_set_transform(Vector2.ZERO)


static func _draw_motif(canvas: CanvasItem, motif: String, center: Vector2, base: Color) -> void:
	var accent := Color("fff5dd")
	match motif:
		"coracao":
			canvas.draw_circle(center + Vector2(-8, -5), 8, accent)
			canvas.draw_circle(center + Vector2(8, -5), 8, accent)
			_poly(canvas, [center + Vector2(-16, -2), center + Vector2(16, -2), center + Vector2(0, 19)], accent)
		"estrela":
			_star(canvas, center, 21, accent)
		"flor":
			_flower(canvas, center, 9, accent)
		"bolinhas":
			for dx in [-20.0, 0.0, 20.0]:
				for dy in [-13.0, 7.0]:
					canvas.draw_circle(center + Vector2(dx, dy), 4, accent)
		"listras":
			for i in range(3):
				canvas.draw_line(center + Vector2(-25, -12 + i * 11), center + Vector2(25, -12 + i * 11), accent, 4)
		"fruta":
			canvas.draw_circle(center, 12, Color("fce2a4"))
			_ellipse(canvas, Rect2(center.x + 2, center.y - 17, 14, 6), Color("6ec69a"))
		"borboleta":
			for x in [-11.0, 11.0]:
				canvas.draw_circle(center + Vector2(x, -7), 11, accent)
				canvas.draw_circle(center + Vector2(x, 8), 8, accent)
			canvas.draw_line(center + Vector2(0, -15), center + Vector2(0, 16), base.darkened(0.3), 4)


static func _poly(canvas: CanvasItem, points: Array[Vector2], color: Color) -> void:
	canvas.draw_colored_polygon(PackedVector2Array(points), color)


static func _ellipse(canvas: CanvasItem, rect: Rect2, color: Color) -> void:
	var points: Array[Vector2] = []
	for i in range(32):
		var angle := float(i) * TAU / 32.0
		points.append(rect.get_center() + Vector2(cos(angle) * rect.size.x * 0.5, sin(angle) * rect.size.y * 0.5))
	_poly(canvas, points, color)


static func _round(canvas: CanvasItem, rect: Rect2, radius: float, color: Color) -> void:
	canvas.draw_rect(Rect2(rect.position.x + radius, rect.position.y, rect.size.x - 2 * radius, rect.size.y), color)
	canvas.draw_rect(Rect2(rect.position.x, rect.position.y + radius, rect.size.x, rect.size.y - 2 * radius), color)
	for center in [rect.position + Vector2(radius, radius), rect.position + Vector2(rect.size.x - radius, radius),
				rect.position + Vector2(radius, rect.size.y - radius), rect.end - Vector2(radius, radius)]:
		canvas.draw_circle(center, radius, color)


static func _flower(canvas: CanvasItem, point: Vector2, petal_radius: float, color: Color) -> void:
	for i in range(6):
		var angle := float(i) * TAU / 6.0
		canvas.draw_circle(point + Vector2.from_angle(angle) * petal_radius, petal_radius * 0.65, color)
	canvas.draw_circle(point, petal_radius * 0.6, Color("f5c75d"))


static func _star(canvas: CanvasItem, point: Vector2, radius: float, color: Color) -> void:
	var vertices: Array[Vector2] = []
	for i in range(10):
		var r := radius if i % 2 == 0 else radius * 0.44
		vertices.append(point + Vector2.from_angle(-PI / 2.0 + i * PI / 5.0) * r)
	_poly(canvas, vertices, color)
