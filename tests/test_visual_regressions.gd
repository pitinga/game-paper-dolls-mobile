extends SceneTree
## Original sprite alpha / scale / coordinate sanity tests (no legacy paper art).
const Free = preload("res://scripts/free_collection.gd")
const Pro = preload("res://scripts/kawaii_collection.gd")
const Sprites = preload("res://scripts/paper_sprites.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error("FALHOU: " + label)


func _image(path: String) -> Image:
	var texture: Texture2D = load(path)
	if texture == null:
		_check(false, "textura importada: " + path)
		return null
	return texture.get_image()


func _run() -> void:
	var free_count := 0
	for model in range(3):
		var base := _image("res://assets/free_kawaii/free_model_%02d.png" % model)
		if base == null: continue
		var doll_bounds: Rect2i = base.get_used_rect()
		_check(doll_bounds.size.x > 450 and doll_bounds.size.y > 1050,
			"boneca Free inteira, não uma miniatura %d" % model)
		_check(doll_bounds.position.x >= 100 and doll_bounds.end.x <= 950,
			"silhueta centralizada %d" % model)
		_check(base.get_pixel(0, 0).a < 0.05,
			"sem fundo opaco %d" % model)
		free_count += 1
		for slot in ["top", "bottom", "dress", "shoes", "accessory"]:
			for index in range(5):
				var path := "res://assets/free_kawaii/free_%s_%02d_%02d.png" % [slot, model, index]
				var img := _image(path)
				if img == null: continue
				_check(img.get_size() == base.get_size(), "mesma moldura %s" % path)
				var rect: Rect2i = img.get_used_rect()
				_check(rect.size.x >= 65 and rect.size.y >= 25,
					"sprite visível: " + path)
				_check(img.get_pixel(0, 0).a < 0.05 and img.get_pixel(1023,1535).a < 0.05,
					"alpha sem retângulo de fundo: " + path)
				if slot == "top":
					_check(rect.position.y >= 550 and rect.end.y <= 960,
						"blusa posicionada sobre o tronco: " + path)
				elif slot == "bottom":
					_check(rect.position.y >= 800 and rect.end.y <= 1300,
						"parte inferior alinhada ao quadril/pernas: " + path)
				elif slot == "dress":
					_check(rect.position.y >= 550 and rect.end.y <= 1300,
						"vestido com altura e proporção aceitáveis: " + path)
				elif slot == "shoes":
					_check(rect.position.y >= 1250 and rect.end.y <= 1536,
						"sapato próximo aos pés: " + path)
				free_count += 1
	_check(free_count == 78, "cobertura de todas as 78 imagens Free")
	_check(Pro.MODEL_SPRITES.size() == 10 and Pro.ITEMS.size() == 150,
		"coleção PRO intacta")
	_check(Sprites.DOLL_RECT.size == Vector2(300, 520),
		"Full-canvas sprites usam mesma área de composição")
	_check(not ResourceLoader.exists("res://assets/paper/model_0.png"),
		"recortes antigos não entram no build Android")
	if DisplayServer.get_name() == "headless":
		print("Aprovação estética exige inspeção em Android; geometria/alpha: %d falhas" % failures)
	print("Regressões visuais Free/Pro: %d falhas" % failures)
	quit(1 if failures else 0)
