extends SceneTree
## Garante navegação por páginas, bloqueio Pro e uso real do último acessório.

const Catalog = preload("res://scripts/catalog.gd")
const State = preload("res://scripts/studio_state.gd")

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		push_error("FALHOU: " + label)


func _run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var game: Control = scene.instantiate()
	game.studio_storage_path = "user://kawaii_navigation_%d.cfg" % Time.get_ticks_usec()
	game.entitlement_file = "user://kawaii_navigation_entitlement_%d.cfg" % Time.get_ticks_usec()
	root.add_child(game)
	await process_frame
	game.screen = "models"
	game.size = Vector2(360, 800)
	_check(game._model_total_pages() == 4, "14 bonecas cabem em quatro páginas")
	for pg in range(4):
		_check(game.models_page == pg, "página atual consistente")
		for slot in range(4):
			var expected := pg * 4 + slot
			if expected >= Catalog.MODEL_NAMES.size():
				break
			var card: Rect2 = game._model_card_rect(slot, game.size)
			_check(card.position.y >= 150 and card.end.y < game.size.y - 103,
				"cartão não colide com navegação")
			_check(game._model_index_at(card.get_center()) == expected,
				"hit test correto do modelo %d" % expected)
		if pg < 3:
			game._handle_tap(Vector2(game.size.x - 60, game.size.y - 76))
	_check(game._model_index_at(game._model_card_rect(2, game.size).get_center()) == -1,
		"última página não possui terceira boneca fantasma")
	game._handle_tap(Vector2(60, game.size.y - 76))
	_check(game.models_page == 2, "página anterior")
	game.models_page = 3
	game._handle_tap(game._model_card_rect(1, game.size).get_center())
	_check(game.screen == "pro", "modelo Tainá bloqueado sem compra")
	_check(game.state.model_index == 0, "nenhum modelo premium liberado sem compra")
	game.state.owned_pro = true
	game.screen = "models"
	game.models_page = 3
	game._handle_tap(game._model_card_rect(1, game.size).get_center())
	_check(game.screen == "studio" and game.state.model_index == 13,
		"última boneca selecionável com direito PRO")
	_check(game._available_items("top").size() == 25, "25 blusas na vitrine")
	_check(game._available_items("accessory").size() == 50, "50 acessórios na vitrine")
	game.category = "accessory"
	game.page = 12
	_check(game._card_at(Vector2(45, game.size.y - 200)) == "pro_kawaii_accessory_48",
		"página final de acessórios alcançável")
	_check(game.state.wear("pro_kawaii_accessory_49"), "último acessório veste Tainá")
	_check(game.state.select_model(4), "trocar para Luna mantém coleção")
	_check(game.state.outfit["accessory"] == "pro_kawaii_accessory_49",
		"trocar entre bonecas kawaii preserva acessório")
	_check(game.state.select_model(0), "trocar para boneca livre")
	_check(game.state.outfit["accessory"] == "", "trocar tipo de boneca remove recorte incompatível")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.studio_storage_path))
	game.queue_free()
	await process_frame
	print("Navegação Kawaii: %d falhas" % failures)
	quit(1 if failures else 0)
