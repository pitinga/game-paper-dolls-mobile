extends SceneTree

const Sprites = preload("res://scripts/paper_sprites.gd")
var errors := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	if not condition:
		push_error("FALHOU: " + description)
		errors += 1


func _run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var game: Control = scene.instantiate()
	var token := str(Time.get_ticks_usec())
	game.studio_storage_path = "user://layout_" + token + ".cfg"
	game.entitlement_file = "user://layout_" + token + "_pro.cfg"
	root.add_child(game)
	await process_frame
	var wardrobe_height: float = float(game.get_script().get_script_constant_map()["WARDROBE_HEIGHT"])
	for viewport in [Vector2(360, 800), Vector2(540, 960), Vector2(540, 1200), Vector2(720, 1280)]:
		game.size = viewport
		var fitted: Rect2 = game._portrait_fit_rect(Rect2(0, 108, viewport.x, viewport.y - 108 - wardrobe_height))
		_check(fitted.position.x >= -0.01 and fitted.end.x <= viewport.x + 0.01,
			"prancheta cabe na largura de " + str(viewport))
		_check(fitted.position.y >= 107.99 and fitted.end.y <= viewport.y - wardrobe_height + 0.01,
			"prancheta cabe entre menu e guarda-roupa " + str(viewport))
		_check(absf(fitted.size.x / fitted.size.y - 540.0 / 640.0) < 0.0001,
			"prancheta sem distorção em " + str(viewport))
		var header_buttons: Array[Rect2] = game._studio_header_rects(viewport.x)
		for index in range(header_buttons.size()):
			_check(header_buttons[index].position.x >= 0 and header_buttons[index].end.x <= viewport.x,
				"botão superior dentro da tela em " + str(viewport))
			if index > 0:
				_check(header_buttons[index - 1].end.x < header_buttons[index].position.x,
					"botões superiores não se sobrepõem em " + str(viewport))
		var wardrobe_top: float = viewport.y - wardrobe_height
		_check(wardrobe_top + 276 + 23 < viewport.y - 53,
			"cores não invadem o rodapé em " + str(viewport))
		var first_color_x: float = viewport.x * 0.5 - 96.0
		var color_label_x: float = 35.0 if viewport.x < 430 else 65.0
		_check(color_label_x + 22.0 < first_color_x - 23.0,
			"rótulo cor não cobre a primeira amostra em " + str(viewport))
		for label in ["VESTE & CRIA", "COMEÇAR A VESTIR", "ESCOLHER MODELO", "DESAFIOS DE LOOK"]:
			var layout: Dictionary = game._label_layout(label, Vector2(viewport.x / 2, 100), 20)
			_check(absf(float(layout["origin_x"]) + float(layout["text_width"]) * 0.5 - viewport.x * 0.5) < 0.1,
				"texto centralizado: " + label)
			_check(float(layout["origin_x"]) >= 0 and float(layout["origin_x"]) + float(layout["text_width"]) <= viewport.x,
				"texto não cortado: " + label)
		for caption in ["‹ VOLTAR", "DESAFIO", "★ PRO", "SALVAR", "DESFAZER", "CENÁRIO"]:
			var layout: Dictionary = game._label_layout(caption, Vector2(viewport.x * 0.5, 70), 14, 68)
			_check(float(layout["text_width"]) <= 68.1, "botão estreito mantém texto legível: " + caption)
	var sample: Texture2D = load("res://assets/paper/model_0.png")
	_check(sample != null, "modelo ilustrado disponível")
	if sample != null:
		var portrait := sample.get_image()
		_check(portrait.get_width() > 300 and portrait.get_height() > 600, "personagem em resolução adequada")
		_check(portrait.get_pixel(0, 0).a < 0.1, "fundo do personagem transparente")
	for slot in ["top", "bottom", "dress", "shoes"]:
		var item: Dictionary = load("res://scripts/catalog.gd").filtered(slot)[0]
		var path := "res://assets/paper/" + Sprites._sprite_name(item) + ".png"
		_check(ResourceLoader.exists(path), "roupa real existente para " + slot)
	_check(Sprites.DOLL_RECT.encloses(Sprites.TOP_RECT), "blusa encaixada no corpo da boneca")
	_check(Sprites.DOLL_RECT.encloses(Sprites.DRESS_RECT), "vestido encaixado no corpo da boneca")
	for index in range(3):
		var dress: Texture2D = load("res://assets/paper/dress_%02d.png" % index)
		var image: Image = dress.get_image()
		_check(image.get_pixel(1, 1).a < 0.05 and
			image.get_pixel(image.get_width() - 2, 1).a < 0.05 and
			image.get_pixel(1, image.get_height() - 2).a < 0.05,
			"recorte de vestido sem retângulo opaco: " + str(index))
	for index in range(4):
		var bare: Texture2D = load("res://assets/paper/model_%d_bare.png" % index)
		_check(bare != null, "modelo com sapato alternativo existe: " + str(index))
		if bare != null:
			var foot: Image = bare.get_image()
			_check(foot.get_pixel(foot.get_width() / 2, foot.get_height() - 1).a < 0.05,
				"sandália original não fica abaixo do sapato escolhido: " + str(index))
	game.screen = "studio"
	game.size = Vector2(360, 800)
	game.state.select_color(0)
	game._studio_tap(Vector2(320, 775))
	_check(game.state.color_variant == 0, "rodapé não toca na paleta de cores")
	_check(game.state.outfit["hair"] == "", "começa sem sobreposição de penteados")
	for i in range(4):
		var hair := "hair_%02d" % i
		_check(game.state.wear(hair), "penteado pode ser escolhido: " + hair)
		_check(game.state.outfit["hair"] == hair, "penteado substitui anterior: " + hair)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.studio_storage_path))
	game.queue_free()
	await process_frame
	print("Layout mobile e ilustrações: %d falhas" % errors)
	quit(1 if errors else 0)
