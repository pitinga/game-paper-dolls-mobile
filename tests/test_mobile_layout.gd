extends SceneTree
## The new original Free and Pro UI must work in narrow Android viewports.
const Catalog = preload("res://scripts/catalog.gd")
const Sprites = preload("res://scripts/paper_sprites.gd")
var errors := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, label: String) -> void:
	if not ok:
		errors += 1
		push_error("FALHOU: " + label)


func _run() -> void:
	var game: Control = load("res://scenes/main.tscn").instantiate()
	var nonce := str(Time.get_ticks_usec())
	game.studio_storage_path = "user://free_mobile_%s.cfg" % nonce
	game.entitlement_file = "user://free_mobile_pro_%s.cfg" % nonce
	root.add_child(game)
	await process_frame
	var wardrobe_height: float = float(game.get_script().get_script_constant_map()["WARDROBE_HEIGHT"])
	for viewport in [Vector2(360, 800), Vector2(540, 960), Vector2(540, 1200), Vector2(720, 1280)]:
		game.size = viewport
		var stage := Rect2(0, 108, viewport.x, viewport.y - 108 - wardrobe_height)
		var fitted: Rect2 = game._portrait_fit_rect(stage)
		_check(fitted.position.x >= -0.01 and fitted.end.x <= viewport.x + 0.01,
			"prancheta dentro da largura %s" % viewport)
		_check(fitted.position.y >= 107.99 and fitted.end.y <= viewport.y - wardrobe_height + 0.01,
			"prancheta não invade rodapé %s" % viewport)
		_check(absf(fitted.size.x / fitted.size.y - 540.0 / 640.0) < 0.0001,
			"prancheta não distorcida %s" % viewport)
		var headers: Array[Rect2] = game._studio_header_rects(viewport.x)
		for h in range(headers.size()):
			_check(headers[h].position.x >= 0 and headers[h].end.x <= viewport.x,
				"header dentro da tela")
			if h > 0:
				_check(headers[h-1].end.x < headers[h].position.x,
					"botões não sobrepostos")
		var tab_width: float = viewport.x / float(Catalog.CATEGORIES.size())
		_check(tab_width >= 72, "cinco abas tocáveis em 360dp")
		var top: float = viewport.y - wardrobe_height
		_check(top + 276 + 23 < viewport.y - 53, "seletor de cor não invade ações")
		game.screen = "models"
		for pg in range(4):
			game.models_page = pg
			for slot in range(4):
				var pos := pg * 4 + slot
				if pos >= Catalog.MODEL_SELECTION.size(): break
				var card: Rect2 = game._model_card_rect(slot, viewport)
				_check(card.position.x >= 0 and card.end.x <= viewport.x,
					"cartão de boneca dentro da largura")
				_check(card.end.y < viewport.y - 103,
					"paginação não cobre bonecas na tela %s" % viewport)
				_check(game._model_index_at(card.get_center()) == int(Catalog.MODEL_SELECTION[pos]),
					"hit test da seleção em %s" % viewport)
		for label in ["ESCOLHER MODELO", "COMEÇAR A VESTIR", "DESFAZER", "CENÁRIO"]:
			var layout: Dictionary = game._label_layout(label, Vector2(viewport.x/2, 70), 14, viewport.x*.65)
			_check(float(layout["text_width"]) <= viewport.x*.65,
				"texto não ultrapassa largura Android")
	game.size = Vector2(360,800)
	_check(not ResourceLoader.exists("res://assets/paper/model_0.png"),
		"nenhum recorte antigo de procedência incerta é incluído")
	for model in range(3):
		var doll := "res://assets/free_kawaii/free_model_%02d.png" % model
		_check(ResourceLoader.exists(doll), "boneca Free original presente: " + doll)
	for slot in Catalog.CATEGORIES:
		var item: Dictionary = Catalog.filtered_for_model(slot, false, 0)[0]
		var sprite: String = "res://assets/" + Sprites._sprite_name(item) + ".png"
		_check(ResourceLoader.exists(sprite), "peça Free original: " + sprite)
	_check(Sprites.DOLL_RECT.size == Vector2(300, 520), "moldura preservada para todas as poses")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.studio_storage_path))
	game.queue_free()
	await process_frame
	print("Layout original Free/PRO: %d falhas" % errors)
	quit(1 if errors else 0)
