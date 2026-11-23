extends SceneTree

const Catalog = preload("res://scripts/catalog.gd")
var errors := 0

class PurchaseSpy extends Node:
	var purchase_calls := 0
	func purchase() -> void:
		purchase_calls += 1
	func restore() -> void:
		pass


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, label: String) -> void:
	if not ok:
		push_error("FALHOU: " + label)
		errors += 1


func _run() -> void:
	var nonce := str(Time.get_ticks_usec())
	var base := "user://paper_test_" + nonce
	var scene: PackedScene = load("res://scenes/main.tscn")
	var game: Control = scene.instantiate()
	game.studio_storage_path = base + ".cfg"
	game.entitlement_file = base + "_pro.cfg"
	game.export_folder = base + "_images"
	root.add_child(game)
	await process_frame
	_check(game.screen == "home", "inicia no menu")
	game._pointer_down(0, Vector2(200, 160))
	game._pointer_up(0, Vector2(200, game.size.y - 295))
	_check(game.screen == "home", "arrastar de área vazia para COMEÇAR não navega")
	game._pointer_down(0, Vector2(200, game.size.y - 295))
	game._pointer_up(0, Vector2(200, game.size.y - 295))
	_check(game.screen == "studio", "tap legítimo no mesmo botão abre o estúdio")
	game._pointer_down(0, Vector2(game.size.x * 0.5, 240))
	game._pointer_up(0, Vector2(game.size.x - 25, game.size.y - 30))
	_check(game.screen == "studio" and not game._clear_armed, "arraste vazio para LIMPAR não arma confirmação")
	game.screen = "finish"
	game._pointer_down(0, Vector2(200, 300))
	game._pointer_up(0, Vector2(200, game.size.y - 70))
	_check(game.screen == "finish", "arrastar vazio para CRIAR OUTRO LOOK não apaga nem navega")
	game.screen = "pro"
	game._pointer_down(0, Vector2(200, 300))
	game._pointer_up(0, Vector2(200, game.size.y - 145))
	_check(game.screen == "pro", "arrastar vazio até RESTAURAR não solicita compra")
	game.screen = "home"
	game.toast = ""
	game.billing._on_disconnected()
	_check(game.toast.is_empty(), "billing disconnect does not toast on automatic refresh")
	game.billing._on_product_details({"response_code": 1, "product_details": []})
	_check(game.toast.is_empty(), "missing Play product details do not toast automatically")

	_check(ProjectSettings.get_setting("application/config/quit_on_go_back") == false, "Android back delegated to app")
	game.screen = "studio"
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_check(game.screen == "home", "Android back returns to home")
	game.screen = "studio"
	var canceled_down := InputEventScreenTouch.new()
	canceled_down.index = 7
	canceled_down.pressed = true
	canceled_down.position = Vector2(45, game.size.y - 200)
	game._gui_input(canceled_down)
	var canceled_up := InputEventScreenTouch.new()
	canceled_up.index = 7
	canceled_up.pressed = false
	canceled_up.canceled = true
	canceled_up.position = canceled_down.position
	game._gui_input(canceled_up)
	_check(game.active_finger == -99 and game.state.outfit["top"] == "", "canceled touch does not wear item")
	game._pointer_down(8, canceled_down.position)
	game._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	_check(game.active_finger == -99 and game.dragging_id.is_empty(), "pause clears captured finger")
	game._pointer_down(9, canceled_down.position)
	game._pointer_up(9, canceled_down.position)
	_check(game.state.outfit["top"] == "top_00", "touch recovers after pause")
	game.state.reset_outfit()
	game.state.history.clear()
	game._clear_armed = true
	game._clear_timeout = 4.0
	game._studio_tap(Vector2(35, game.size.y - 30))
	_check(not game._clear_armed, "undo disarms clear confirmation")
	game.screen = "home"
	_check(not game.PRO_SALES_ENABLED, "vendas Pro suspensas enquanto arte paga duplica arte grátis")
	game.screen = "pro"
	game.state.owned_pro = false
	var original_billing: Node = game.billing
	var spy := PurchaseSpy.new()
	game.billing = spy
	game._handle_tap(Vector2(game.size.x * 0.5, game.size.y - 215))
	_check(spy.purchase_calls == 0, "suspensão não chama Billing.purchase()")
	_check(not game.state.owned_pro, "botão Pro não libera conteúdo durante suspensão")
	game.billing = original_billing
	game.state.owned_pro = true
	game.toast = ""
	game._on_entitlement_checked(true)
	_check(game.toast.is_empty(), "consulta automática de Pro já ativo não repete aviso")
	game.state.owned_pro = false
	game.screen = "home"
	var first_short := load("res://assets/paper/bottom_00.png") as Texture2D
	var first_pants := load("res://assets/paper/bottom_01.png") as Texture2D
	_check(first_short != null and first_pants != null, "fixtures das duas alturas disponíveis")
	if first_short != null and first_pants != null:
		_check(first_short.get_size().y < first_short.get_size().x * 0.8, "short sintético mais curto que largo")
		_check(first_pants.get_size().y > first_pants.get_size().x * 0.8, "calça sintética mais alta que short")
	# O Pro Test não inicializa Billing: retomar o Android não deve mostrar
	# "Google Play indisponível" por executar refresh de uma ponte desligada.
	game._pro_test_build = true
	game.toast = ""
	game._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	_check(game.toast.is_empty(), "retomada do Pro Test não gera falso erro de Google Play")
	game._handle_tap(Vector2(200, game.size.y - 295))
	_check(game.screen == "studio", "menu abre estúdio")
	# Emula toque real na vitrine; o usuário pode tocar ou arrastar.
	var down := InputEventScreenTouch.new()
	down.index = 0
	down.pressed = true
	down.position = Vector2(45, game.size.y - 200)
	game._gui_input(down)
	var move := InputEventScreenDrag.new()
	move.index = 0
	move.position = Vector2(255, 350)
	game._gui_input(move)
	var up := InputEventScreenTouch.new()
	up.index = 0
	up.pressed = false
	up.position = Vector2(255, 350)
	game._gui_input(up)
	_check(game.state.outfit["top"] == "top_00", "arrastar roupa por toque encaixa")
	game._handle_tap(Vector2(game.size.x * 0.415, game.size.y - 330))
	_check(game.category == "dress", "selecionar categoria")
	game._pointer_down(1, Vector2(45, game.size.y - 200))
	game._pointer_up(1, Vector2(45, game.size.y - 200))
	_check(game.state.outfit["dress"] == "dress_00", "tocar miniatura veste")
	_check(game.state.outfit["top"] == "", "vestido remove blusa na UI")
	# Segundo dedo não toma posse de um gesto em andamento.
	game._pointer_down(0, Vector2(45, game.size.y - 200))
	game._pointer_down(1, Vector2(165, game.size.y - 200))
	_check(game.active_finger == 0, "segunda captura ignorada")
	var second_cancel := InputEventScreenTouch.new()
	second_cancel.index = 1
	second_cancel.canceled = true
	second_cancel.position = Vector2(165, game.size.y - 200)
	game._gui_input(second_cancel)
	_check(game.active_finger == 0 and not game.dragging_id.is_empty(), "cancelar dedo ignorado não encerra arraste do dedo capturado")
	game._pointer_up(0, Vector2(300, 350))
	_check(game.state.outfit["dress"] == "", "repetir toque na peça selecionada remove roupa")
	game._handle_tap(Vector2(35, game.size.y - 30))
	_check(game.state.outfit["dress"] == "dress_00", "desfazer da remoção restaura vestido")
	game._handle_tap(Vector2(35, game.size.y - 30))
	_check(game.state.outfit["top"] == "top_00", "segundo desfazer restaura blusa")
	var selected: Dictionary = Catalog.by_id("top_00")
	_check(str(selected["name"]).findn("azul") < 0, "nome de peça não depende da cor atual")
	game.state.reset_outfit()
	game.state.select_challenge(1)
	game.state.wear("top_00")
	game.state.wear("bottom_00")
	_check(game.state.challenge_progress() == 2, "progresso de desafio por duas peças")
	_check(game.state.complete_challenge_if_ready(), "conquista de desafio registrada")
	_check(not game.state.complete_challenge_if_ready(), "conquista idempotente")
	_check(game._toast_rect(game.size).position.y > 157.0, "aviso não cobre placa de desafio")
	game.state.save()
	var restored: RefCounted = load("res://scripts/studio_state.gd").new()
	restored.storage_path = game.studio_storage_path
	restored.load_saved()
	_check(restored.completed_challenges.has(1), "conquista preservada em disco")
	game.state.reset_outfit()
	game._studio_tap(Vector2(game.size.x - 25, game.size.y - 30))
	_check(game._clear_armed and game.state.history.size() > 0, "limpar exige confirmação")
	game._studio_tap(Vector2(game.size.x - 25, game.size.y - 30))
	_check(not game._clear_armed, "confirmação consumida")
	# Exportação só da composição, sem botões, em PNG válido 540x640.
	game.screen = "finish"
	game.export_png()
	for frame in range(25):
		if not game._saving:
			break
		await process_frame
	print("Export state: saving=%s path=%s" % [game._saving, game.exported_path])
	_check(not game._saving, "captura não trava no modo headless")
	if not game.exported_path.is_empty():
		var image := Image.new()
		_check(image.load(game.exported_path) == OK, "PNG exportado legível")
		_check(image.get_size() == Vector2i(540, 640), "resolução da composição")
		_check(image.get_pixel(270, 190) != image.get_pixel(15, 15), "boneca visível na imagem")
		DirAccess.remove_absolute(ProjectSettings.globalize_path(game.exported_path))
	else:
		_check(game.toast == "A imagem não está disponível neste dispositivo.", "falha de renderização explicada")
	# Testa escrita/leitura real de PNG sem depender do renderer dummy do CI.
	var image_sample := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	image_sample.fill(Color("e886b1"))
	var png_path := base + "_probe.png"
	_check(image_sample.save_png(png_path) == OK, "codificador PNG")
	var loaded := Image.new()
	_check(loaded.load(png_path) == OK and loaded.get_size() == Vector2i(8, 8), "round-trip PNG")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(png_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.studio_storage_path))
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(base + "_images"))
	print("Integração e PNG: %d falhas" % errors)
	quit(1 if errors > 0 else 0)
