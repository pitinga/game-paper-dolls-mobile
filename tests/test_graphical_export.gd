extends SceneTree
## Teste de exportação REAL: executar com display virtual, nunca --headless.
## LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a godot --path . --script res://tests/test_graphical_export.gd

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, description: String) -> void:
	if not ok:
		failures += 1
		push_error("FALHOU - " + description)


func _wait_export(game: Control) -> void:
	for frame in range(120):
		if not game._saving:
			return
		await process_frame


func _run() -> void:
	_check(DisplayServer.get_name() != "headless", "exportação requer renderer gráfico real")
	if failures:
		quit(1)
		return
	root.size = Vector2i(540, 960)
	var nonce := "%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	var base := "user://paper_export_graphics_%s" % nonce
	var game: Control = load("res://scenes/main.tscn").instantiate()
	game.studio_storage_path = base + ".cfg"
	game.entitlement_file = base + "_pro.cfg"
	game.export_folder = base + "_images"
	root.add_child(game)
	await process_frame
	_check(game._portrait_view.get_child_count() == 1 and game._portrait.get_parent() == game._portrait_view,
		"viewport exporta somente a composição, sem controles da interface")
	game.state.wear("top_00")
	game._portrait.queue_redraw()
	await process_frame
	await process_frame
	game.export_png()
	await _wait_export(game)
	_check(not game._saving and not game.exported_path.is_empty(), "renderer gera PNG obrigatório")
	var first_path: String = game.exported_path
	var first_image := Image.new()
	if not first_path.is_empty():
		_check(first_image.load(first_path) == OK, "primeiro PNG é legível")
	_check(first_image.get_size() == Vector2i(540, 640), "composição tem 540x640")
	if not first_image.is_empty():
		_check(first_image.get_pixel(270, 190) != first_image.get_pixel(15, 15), "boneca não é uma imagem vazia")
	var first_corner := first_image.get_pixel(15, 15) if not first_image.is_empty() else Color.BLACK
	_check(game.state.wear("top_01") and game.state.select_background(1), "troca de roupa e cenário aplicada ao estado")
	game._portrait.queue_redraw()
	await process_frame
	await process_frame
	game.export_png()
	await _wait_export(game)
	_check(not game._saving and not game.exported_path.is_empty(), "troca de look gera novo PNG")
	var second_path: String = game.exported_path
	var second_image := Image.new()
	if not second_path.is_empty():
		_check(second_image.load(second_path) == OK, "segundo PNG é legível")
	_check(second_image.get_size() == Vector2i(540, 640), "segunda exportação mantém 540x640")
	if not second_image.is_empty():
		_check(second_image.get_pixel(15, 15) != first_corner,
			"mudar cenário altera os pixels da composição exportada")
		_check(not first_image.is_empty() and second_image.get_data() != first_image.get_data(),
			"trocar roupa e cenário gera imagem diferente, sem UI")
	game.queue_free()
	await process_frame
	for file in [first_path, second_path, base + ".cfg", base + "_pro.cfg"]:
		if not file.is_empty() and FileAccess.file_exists(file):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	print("Exportação gráfica: %d falha(s)." % failures)
	quit(1 if failures else 0)
