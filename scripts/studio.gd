extends Control

const Catalog = preload("res://scripts/catalog.gd")
const Art = preload("res://scripts/doll_art.gd")
const StudioState = preload("res://scripts/studio_state.gd")
const PortraitCanvas = preload("res://scripts/portrait_canvas.gd")
const BillingBridge = preload("res://scripts/play_billing_bridge.gd")
const AndroidGallery = preload("res://scripts/android_gallery.gd")
const EXPORT_FOLDER := "user://criacoes"
const ENTITLEMENT_FILE := "user://paper_dolls_pro.cfg"

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
var _portrait_view: SubViewport
var _portrait: Node2D
var studio_storage_path := StudioState.STORAGE_PATH
var entitlement_file := ENTITLEMENT_FILE
var export_folder := EXPORT_FOLDER


func _ready() -> void:
	state = StudioState.new()
	state.storage_path = studio_storage_path
	state.owned_pro = _load_positive_entitlement()
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
	billing.start()
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if state != null:
			state.save()
	if what == NOTIFICATION_APPLICATION_RESUMED and billing != null:
		billing.refresh()


func _process(delta: float) -> void:
	if toast_elapsed > 0.0:
		toast_elapsed -= delta
		if toast_elapsed <= 0.0:
			toast = ""
		queue_redraw()


func _draw() -> void:
	var bounds := get_rect().size
	if _portrait != null:
		_portrait.queue_redraw()
	draw_rect(Rect2(Vector2.ZERO, bounds), Color("fff6f9"))
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
			Art.draw_item(self, item, drag_pos + Vector2(0, -34), 0.75, state.color_variant)
	if not toast.is_empty():
		_draw_pill(Rect2(18, bounds.y - 356, bounds.x - 36, 42), Color("4b3a58"))
		_label(toast, Vector2(bounds.x * 0.5, bounds.y - 328), 17, Color.WHITE)


func _draw_home(bounds: Vector2) -> void:
	var cx := bounds.x * 0.5
	draw_circle(Vector2(cx, 198), 135, Color("ffe0eb"))
	_label("VESTE & CRIA", Vector2(cx, 85), 39, Color("533958"))
	_label("Bonecas de Papel", Vector2(cx, 116), 20, Color("9a657f"))
	# A mesma composição vetorial do estúdio aparece na capa.
	draw_texture_rect(_portrait_view.get_texture(), Rect2(cx - 155, 130, 310, 390), false)
	_label("Crie looks, combine e salve!", Vector2(cx, bounds.y * 0.61), 23, Color("634964"))
	_action(Rect2(42, bounds.y - 325, bounds.x - 84, 62), "COMEÇAR A VESTIR", true)
	_action(Rect2(42, bounds.y - 250, bounds.x - 84, 53), "ESCOLHER MODELO", false)
	_action(Rect2(42, bounds.y - 185, bounds.x - 84, 53), "DESAFIOS DE LOOK", false)
	_action(Rect2(42, bounds.y - 120, (bounds.x - 96) * 0.5, 49), "PRO", false)
	_action(Rect2(bounds.x * 0.5 + 6, bounds.y - 120, (bounds.x - 96) * 0.5, 49), "MAIS JOGOS", false)
	_label("Sem cronômetro • offline • imagem PNG grátis", Vector2(cx, bounds.y - 21), 13, Color("916f82"))


func _draw_studio(bounds: Vector2) -> void:
	var stage_height := bounds.y - 426
	_draw_pill(Rect2(0, 0, bounds.x, 108), Color("fffafc"))
	_button(Rect2(10, 32, 78, 48), "‹ VOLTAR")
	_button(Rect2(97, 32, 110, 48), "DESAFIO")
	_button(Rect2(bounds.x - 198, 32, 83, 48), "PRO" if not state.owned_pro else "★ PRO")
	_button(Rect2(bounds.x - 108, 32, 98, 48), "SALVAR")
	var stage_rect := Rect2(0, 108, bounds.x, stage_height)
	draw_texture_rect(_portrait_view.get_texture(), stage_rect, false)
	if state.challenge_index >= 0:
		var challenge: Dictionary = Catalog.CHALLENGES[state.challenge_index]
		_draw_pill(Rect2(18, 121, bounds.x - 36, 36), Color("ffffff", 0.92))
		_label("%s  •  %d/2" % [challenge["name"], state.challenge_progress()], Vector2(bounds.x * 0.5, 145), 17, Color("68436b"))
		if state.challenge_progress() == 2:
			_label("✓ LOOK CONCLUÍDO!", Vector2(bounds.x * 0.5, 183), 19, Color("438762"))
	_draw_wardrobe(bounds)


func _draw_wardrobe(bounds: Vector2) -> void:
	var top := bounds.y - 318
	_draw_pill(Rect2(0, top, bounds.x, 328), Color("fffafc"))
	for i in range(Catalog.CATEGORIES.size()):
		var slot: String = Catalog.CATEGORIES[i]
		var width := bounds.x / 6.0
		var selected := slot == category
		_draw_pill(Rect2(i * width + 3, top + 11, width - 6, 39), Color("ed91b6") if selected else Color("f5e9ef"))
		_label(["Blusas", "Baixo", "Vestidos", "Pés", "Cabelos", "Extras"][i],
			Vector2((i + 0.5) * width, top + 36), 13, Color.WHITE if selected else Color("654861"))
	var items: Array[Dictionary] = Catalog.filtered(category)
	var start := page * 4
	for i in range(4):
		var x := 12 + i * ((bounds.x - 24) / 4.0)
		var card := Rect2(x + 2, top + 65, (bounds.x - 24) / 4.0 - 6, 125)
		_draw_pill(card, Color("fff1f6"))
		if start + i >= items.size():
			continue
		var item: Dictionary = items[start + i]
		var locked: bool = bool(item["pro"]) and not state.owned_pro
		var scale_factor := 0.66 if category != "accessory" else 0.55
		Art.draw_item(self, item, Vector2(card.get_center().x, card.position.y + 62), scale_factor, state.color_variant)
		if locked:
			_draw_pill(Rect2(card.position.x + 50, card.position.y + 8, card.size.x - 55, 24), Color("76537c"))
			_label("PRO", Vector2(card.end.x - 32, card.position.y + 26), 12, Color.WHITE)
		_label(str(item["name"]), Vector2(card.get_center().x, card.end.y - 8), 12, Color("624b60"))
	var total_pages := maxi(1, ceili(float(items.size()) / 4.0))
	_button(Rect2(12, top + 196, 74, 43), "‹")
	_label("%s  %d/%d" % [Catalog.CATEGORY_NAMES[category], page + 1, total_pages],
		Vector2(bounds.x * 0.5, top + 223), 16, Color("6b506b"))
	_button(Rect2(bounds.x - 86, top + 196, 74, 43), "›")
	for i in range(5):
		var pos := Vector2(bounds.x * 0.5 - 96 + i * 48, top + 258)
		var hue: Color = Color.from_hsv(fposmod(0.92 + float(i) * 0.135, 1.0), 0.55, 0.96)
		draw_circle(pos, 15 if i != state.color_variant else 18, hue)
		if i == state.color_variant:
			draw_arc(pos, 23, 0, TAU, 24, Color("795474"), 3)
	_label("Cor", Vector2(65, top + 265), 15, Color("71546c"))
	var bottom_y := bounds.y - 53
	for i in range(4):
		var labels := ["DESFAZER", "TIRAR", "CENÁRIO", "LIMPAR"]
		var w := (bounds.x - 20) / 4.0
		_button(Rect2(6 + i * w, bottom_y, w - 5, 43), labels[i])


func _draw_models(bounds: Vector2) -> void:
	_draw_page_title(bounds, "Escolha seu modelo", "Os quatro usam as mesmas roupas")
	for index in range(4):
		var col := index % 2
		var row := index / 2
		var width := (bounds.x - 48) * 0.5
		var rect := Rect2(16 + col * (width + 16), 165 + row * 270, width, 253)
		_draw_pill(rect, Color("ffecf4") if index == state.model_index else Color.WHITE)
		draw_set_transform(Vector2(rect.position.x + width * 0.5 - 270 * 0.32, rect.position.y + 5), 0, Vector2.ONE * 0.32)
		Art.draw_doll(self, index, {}, 0)
		draw_set_transform(Vector2.ZERO)
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
		_draw_pill(rect, Color("ffffff"))
		for k in range(6):
			draw_rect(Rect2(rect.position.x + 8, rect.position.y + 8 + k * 20, rect.size.x - 16, 22),
				bg["top"].lerp(bg["bottom"], float(k) / 6.0))
		_label(str(bg["name"]) + (" • PRO" if bg["pro"] else "") + (" ✓" if index == state.background_index else ""),
			Vector2(rect.get_center().x, rect.end.y - 15), 17, Color("62435d"))


func _draw_challenges(bounds: Vector2) -> void:
	_draw_page_title(bounds, "Desafios de looks", "Sem tempo limite: crie no seu ritmo")
	for i in range(Catalog.CHALLENGES.size()):
		var challenge: Dictionary = Catalog.CHALLENGES[i]
		var rect := Rect2(24, 165 + i * 113, bounds.x - 48, 94)
		_draw_pill(rect, Color("ffecf4"))
		_label("✦ " + str(challenge["name"]), Vector2(bounds.x * 0.5, rect.position.y + 37), 22, Color("67435c"))
		_label(str(challenge["hint"]), Vector2(bounds.x * 0.5, rect.position.y + 67), 15, Color("9c6a80"))
	_action(Rect2(36, bounds.y - 96, bounds.x - 72, 54), "JOGAR LIVRE", false)


func _draw_finish(bounds: Vector2) -> void:
	_draw_page_title(bounds, "Seu look ficou lindo!", "Salve a imagem sem menus")
	var stage := Rect2(45, 152, bounds.x - 90, bounds.y - 430)
	draw_texture_rect(_portrait_view.get_texture(), stage, false)
	if not exported_path.is_empty():
		_label("PNG salvo: " + exported_path.get_file(), Vector2(bounds.x * 0.5, bounds.y - 260), 15, Color("56795a"))
	_action(Rect2(40, bounds.y - 235, bounds.x - 80, 56), "SALVAR PNG", true)
	_action(Rect2(40, bounds.y - 168, bounds.x - 80, 53),
		"COMPARTILHAR" if not gallery_uri.is_empty() else "VOLTAR À EDIÇÃO", false)
	_action(Rect2(40, bounds.y - 105, bounds.x - 80, 53), "CRIAR OUTRO LOOK", false)


func _draw_pro(bounds: Vector2) -> void:
	_draw_page_title(bounds, "Coleção PRO ✦", "Uma compra dentro do mesmo aplicativo")
	_label("Mais cores, roupas, acessórios", Vector2(bounds.x * 0.5, 250), 26, Color("6f4367"))
	_label("e cenários especiais!", Vector2(bounds.x * 0.5, 291), 26, Color("6f4367"))
	for i in range(4):
		var x := bounds.x * 0.5 - 143 + i * 95
		Art.draw_item(self, Catalog.filtered("dress")[8 + i], Vector2(x, 410), 0.7)
	_label("Grátis: salvar PNG e usar 4 modelos", Vector2(bounds.x * 0.5, 535), 18, Color("795777"))
	_label("PRO: peças exclusivas e sem anúncios", Vector2(bounds.x * 0.5, 572), 18, Color("795777"))
	_label("Compras restauráveis na Play Store", Vector2(bounds.x * 0.5, 608), 16, Color("98768b"))
	if state.owned_pro:
		_label("✓ PRO ATIVO", Vector2(bounds.x * 0.5, bounds.y - 245), 27, Color("46886c"))
	else:
		_action(Rect2(32, bounds.y - 249, bounds.x - 64, 62),
			"COMPRAR PRO " + billing_price if not billing_price.is_empty() else "COMPRAR PRO", true)
	_action(Rect2(32, bounds.y - 173, bounds.x - 64, 56), "RESTAURAR COMPRA", false)
	_label("Sem IDs de anúncios: publicidade desativada.", Vector2(bounds.x * 0.5, bounds.y - 64), 14, Color("917083"))


func _draw_games(bounds: Vector2) -> void:
	_draw_page_title(bounds, "Mais jogos", "Outras criações do mesmo estúdio")
	for i in range(3):
		var titles := ["Pong Mobile", "2048 Mobile", "Novos jogos em breve"]
		var hints := ["Desafie o computador", "Combine números até 2048", "Estamos preparando novidades"]
		var rect := Rect2(30, 180 + i * 165, bounds.x - 60, 136)
		_draw_pill(rect, Color("ffe8f1"))
		_label(titles[i], Vector2(bounds.x * 0.5, rect.position.y + 57), 26, Color("68445f"))
		_label(hints[i], Vector2(bounds.x * 0.5, rect.position.y + 93), 17, Color("916c85"))
	_label("Links oficiais serão ativados quando cada jogo sair na Play Store.", Vector2(bounds.x * 0.5, bounds.y - 80), 13, Color("96768b"))


func _draw_page_title(bounds: Vector2, title: String, subtitle: String) -> void:
	_draw_pill(Rect2(0, 0, bounds.x, 134), Color("fffafc"))
	_button(Rect2(12, 28, 98, 49), "‹ VOLTAR")
	_label(title, Vector2(bounds.x * 0.5, 101), 29, Color("644360"))
	_label(subtitle, Vector2(bounds.x * 0.5, 135), 16, Color("9a6e85"))


func _button(rect: Rect2, name: String) -> void:
	_draw_pill(rect, Color("f7dce9"))
	_label(name, rect.get_center() + Vector2(0, 6), 14, Color("67455e"))


func _action(rect: Rect2, name: String, primary: bool) -> void:
	_draw_pill(rect, Color("e886b1") if primary else Color("f2d7e5"))
	_label(name, rect.get_center() + Vector2(0, 8), 20, Color.WHITE if primary else Color("6e4963"))


func _draw_pill(rect: Rect2, color: Color) -> void:
	var radius := minf(16.0, rect.size.y * 0.35)
	draw_rect(Rect2(rect.position.x + radius, rect.position.y, maxf(0, rect.size.x - 2 * radius), rect.size.y), color)
	draw_rect(Rect2(rect.position.x, rect.position.y + radius, rect.size.x, maxf(0, rect.size.y - 2 * radius)), color)
	for pos in [rect.position + Vector2(radius, radius), rect.position + Vector2(rect.size.x - radius, radius),
			rect.position + Vector2(radius, rect.size.y - radius), rect.end - Vector2(radius, radius)]:
		draw_circle(pos, radius, color)


func _label(content: String, pos: Vector2, font_size: int, color: Color) -> void:
	var font: Font = ThemeDB.fallback_font
	draw_string(font, pos, content, HORIZONTAL_ALIGNMENT_CENTER, 520, font_size, color)


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
		if point.y < size.y - 318 or point.distance_to(drag_origin) < 22:
			_wear(dragged)
	else:
		_handle_tap(point)
	queue_redraw()


func _card_at(point: Vector2) -> String:
	var top := size.y - 318
	if point.y < top + 65 or point.y > top + 190:
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
		state.save()
		if state.challenge_progress() == 2:
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
				if gallery_uri.is_empty():
					screen = "studio"
				elif not AndroidGallery.share_image(gallery_uri):
					_show_message("Compartilhar indisponível neste aparelho.")
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
				billing.purchase()
			elif y >= size.y - 173 and y < size.y - 117:
				billing.restore()
		"games":
			if y < 85:
				screen = "home"


func _studio_tap(point: Vector2) -> void:
	var y := point.y
	if y >= 32 and y <= 80:
		if point.x < 88:
			screen = "home"
		elif point.x < 208:
			screen = "challenges"
		elif point.x >= size.x - 198 and point.x < size.x - 115:
			screen = "pro"
		elif point.x >= size.x - 108:
			screen = "finish"
		return
	var top := size.y - 318
	if y < top:
		# Tap a currently worn layer to take it off without opening another panel.
		return
	if y < top + 55:
		var index := floori(point.x / (size.x / 6.0))
		if index >= 0 and index < Catalog.CATEGORIES.size():
			category = Catalog.CATEGORIES[index]
			page = 0
	elif y >= top + 196 and y < top + 244:
		var count := Catalog.filtered(category).size()
		var total := maxi(1, ceili(float(count) / 4.0))
		if point.x < 95:
			page = posmod(page - 1, total)
		elif point.x > size.x - 95:
			page = posmod(page + 1, total)
	elif y >= top + 240 and y < top + 278:
		for index in range(5):
			var swatch_pos := Vector2(size.x * 0.5 - 96 + index * 48, top + 258)
			if point.distance_to(swatch_pos) < 22:
				if state.select_color(index):
					state.save()
				break
	elif y >= size.y - 53:
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
				state.reset_outfit()
				state.save()
				_show_message("Look limpo. Desfazer restaura a edição.")


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


func export_png() -> void:
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
			_show_message("Imagem salva na galeria! ✦" if not gallery_uri.is_empty() else "PNG salvo no aplicativo! ✦")
		else:
			_show_message("Erro ao salvar imagem: " + str(error))
	_saving = false
	queue_redraw()
