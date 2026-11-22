extends Control

const Catalog = preload("res://scripts/catalog.gd")
const Art = preload("res://scripts/doll_art.gd")
const Sprites = preload("res://scripts/paper_sprites.gd")
const StudioState = preload("res://scripts/studio_state.gd")
const PortraitCanvas = preload("res://scripts/portrait_canvas.gd")
const BillingBridge = preload("res://scripts/play_billing_bridge.gd")
const AndroidGallery = preload("res://scripts/android_gallery.gd")
const EXPORT_FOLDER := "user://criacoes"
const ENTITLEMENT_FILE := "user://paper_dolls_pro.cfg"
const WARDROBE_HEIGHT := 360.0
# Never sell duplicated placeholder art. Enable only after unique licensed Pro assets ship.
const PRO_SALES_ENABLED := false

var state: RefCounted
var screen := "home"
var category := "top"
var page := 0
var active_finger := -99
var dragging_id := ""
var drag_pos := Vector2.ZERO
var drag_origin := Vector2.ZERO
var toast := ""
var toast_elapsed := 0.0
var exported_path := ""
var gallery_uri := ""
var billing: Node
var billing_price := ""
var billing_available := false
var billing_busy := false
var _saving := false
var _export_serial := 0
var _clear_armed := false
var _clear_timeout := 0.0
var _portrait_view: SubViewport
var _portrait: Node2D
var studio_storage_path := StudioState.STORAGE_PATH
var entitlement_file := ENTITLEMENT_FILE
var export_folder := EXPORT_FOLDER
var _pro_test_build := false


func _ready() -> void:
	state = StudioState.new()
	state.storage_path = studio_storage_path
	# O desbloqueio de teste só existe com os DOIS requisitos: APK de debug
	# e preset dedicado. Nunca é ativado no pacote publicado pela Play Store.
	_pro_test_build = OS.is_debug_build() and OS.has_feature("paper_dolls_pro_test")
	state.owned_pro = _pro_test_build or _load_positive_entitlement()
	state.load_saved()
	_portrait_view = SubViewport.new()
	_portrait_view.name = "PortraitViewport"
	_portrait_view.size = Vector2i(540, 640)
	_portrait_view.transparent_bg = false
	_portrait_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_portrait_view)
	_portrait = PortraitCanvas.new()
	_portrait.studio_state = state
	_portrait_view.add_child(_portrait)
	resized.connect(queue_redraw)
	billing = BillingBridge.new()
	billing.name = "PlayBilling"
	add_child(billing)
	billing.entitlement_checked.connect(_on_entitlement_checked)
	billing.price_changed.connect(func(price: String) -> void:
		billing_price = price
		queue_redraw())
	billing.availability_changed.connect(func(available: bool) -> void:
		billing_available = available
		queue_redraw())
	billing.purchase_message.connect(_show_message)
	billing.checkout_changed.connect(func(busy: bool) -> void:
		billing_busy = busy
		queue_redraw())
	if not _pro_test_build:
		billing.start()
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if state != null:
			state.save()
	# No APK Pro Test o Billing não foi iniciado. Fazer refresh ao voltar do
	# segundo plano emitia indevidamente "Google Play indisponível" na V5.
	if what == NOTIFICATION_APPLICATION_RESUMED and billing != null and not _pro_test_build:
		billing.refresh()


func _process(delta: float) -> void:
	if _clear_timeout > 0.0:
		_clear_timeout -= delta
		if _clear_timeout <= 0.0:
			_clear_armed = false
			queue_redraw()
	if toast_elapsed > 0.0:
		toast_elapsed -= delta
		if toast_elapsed <= 0.0:
			toast = ""
		queue_redraw()


func _draw() -> void:
	var bounds := get_rect().size
	if _portrait != null:
		_portrait.queue_redraw()
	draw_rect(Rect2(Vector2.ZERO, bounds), Color("fffafc"))
	match screen:
		"home": _draw_home(bounds)
		"studio": _draw_studio(bounds)
		"models": _draw_models(bounds)
		"background": _draw_backgrounds(bounds)
		"challenges": _draw_challenges(bounds)
		"finish": _draw_finish(bounds)
		"pro": _draw_pro(bounds)
		"games": _draw_games(bounds)
	if not dragging_id.is_empty():
		var item: Dictionary = Catalog.by_id(dragging_id)
		if not item.is_empty():
			Sprites.draw_item_thumbnail(self, item, drag_pos + Vector2(0, -34), Vector2(100, 110))
	if not toast.is_empty():
		var toast_rect := _toast_rect(bounds)
		_draw_pill(toast_rect, Color("4b3a58"))
		_label(toast, toast_rect.get_center() + Vector2(0, 6), 17, Color.WHITE, toast_rect.size.x - 24)


func _toast_rect(bounds: Vector2) -> Rect2:
	# Nunca esconder o progresso do desafio nem os comandos do guarda-roupa.
	var y := bounds.y - WARDROBE_HEIGHT - 56 if screen == "studio" else bounds.y - 425.0
	return Rect2(18, y, bounds.x - 36, 46)


func _draw_home(bounds: Vector2) -> void:
	var cx := bounds.x * 0.5
	_label("VESTE & CRIA", Vector2(cx, 79), 37, Color("412d3d"))
	_label("Bonecas de Papel", Vector2(cx, 114), 20, Color("74465e"))
	var actions_y := bounds.y - 337.0
	var art_height := minf(620.0, maxf(280.0, actions_y - 194.0))
	_draw_portrait_fitted(Rect2(10, 135, bounds.x - 20, art_height))
	_label("Crie looks, combine e salve!", Vector2(cx, 135 + art_height + 33), 21, Color("53394b"))
	_action(Rect2(26, bounds.y - 325, bounds.x - 52, 62), "COMEÇAR A VESTIR", true)
	_action(Rect2(26, bounds.y - 250, bounds.x - 52, 53), "ESCOLHER MODELO", false)
	_action(Rect2(26, bounds.y - 185, bounds.x - 52, 53), "DESAFIOS DE LOOK", false)
	_action(Rect2(26, bounds.y - 120, (bounds.x - 62) * 0.5, 49), "PRO", false)
	_action(Rect2(bounds.x * 0.5 + 5, bounds.y - 120, (bounds.x - 62) * 0.5, 49), "MAIS JOGOS", false)
	_label("Crie • Salve • Compartilhe", Vector2(cx, bounds.y - 21), 14, Color("705066"))


func _draw_studio(bounds: Vector2) -> void:
	var stage_height := bounds.y - 108.0 - WARDROBE_HEIGHT
	_draw_pill(Rect2(0, 0, bounds.x, 108), Color("fffafc"))
	var header_buttons := _studio_header_rects(bounds.x)
	_button(header_buttons[0], "‹ VOLTAR")
	_button(header_buttons[1], "DESAFIO")
	_button(header_buttons[2], "PRO" if not state.owned_pro else "★ PRO")
	_button(header_buttons[3], "SALVAR")
	var stage_rect := Rect2(0, 108, bounds.x, stage_height)
	_draw_portrait_fitted(stage_rect)
	if state.challenge_index >= 0:
		var challenge: Dictionary = Catalog.CHALLENGES[state.challenge_index]
		_draw_pill(Rect2(18, 121, bounds.x - 36, 36), Color("ffffff", 0.92))
		var completed: bool = state.completed_challenges.has(state.challenge_index)
		_label("%s  •  %d/2%s" % [challenge["name"], state.challenge_progress(), " ★" if completed else ""],
			Vector2(bounds.x * 0.5, 145), 17, Color("68436b"))
	_draw_wardrobe(bounds)


func _studio_header_rects(width: float) -> Array[Rect2]:
	# Percentuais aplicados ao espaço útil: quatro áreas sem interseção
	# também em 360 dp, com o mesmo desenho e alvo de toque.
	var margin := 8.0
	var gap := 7.0
	var usable := width - margin * 2.0 - gap * 3.0
	var weights := [0.22, 0.27, 0.23, 0.28]
	var positions: Array[Rect2] = []
	var x := margin
	for weight in weights:
		var button_width: float = usable * weight
		positions.append(Rect2(x, 32, button_width, 48))
		x += button_width + gap
	return positions


func _draw_wardrobe(bounds: Vector2) -> void:
	var top := bounds.y - WARDROBE_HEIGHT
	_draw_pill(Rect2(0, top, bounds.x, WARDROBE_HEIGHT), Color("fffafc"))
	for i in range(Catalog.CATEGORIES.size()):
		var slot: String = Catalog.CATEGORIES[i]
		var width := bounds.x / 6.0
		var selected := slot == category
		_draw_pill(Rect2(i * width + 3, top + 11, width - 6, 49), Color("ad356c") if selected else Color("f3e3ea"))
		_label(["Blusas", "Baixo", "Vestidos", "Pés", "Cabelos", "Extras"][i],
			Vector2((i + 0.5) * width, top + 36), 14, Color.WHITE if selected else Color("4f3045"), width - 6)
	var items: Array[Dictionary] = Catalog.filtered(category)
	var start := page * 4
	for i in range(4):
		var x := 12 + i * ((bounds.x - 24) / 4.0)
		var card := Rect2(x + 2, top + 62, (bounds.x - 24) / 4.0 - 6, 127)
		_draw_pill(card, Color("ffffff"))
		if start + i >= items.size():
			continue
		var item: Dictionary = items[start + i]
		var selected: bool = str(state.outfit.get(category, "")) == str(item["id"])
		if selected:
			draw_rect(card.grow(1), Color("a62b64"), false, 4.0)
			_label("✓", Vector2(card.position.x + 15, card.position.y + 22), 17, Color("a62b64"))
		if state.challenge_index >= 0 and str(item["tag"]) == str(Catalog.CHALLENGES[state.challenge_index]["tag"]):
			_label("✦", Vector2(card.end.x - 12, card.position.y + 22), 15, Color("a62b64"))
		var locked: bool = bool(item["pro"]) and not state.owned_pro
		Sprites.draw_item_thumbnail(self, item, Vector2(card.get_center().x, card.position.y + 57), Vector2(108, 88))
		if locked:
			_draw_pill(Rect2(card.position.x + 50, card.position.y + 8, card.size.x - 55, 24), Color("76537c"))
			_label("PRO", Vector2(card.end.x - 32, card.position.y + 26), 12, Color.WHITE)
		_label(str(item["name"]), Vector2(card.get_center().x, card.end.y - 8), 12, Color("624b60"))
	var total_pages := maxi(1, ceili(float(items.size()) / 4.0))
	_button(Rect2(12, top + 198, 74, 48), "‹")
	_label("%s  %d/%d" % [Catalog.CATEGORY_NAMES[category], page + 1, total_pages],
		Vector2(bounds.x * 0.5, top + 225), 16, Color("6b506b"))
	_button(Rect2(bounds.x - 86, top + 198, 74, 48), "›")
	var filter_colors: Array[Color] = [Color.WHITE, Color("ffe2d9"), Color("e8dbff"), Color("d7ffe4"), Color("ffe0f1")]
	for i in range(5):
		var pos := Vector2(bounds.x * 0.5 - 96 + i * 48, top + 276)
		draw_circle(pos, 15 if i != state.color_variant else 18, filter_colors[i])
		draw_arc(pos, 16 if i != state.color_variant else 19, 0, TAU, 24, Color("c6a9ba"), 1.5)
		if i == state.color_variant:
			draw_arc(pos, 23, 0, TAU, 24, Color("795474"), 3)
	_label("Tom", Vector2(35 if bounds.x < 430 else 65, top + 283), 15, Color("71546c"))
	var bottom_y := bounds.y - 56
	for i in range(4):
		var labels := ["DESFAZER", "TIRAR", "CENÁRIO", "CONFIRMAR" if _clear_armed else "LIMPAR"]
		var w := (bounds.x - 20) / 4.0
		_button(Rect2(6 + i * w, bottom_y, w - 5, 48), labels[i])


func _draw_models(bounds: Vector2) -> void:
	_draw_page_title(bounds, "Escolha seu modelo", "Os quatro usam as mesmas roupas")
	for index in range(4):
		var col := index % 2
		var row := index / 2
		var width := (bounds.x - 48) * 0.5
		var rect := Rect2(16 + col * (width + 16), 165 + row * 270, width, 253)
		_draw_pill(rect, Color("ffecf4") if index == state.model_index else Color.WHITE)
		Sprites.draw_model_preview(self, index, Rect2(rect.position + Vector2(9, 9), Vector2(width - 18, 213)))
		_label(Catalog.MODEL_NAMES[index] + (" ✓" if index == state.model_index else ""),
			Vector2(rect.get_center().x, rect.end.y - 14), 20, Color("64445f"))


func _draw_backgrounds(bounds: Vector2) -> void:
	_draw_page_title(bounds, "Escolha o cenário", "Uma paisagem para cada criação")
	for index in range(Catalog.BACKGROUNDS.size()):
		var col := index % 2
		var row := index / 2
		var width := (bounds.x - 48) * 0.5
		var rect := Rect2(16 + col * (width + 16), 158 + row * 181, width, 162)
		var bg: Dictionary = Catalog.BACKGROUNDS[index]
		_draw_pill(rect, Color.WHITE)
		var preview := Rect2(rect.position + Vector2(8, 8), Vector2(rect.size.x - 16, 120))
		# Prévia da cena real (árvores/estrelas/praia) em vez de faixas de cor.
		draw_set_transform(preview.position, 0.0, Vector2(preview.size.x / 540.0, preview.size.y / 640.0))
		Art.draw_background(self, index)
		draw_set_transform(Vector2.ZERO)
		Sprites.draw_model_preview(self, state.model_index,
			Rect2(preview.get_center().x - 27, preview.position.y + 4, 54, preview.size.y - 8))
		var selected: bool = index == state.background_index
		if selected:
			draw_rect(rect.grow(1), Color("a62b64"), false, 4)
		var locked: bool = bool(bg["pro"]) and not state.owned_pro
		_label(str(bg["name"]) + (" 🔒" if locked else "") + (" ✓" if selected else ""),
			Vector2(rect.get_center().x, rect.end.y - 15), 16, Color("62435d"), rect.size.x - 14)


func _draw_challenges(bounds: Vector2) -> void:
	_draw_page_title(bounds, "Desafios de looks", "Sem tempo limite: crie no seu ritmo")
	for i in range(Catalog.CHALLENGES.size()):
		var challenge: Dictionary = Catalog.CHALLENGES[i]
		var rect := Rect2(24, 165 + i * 113, bounds.x - 48, 94)
		var completed: bool = state.completed_challenges.has(i)
		_draw_pill(rect, Color("e5f6eb") if completed else Color("ffecf4"))
		_label(("★ " if completed else "✦ ") + str(challenge["name"]), Vector2(bounds.x * 0.5, rect.position.y + 37), 22, Color("67435c"))
		_label(str(challenge["hint"]), Vector2(bounds.x * 0.5, rect.position.y + 67), 15, Color("9c6a80"))
	_action(Rect2(36, bounds.y - 96, bounds.x - 72, 54), "JOGAR LIVRE", false)


func _draw_finish(bounds: Vector2) -> void:
	_draw_page_title(bounds, "Seu look ficou lindo!", "Sua criação está pronta!")
	var stage := Rect2(45, 152, bounds.x - 90, bounds.y - 430)
	_draw_portrait_fitted(stage)
	if not exported_path.is_empty():
		_label("✓ Salva na galeria" if not gallery_uri.is_empty() else "✓ Guardada no jogo",
			Vector2(bounds.x * 0.5, bounds.y - 260), 17, Color("356849"))
	_action(Rect2(40, bounds.y - 235, bounds.x - 80, 56), "SALVAR", true)
	_action(Rect2(40, bounds.y - 168, bounds.x - 80, 53), "COMPARTILHAR", false)
	_action(Rect2(40, bounds.y - 105, bounds.x - 80, 53), "CRIAR OUTRO LOOK", false)


func _draw_pro(bounds: Vector2) -> void:
	_draw_page_title(bounds, "Coleção PRO ✦", "Uma compra dentro do mesmo aplicativo")
	_label("Mais cores, roupas, acessórios", Vector2(bounds.x * 0.5, 250), 26, Color("6f4367"))
	_label("e cenários especiais!", Vector2(bounds.x * 0.5, 291), 26, Color("6f4367"))
	for i in range(4):
		var x := bounds.x * 0.5 - 143 + i * 95
		Sprites.draw_item_thumbnail(self, Catalog.filtered("dress")[8 + i], Vector2(x, 410), Vector2(82, 98))
	_label("Grátis: salvar imagens e usar 4 modelos", Vector2(bounds.x * 0.5, 535), 18, Color("795777"))
	_label("PRO: compras suspensas até termos artes exclusivas" if not PRO_SALES_ENABLED else "PRO: peças exclusivas e sem anúncios", Vector2(bounds.x * 0.5, 572), 18, Color("795777"))
	_label("Compras restauráveis na Play Store", Vector2(bounds.x * 0.5, 608), 16, Color("98768b"))
	if state.owned_pro:
		_label("✓ PRO ATIVO", Vector2(bounds.x * 0.5, bounds.y - 245), 27, Color("46886c"))
	else:
		_action(Rect2(32, bounds.y - 249, bounds.x - 64, 62),
			"COMPRAS TEMPORARIAMENTE INDISPONÍVEIS" if not PRO_SALES_ENABLED else ("COMPRAR PRO " + billing_price if not billing_price.is_empty() else "COMPRAR PRO"), PRO_SALES_ENABLED)
		_action(Rect2(32, bounds.y - 173, bounds.x - 64, 56), "RESTAURAR COMPRA", false)


func _draw_games(bounds: Vector2) -> void:
	_draw_page_title(bounds, "Mais jogos", "Outras criações do mesmo estúdio")
	for i in range(3):
		var titles := ["Pong Mobile", "2048 Mobile", "Novos jogos em breve"]
		var hints := ["Desafie o computador", "Combine números até 2048", "Estamos preparando novidades"]
		var rect := Rect2(30, 180 + i * 165, bounds.x - 60, 136)
		_draw_pill(rect, Color("eeeeee") if i == 2 else Color("ffe8f1"))
		_label(titles[i], Vector2(bounds.x * 0.5, rect.position.y + 57), 26, Color("999999") if i == 2 else Color("68445f"))
		_label(hints[i], Vector2(bounds.x * 0.5, rect.position.y + 93), 17, Color("999999") if i == 2 else Color("916c85"))


func _draw_page_title(bounds: Vector2, title: String, subtitle: String) -> void:
	_draw_pill(Rect2(0, 0, bounds.x, 134), Color("fffafc"))
	_button(Rect2(12, 28, 98, 49), "‹ VOLTAR")
	_label(title, Vector2(bounds.x * 0.5, 101), 29, Color("644360"))
	_label(subtitle, Vector2(bounds.x * 0.5, 135), 16, Color("9a6e85"))


func _button(rect: Rect2, name: String) -> void:
	_draw_pill(rect, Color("f2d5e1"))
	_label(name, rect.get_center() + Vector2(0, 6), 14, Color("49243c"), rect.size.x - 12)


func _action(rect: Rect2, name: String, primary: bool) -> void:
	_draw_pill(rect, Color("aa3268") if primary else Color("f2d5e1"))
	_label(name, rect.get_center() + Vector2(0, 8), 20, Color.WHITE if primary else Color("49243c"), rect.size.x - 14)


func _portrait_fit_rect(container: Rect2) -> Rect2:
	var aspect := 540.0 / 640.0
	var width := minf(container.size.x, container.size.y * aspect)
	var height := width / aspect
	return Rect2(container.position + (container.size - Vector2(width, height)) * 0.5, Vector2(width, height))


func _draw_portrait_fitted(container: Rect2) -> void:
	draw_texture_rect(_portrait_view.get_texture(), _portrait_fit_rect(container), false)


func _draw_pill(rect: Rect2, color: Color) -> void:
	var radius := minf(16.0, rect.size.y * 0.35)
	draw_rect(Rect2(rect.position.x + radius, rect.position.y, maxf(0, rect.size.x - 2 * radius), rect.size.y), color)
	draw_rect(Rect2(rect.position.x, rect.position.y + radius, rect.size.x, maxf(0, rect.size.y - 2 * radius)), color)
	for pos in [rect.position + Vector2(radius, radius), rect.position + Vector2(rect.size.x - radius, radius),
			rect.position + Vector2(radius, rect.size.y - radius), rect.end - Vector2(radius, radius)]:
		draw_circle(pos, radius, color)


func _label(content: String, pos: Vector2, font_size: int, color: Color, max_width: float = 0.0) -> void:
	var font: Font = ThemeDB.fallback_font
	var layout := _label_layout(content, pos, font_size, max_width)
	draw_string(font, Vector2(layout["origin_x"], pos.y), content,
		HORIZONTAL_ALIGNMENT_LEFT, -1, layout["font_size"], color)


func _label_layout(content: String, pos: Vector2, font_size: int, max_width: float = 0.0) -> Dictionary:
	var font: Font = ThemeDB.fallback_font
	# draw_string interpreta pos.x como a BORDA ESQUERDA do texto. A implementação
	# anterior passava o centro e adicionava mais 260 px; no Android cortava tudo.
	var available := max_width if max_width > 0.0 else maxf(25.0, 2.0 * minf(pos.x, size.x - pos.x) - 20.0)
	var fitted_size := font_size
	while fitted_size > 10 and font.get_string_size(content, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted_size).x > available:
		fitted_size -= 1
	var text_width := font.get_string_size(content, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted_size).x
	return {"origin_x": pos.x - text_width * 0.5, "text_width": text_width,
		"font_size": fitted_size, "available": available}


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_pointer_down(event.index, event.position)
		else:
			_pointer_up(event.index, event.position)
		accept_event()
	elif event is InputEventScreenDrag:
		_pointer_move(event.index, event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pointer_down(-1, event.position)
		else:
			_pointer_up(-1, event.position)
		accept_event()
	elif event is InputEventMouseMotion and active_finger == -1:
		_pointer_move(-1, event.position)
		accept_event()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_BACK, KEY_ESCAPE]:
		_go_back()
		get_viewport().set_input_as_handled()


func _go_back() -> void:
	match screen:
		"studio": screen = "home"
		"finish", "background": screen = "studio"
		_: screen = "home"
	_clear_armed = false
	queue_redraw()


func _pointer_down(finger: int, point: Vector2) -> void:
	if active_finger != -99:
		return
	active_finger = finger
	drag_origin = point
	drag_pos = point
	dragging_id = _card_at(point) if screen == "studio" else ""
	queue_redraw()


func _pointer_move(finger: int, point: Vector2) -> void:
	if active_finger != finger:
		return
	drag_pos = point
	if not dragging_id.is_empty():
		queue_redraw()


func _pointer_up(finger: int, point: Vector2) -> void:
	if active_finger != finger:
		return
	active_finger = -99
	if not dragging_id.is_empty():
		var dragged := dragging_id
		dragging_id = ""
		if point.y < size.y - WARDROBE_HEIGHT or point.distance_to(drag_origin) < 22:
			_wear(dragged)
	else:
		_handle_tap(point)
	queue_redraw()


func _card_at(point: Vector2) -> String:
	var top := size.y - WARDROBE_HEIGHT
	if point.y < top + 62 or point.y > top + 189:
		return ""
	var index := floori((point.x - 12) / ((size.x - 24) / 4.0))
	if index < 0 or index >= 4:
		return ""
	var items: Array[Dictionary] = Catalog.filtered(category)
	var item_index := page * 4 + index
	return str(items[item_index]["id"]) if item_index < items.size() else ""


func _wear(id: String) -> void:
	var item: Dictionary = Catalog.by_id(id)
	if bool(item.get("pro", false)) and not state.owned_pro:
		screen = "pro"
		return
	if state.wear(id):
		var just_completed: bool = state.complete_challenge_if_ready()
		state.save()
		if just_completed:
			_show_message("Desafio concluído! ✦")


func _handle_tap(point: Vector2) -> void:
	var y := point.y
	var w := size.x
	match screen:
		"home":
			if y >= size.y - 325 and y < size.y - 263:
				screen = "studio"
			elif y >= size.y - 250 and y < size.y - 197:
				screen = "models"
			elif y >= size.y - 185 and y < size.y - 132:
				screen = "challenges"
			elif y >= size.y - 120 and y < size.y - 71:
				screen = "pro" if point.x < w * 0.5 else "games"
		"studio": _studio_tap(point)
		"models":
			if y < 85:
				screen = "home"
			elif y >= 165:
				var col := 0 if point.x < w * 0.5 else 1
				var row := floori((y - 165) / 270)
				var index := row * 2 + col
				if state.select_model(index):
					state.save()
					screen = "studio"
		"background":
			if y < 85:
				screen = "studio"
			elif y >= 158:
				var col := 0 if point.x < w * 0.5 else 1
				var row := floori((y - 158) / 181)
				var index := row * 2 + col
				if index < Catalog.BACKGROUNDS.size():
					if state.select_background(index):
						state.save()
						screen = "studio"
					elif bool(Catalog.BACKGROUNDS[index]["pro"]) and not state.owned_pro:
						screen = "pro"
		"challenges":
			if y < 85:
				screen = "home"
			elif y >= size.y - 96:
				state.select_challenge(-1)
				state.save()
				screen = "studio"
			elif y >= 165:
				var index := floori((y - 165) / 113)
				if state.select_challenge(index):
					state.save()
					screen = "studio"
		"finish":
			if y < 85:
				screen = "studio"
			elif y >= size.y - 168 and y < size.y - 115:
				share_creation()
			elif y >= size.y - 235 and y < size.y - 179:
				export_png()
			elif y >= size.y - 105:
				state.reset_outfit()
				state.save()
				exported_path = ""
				gallery_uri = ""
				screen = "studio"
		"pro":
			if y < 85:
				screen = "home"
			elif y >= size.y - 249 and y < size.y - 187 and not state.owned_pro and not billing_busy:
				if PRO_SALES_ENABLED:
					billing.purchase()
				else:
					_show_message("Compras suspensas até termos artes PRO exclusivas.")
			elif y >= size.y - 173 and y < size.y - 117 and not state.owned_pro and not billing_busy:
				billing.restore()
		"games":
			if y < 85:
				screen = "home"


func _studio_tap(point: Vector2) -> void:
	var y := point.y
	if y >= 32 and y <= 80:
		var header_buttons := _studio_header_rects(size.x)
		if header_buttons[0].has_point(point):
			screen = "home"
		elif header_buttons[1].has_point(point):
			screen = "challenges"
		elif header_buttons[2].has_point(point):
			screen = "pro"
		elif header_buttons[3].has_point(point):
			exported_path = ""
			gallery_uri = ""
			screen = "finish"
		return
	var top := size.y - WARDROBE_HEIGHT
	if y < top:
		# Tap a currently worn layer to take it off without opening another panel.
		return
	# Prioridade ao rodapé; a faixa de cor NÃO invade a área dos botões.
	if y >= size.y - 56:
		var button_index := floori((point.x - 6) / ((size.x - 20) / 4.0))
		match button_index:
			0:
				if state.undo():
					state.save()
			1:
				if state.remove(category):
					state.save()
			2: screen = "background"
			3:
				if _clear_armed:
					state.reset_outfit()
					state.save()
					_clear_armed = false
					_clear_timeout = 0.0
					_show_message("Look limpo! Toque Desfazer para voltar.")
				else:
					_clear_armed = true
					_clear_timeout = 4.0
					_show_message("Limpar tudo? Toque CONFIRMAR novamente.")
	elif y >= top + 250 and y < top + 305:
		for index in range(5):
			var swatch_pos := Vector2(size.x * 0.5 - 96 + index * 48, top + 276)
			if point.distance_to(swatch_pos) < 24:
				if state.select_color(index):
					state.save()
				break
	elif y < top + 62:
		_clear_armed = false
		var index := floori(point.x / (size.x / 6.0))
		if index >= 0 and index < Catalog.CATEGORIES.size():
			category = Catalog.CATEGORIES[index]
			page = 0
	elif y >= top + 198 and y < top + 245:
		var count := Catalog.filtered(category).size()
		var total := maxi(1, ceili(float(count) / 4.0))
		if point.x < 95:
			page = posmod(page - 1, total)
		elif point.x > size.x - 95:
			page = posmod(page + 1, total)


func _show_message(message: String) -> void:
	toast = message
	toast_elapsed = 4.0
	queue_redraw()


func _load_positive_entitlement() -> bool:
	var config := ConfigFile.new()
	return config.load(entitlement_file) == OK and bool(config.get_value("pro", "owned", false))


func _on_entitlement_checked(owned: bool) -> void:
	# Nunca retirar uma compra positiva em caso de consulta vazia/desatualizada.
	# Isso privilegia quem pagou quando a Play Store não consegue verificar.
	if owned:
		state.owned_pro = true
		var config := ConfigFile.new()
		config.set_value("pro", "owned", true)
		var err := config.save(entitlement_file)
		if err != OK:
			push_warning("Não foi possível guardar a compra Pro: " + str(err))
		_show_message("PRO liberado! A sua compra fica guardada.")
	queue_redraw()


func share_creation() -> void:
	if exported_path.is_empty() or not FileAccess.file_exists(exported_path):
		export_png(true)
	elif not AndroidGallery.share_image(exported_path, gallery_uri):
		_show_message("Não foi possível abrir o compartilhamento.")


func export_png(share_after: bool = false) -> void:
	if _saving:
		return
	_saving = true
	_portrait.queue_redraw()
	# O renderer dummy usado no CI não gera texturas de SubViewport.
	if DisplayServer.get_name() == "headless":
		_show_message("A imagem não está disponível neste dispositivo.")
		_saving = false
		return
	# Um atraso curto limita o tempo de espera também no modo headless, onde
	# frame_post_draw não é necessariamente emitido.
	await get_tree().process_frame
	await get_tree().process_frame
	var picture: Image = _portrait_view.get_texture().get_image()
	if picture == null or picture.is_empty():
		_show_message("A imagem não está disponível neste dispositivo.")
		_saving = false
		return
	var dir_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(export_folder))
	if dir_error != OK:
		_show_message("Não foi possível criar a pasta de imagens.")
	else:
		_export_serial += 1
		var name := "look_%d_%03d.png" % [int(Time.get_unix_time_from_system()), _export_serial]
		var path := export_folder + "/" + name
		var error := picture.save_png(path)
		if error == OK:
			exported_path = path
			gallery_uri = AndroidGallery.save_png(path)
			if share_after:
				if not AndroidGallery.share_image(exported_path, gallery_uri):
					_show_message("Não foi possível abrir o compartilhamento.")
			else:
				_show_message("Imagem na galeria! ✦" if not gallery_uri.is_empty()
					else "Guardada no jogo. Toque Compartilhar para enviar.")
		else:
			_show_message("Não foi possível salvar a imagem.")
	_saving = false
	queue_redraw()
