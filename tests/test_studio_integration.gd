extends SceneTree
## Free and Pro game flow, touch gestures, undo, persistence and disabled billing.
const Catalog = preload("res://scripts/catalog.gd")
const State = preload("res://scripts/studio_state.gd")
var errors := 0

class PurchaseSpy extends Node:
	var purchase_calls := 0
	func purchase() -> void:
		purchase_calls += 1
	func restore() -> void:
		pass


func _initialize() -> void:
	call_deferred("_run")


func _check(value: bool, desc: String) -> void:
	if not value:
		errors += 1
		push_error("FALHOU: " + desc)


func _run() -> void:
	var nonce := str(Time.get_ticks_usec())
	var base := "user://free_integration_%s" % nonce
	var game: Control = load("res://scenes/main.tscn").instantiate()
	game.studio_storage_path = base + ".cfg"
	game.entitlement_file = base + "_pro.cfg"
	game.export_folder = base + "_images"
	root.add_child(game)
	await process_frame
	_check(game.screen == "home" and game.state.model_index == 0, "Amora é a boneca Free inicial")
	_check(not game.PRO_SALES_ENABLED, "cobrança PRO continua suspensa")
	_check(ProjectSettings.get_setting("application/config/quit_on_go_back") == false, "Android Back delegado ao jogo")
	var start := Vector2(game.size.x * 0.5, game.size.y - 294)
	game._pointer_down(0, Vector2(100, 180))
	game._pointer_up(0, start)
	_check(game.screen == "home", "arraste de outra área não abre o jogo")
	game._pointer_down(0, start)
	game._pointer_up(0, start)
	_check(game.screen == "studio", "toque no botão inicia o jogo")
	_check(game._available_items("top").size() == 5, "cinco blusas da Amora")
	var top_card := Vector2(45, game.size.y - 200)
	_check(game._card_at(top_card) == "free_top_00_00", "primeiro cartão Free da Amora")
	game._pointer_down(0, top_card)
	game._pointer_up(0, top_card)
	_check(game.state.outfit["top"] == "free_top_00_00", "toque veste blusa Free")
	game._studio_tap(Vector2(game.size.x * 0.3, game.size.y - 330))
	_check(game.category == "bottom", "cinco categorias com tab de partes inferiores")
	_check(game._available_items("bottom").size() == 5, "cinco partes inferiores Free")
	game._pointer_down(0, top_card)
	game._pointer_up(0, top_card)
	_check(game.state.outfit["bottom"] == "free_bottom_00_00", "saia equipada por toque")
	game._studio_tap(Vector2(game.size.x * 0.5, game.size.y - 330))
	_check(game.category == "dress", "vestidos na terceira guia")
	game._pointer_down(0, top_card)
	game._pointer_up(0, top_card)
	_check(game.state.outfit["dress"] == "free_dress_00_00", "vestido Free equipado")
	_check(game.state.outfit["top"] == "" and game.state.outfit["bottom"] == "",
		"vestido retira blusa e saia")
	game._studio_tap(Vector2(35, game.size.y - 30))
	_check(game.state.outfit["dress"] == "" and game.state.outfit["top"] == "free_top_00_00",
		"desfazer restaura look original")
	_check(game.state.save() == OK, "salvar look original")
	var restored := State.new()
	restored.storage_path = game.studio_storage_path
	restored.load_saved()
	_check(restored.outfit["top"] == "free_top_00_00", "look Free persiste")
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_check(game.screen == "home", "botão Android Back retorna ao menu")
	game.screen = "models"
	game._handle_tap(game._model_card_rect(1, game.size).get_center())
	_check(game.state.model_index == 1 and game.screen == "studio", "troca para Céu grátis")
	_check(game.state.outfit["top"] == "", "não reutiliza roupa Free de outra pose")
	_check(game._available_items("dress").size() == 5, "Céu tem cinco vestidos")
	game.screen = "models"
	game._handle_tap(game._model_card_rect(3, game.size).get_center())
	_check(game.screen == "pro" and game.state.model_index == 1,
		"Luna PRO bloqueada sem entitlement")
	var spy := PurchaseSpy.new()
	var orig_billing: Node = game.billing
	game.billing = spy
	game._handle_tap(Vector2(game.size.x * 0.5, game.size.y - 215))
	_check(spy.purchase_calls == 0, "botão PRO desativado não chama compra")
	game.billing = orig_billing
	game.screen = "studio"
	game._pro_test_build = true
	game.toast = ""
	game._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	_check(game.toast.is_empty(), "modo PRO de teste não faz cobrança/refresh automático")
	var touch := InputEventScreenTouch.new()
	touch.index = 2
	touch.position = top_card
	touch.pressed = true
	game._gui_input(touch)
	var canceled := InputEventScreenTouch.new()
	canceled.index = 2
	canceled.position = top_card
	canceled.pressed = false
	canceled.canceled = true
	game._gui_input(canceled)
	_check(game.active_finger == -99 and game.dragging_id.is_empty(),
		"cancelamento de toque não veste peça")
	game.state.owned_pro = true
	game.state.select_model(4)
	_check(game._available_items("top").size() == 25 and game._available_items("accessory").size() == 50,
		"desbloqueio exibe conteúdo PRO integral")
	_check(game.state.wear("pro_kawaii_top_24"), "última blusa PRO permanece disponível")
	game.state.select_model(0)
	_check(game.state.outfit["top"] == "", "troca PRO para Free remove roupa incompatível")
	game.screen = "finish"
	game.export_png()
	for frame in range(25):
		if not game._saving: break
		await process_frame
	_check(not game._saving, "exportação não trava quando o renderer é headless")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.studio_storage_path))
	game.queue_free()
	await process_frame
	print("Integração Free/PRO: %d falha(s)" % errors)
	quit(1 if errors else 0)
