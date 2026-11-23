extends SceneTree
## 13 selectable dolls: three Free originals and ten Pro originals.
const Catalog = preload("res://scripts/catalog.gd")
const Sprites = preload("res://scripts/paper_sprites.gd")
const Free = preload("res://scripts/free_collection.gd")
const Pro = preload("res://scripts/kawaii_collection.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error("FALHOU: " + label)


func _run() -> void:
	var game: Control = load("res://scenes/main.tscn").instantiate()
	var nonce := str(Time.get_ticks_usec())
	game.studio_storage_path = "user://nav_free_%s.cfg" % nonce
	game.entitlement_file = "user://nav_free_entitlement_%s.cfg" % nonce
	root.add_child(game)
	await process_frame
	game.screen = "models"
	game.size = Vector2(360, 800)
	_check(game._model_total_pages() == 4, "13 bonecas em quatro páginas")
	_check(Catalog.MODEL_SELECTION == [0, 1, 2, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13],
		"modelos legados sem direitos não aparecem")
	for p in range(4):
		_check(game.models_page == p, "página %d" % p)
		for slot in range(4):
			var position := p * 4 + slot
			if position >= Catalog.MODEL_SELECTION.size():
				break
			var rect: Rect2 = game._model_card_rect(slot, game.size)
			_check(rect.position.y >= 150 and rect.end.y < game.size.y - 103,
				"cartão fora do rodapé")
			var index: int = Catalog.MODEL_SELECTION[position]
			_check(game._model_index_at(rect.get_center()) == index,
				"hit test modelo %d" % index)
		if p < 3:
			game._handle_tap(Vector2(360 - 50, 800 - 76))
	_check(game._model_index_at(game._model_card_rect(1, game.size).get_center()) == -1,
		"última página não tem slot fantasma")
	game.models_page = 0
	game._handle_tap(game._model_card_rect(1, game.size).get_center())
	_check(game.screen == "studio" and game.state.model_index == 1,
		"Céu Free selecionável sem compra")
	_check(game._available_items("top").size() == 5 and game._available_items("accessory").size() == 5,
		"somente cinco peças por categoria Free")
	game.screen = "models"
	game._handle_tap(game._model_card_rect(3, game.size).get_center())
	_check(game.screen == "pro" and game.state.model_index == 1,
		"Luna bloqueada sem compra")
	game.state.owned_pro = true
	game.screen = "models"
	game.models_page = 3
	game._handle_tap(game._model_card_rect(0, game.size).get_center())
	_check(game.screen == "studio" and game.state.model_index == 13,
		"Tainá acessível com direito PRO")
	_check(game._available_items("top").size() == 25 and game._available_items("accessory").size() == 50,
		"catálogo PRO intacto")
	game.category = "accessory"
	game.page = 12
	_check(game._card_at(Vector2(45, game.size.y - 200)) == "pro_kawaii_accessory_48",
		"última página de acessórios PRO")
	_check(game.state.wear("pro_kawaii_accessory_49"), "último acessório veste Tainá")
	_check(game.state.select_model(4) and game.state.outfit["accessory"] == "pro_kawaii_accessory_49",
		"PRO preserva roupa entre Tainá e Luna")
	_check(game.state.select_model(0) and game.state.outfit["accessory"] == "",
		"alternar para Free limpa roupa PRO")

	for spec in Free.ITEMS.slice(0, 20):
		_check(Sprites._texture(str(spec["sprite"])) != null, "PNG Free disponível")
	for spec in Pro.ITEMS.slice(0, 20):
		_check(Sprites._texture("kawaii/" + str(spec["id"])) != null, "PNG PRO disponível")
	_check(Sprites._image_lru.size() <= Sprites.TEXTURE_CACHE_LIMIT,
		"cache LRU limita imagens Free e PRO em memória")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.studio_storage_path))
	game.queue_free()
	await process_frame
	print("Navegação Free/PRO: %d falha(s)" % failures)
	quit(1 if failures else 0)
