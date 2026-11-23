extends SceneTree
## REAL PNG exports via XVFB: Free dolls, outfit changes, all-Pro preservation.
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, description: String) -> void:
	if not ok:
		failures += 1
		push_error("FALHOU: " + description)


func _wait_export(game: Control) -> void:
	for frame in range(120):
		if not game._saving:
			return
		await process_frame


func _export(game: Control, label: String) -> Dictionary:
	game._portrait.queue_redraw()
	await process_frame
	await process_frame
	game.export_png()
	await _wait_export(game)
	_check(not game._saving and not game.exported_path.is_empty(), "exportação concluída: " + label)
	var image := Image.new()
	var path: String = game.exported_path
	if not path.is_empty():
		_check(image.load(path) == OK, "PNG legível: " + label)
	_check(image.get_size() == Vector2i(540, 640), "540x640: " + label)
	if not image.is_empty():
		_check(image.get_pixel(270, 190) != image.get_pixel(15, 15),
			"boneca renderizada, não fundo vazio: " + label)
	return {"path": path, "image": image}


func _run() -> void:
	_check(DisplayServer.get_name() != "headless", "renderer gráfico obrigatório")
	if failures:
		quit(1)
		return
	root.size = Vector2i(540, 960)
	var nonce := "%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	var base := "user://free_render_%s" % nonce
	var game: Control = load("res://scenes/main.tscn").instantiate()
	game.studio_storage_path = base + ".cfg"
	game.entitlement_file = base + "_pro.cfg"
	game.export_folder = base + "_images"
	root.add_child(game)
	await process_frame
	_check(game._portrait_view.get_child_count() == 1 and
		game._portrait.get_parent() == game._portrait_view,
		"PNG contém apenas a criação sem botões/UI")
	_check(game.state.wear("free_top_00_00") and game.state.wear("free_bottom_00_00"),
		"Amora usa coleção Free")
	var img_amora: Dictionary = await _export(game, "Amora Free")
	_check(game.state.wear("free_top_00_01") and game.state.select_background(1),
		"troca original de roupa/cenário Free")
	var img_amora2: Dictionary = await _export(game, "Amora outro look")
	if not img_amora["image"].is_empty() and not img_amora2["image"].is_empty():
		_check(img_amora["image"].get_data() != img_amora2["image"].get_data(),
			"alterações Free resultam em PNG diferentes")
	_check(game.state.select_model(1), "Céu grátis")
	_check(game.state.wear("free_dress_01_02") and game.state.wear("free_shoes_01_01"),
		"Céu veste sua coleção exclusiva")
	var img_ceu: Dictionary = await _export(game, "Céu Free")
	if not img_ceu["image"].is_empty() and not img_amora2["image"].is_empty():
		_check(img_ceu["image"].get_data() != img_amora2["image"].get_data(),
			"duas bonecas Free diferentes produzem PNGs diferentes")
	_check(game.state.select_model(2), "Mel grátis")
	_check(game.state.wear("free_dress_02_04") and game.state.wear("free_accessory_02_03"),
		"Mel veste vestido e colar originais")
	var img_mel: Dictionary = await _export(game, "Mel Free")
	if not img_mel["image"].is_empty() and not img_ceu["image"].is_empty():
		_check(img_mel["image"].get_data() != img_ceu["image"].get_data(),
			"as três bonecas Free têm imagens distintas")
	game.state.owned_pro = true
	_check(game.state.select_model(4) and game.state.wear("pro_kawaii_dress_00") and
		game.state.wear("pro_kawaii_shoes_00"), "Luna PRO preservada")
	var img_luna: Dictionary = await _export(game, "Luna PRO")
	_check(game.state.select_model(13) and game.state.wear("pro_kawaii_dress_24") and
		game.state.wear("pro_kawaii_accessory_49"), "Tainá e itens 24/49")
	var img_taina: Dictionary = await _export(game, "Tainá PRO")
	if not img_luna["image"].is_empty() and not img_taina["image"].is_empty():
		_check(img_luna["image"].get_data() != img_taina["image"].get_data(),
			"modelos Pro continuam renderizando imagens distintas")
	game.queue_free()
	await process_frame
	for image in [img_amora, img_amora2, img_ceu, img_mel, img_luna, img_taina]:
		var file: String = str(image["path"])
		if not file.is_empty() and FileAccess.file_exists(file):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	for file in [base + ".cfg", base + "_pro.cfg"]:
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	print("Exportação gráfica Free/PRO: %d falha(s)." % failures)
	quit(1 if failures else 0)
