extends SceneTree

const Catalog = preload("res://scripts/catalog.gd")
var errors := 0


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
	game._handle_tap(Vector2(game.size.x * 0.415, game.size.y - 280))
	_check(game.category == "dress", "selecionar categoria")
	game._pointer_down(1, Vector2(45, game.size.y - 200))
	game._pointer_up(1, Vector2(45, game.size.y - 200))
	_check(game.state.outfit["dress"] == "dress_00", "tocar miniatura veste")
	_check(game.state.outfit["top"] == "", "vestido remove blusa na UI")
	# Segundo dedo não toma posse de um gesto em andamento.
	game._pointer_down(0, Vector2(45, game.size.y - 200))
	game._pointer_down(1, Vector2(165, game.size.y - 200))
	_check(game.active_finger == 0, "segunda captura ignorada")
	game._pointer_up(0, Vector2(300, 350))
	game._handle_tap(Vector2(35, game.size.y - 30))
	_check(game.state.outfit["top"] == "top_00", "desfazer integrado restaura blusa")
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
