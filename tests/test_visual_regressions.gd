extends SceneTree

const StudioState = preload("res://scripts/studio_state.gd")
const PortraitCanvas = preload("res://scripts/portrait_canvas.gd")
const Sprites = preload("res://scripts/paper_sprites.gd")

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(value: bool, description: String) -> void:
	if not value:
		failures += 1
		push_error("FALHOU: " + description)


func _run() -> void:
	# Cobertura de TODOS os 41 PNGs privados (no CI, fixtures sintéticas).
	# É deliberadamente um teste de alfa, NÃO uma certificação de acabamento.
	var sprite_names: Array[String] = []
	for index in range(4):
		sprite_names.append("model_%d" % index)
		sprite_names.append("model_%d_bare" % index)
	for slot in ["top", "bottom", "dress"]:
		for index in range(8):
			sprite_names.append("%s_%02d" % [slot, index])
	for index in range(6):
		sprite_names.append("shoes_%02d" % index)
	for index in range(3):
		sprite_names.append("accessory_%02d" % index)
	_check(sprite_names.size() == 41, "inventário de 41 imagens coberto")
	for sprite_name in sprite_names:
		var texture: Texture2D = load("res://assets/paper/" + sprite_name + ".png")
		_check(texture != null, "sprite presente: " + sprite_name)
		if texture == null:
			continue
		var pixels: Image = texture.get_image()
		_check(pixels.get_width() >= 20 and pixels.get_height() >= 20,
			"sprite com dimensões úteis: " + sprite_name)
		var corners := [Vector2i(0, 0), Vector2i(pixels.get_width() - 1, 0),
			Vector2i(0, pixels.get_height() - 1),
			Vector2i(pixels.get_width() - 1, pixels.get_height() - 1)]
		var transparent_corners := 0
		for corner in corners:
			if pixels.get_pixelv(corner).a < 0.1:
				transparent_corners += 1
		# Botas altas podem tocar os DOIS cantos superiores do recorte.
		_check(transparent_corners >= 2, "sem fundo retangular nos cantos: " + sprite_name)
		var opaque_samples := 0
		for y in range(0, pixels.get_height(), maxi(1, int(pixels.get_height() / 12))):
			for x in range(0, pixels.get_width(), maxi(1, int(pixels.get_width() / 12))):
				if pixels.get_pixel(x, y).a > 0.8:
					opaque_samples += 1
		_check(opaque_samples > 4, "silhueta não desapareceu: " + sprite_name)
	# O oráculo verifica pixels de todas as três variantes listradas.
	# As faixas claras são TECIDO OPACO, não recortes de pele.
	for index in range(3, 6):
		var image := (load("res://assets/paper/dress_%02d.png" % index) as Texture2D).get_image()
		var opaque := 0
		var sampled := 0
		for y in range(65, 140, 3):
			for x in range(65, 140, 3):
				sampled += 1
				if image.get_pixel(x, y).a >= 0.95:
					opaque += 1
		_check(float(opaque) / sampled > 0.96,
			"listras internas opacas no macacão %d (%d/%d)" % [index, opaque, sampled])
		_check(image.get_pixel(0, 0).a < 0.05,
			"borda externa transparente no macacão %d" % index)
	for style in ["bota", "tenis", "sandalia", "sapato"]:
		var rect: Rect2 = Sprites._shoe_rect_for_style(style)
		_check(absf(rect.end.y - Sprites.DOLL_RECT.end.y) < 0.01,
			"calçado %s termina junto aos pés" % style)
		_check(rect.position.y >= Sprites.DOLL_RECT.position.y,
			"calçado %s não sai do modelo" % style)
	for index in [1, 4, 5]:
		var shoe := (load("res://assets/paper/shoes_%02d.png" % index) as Texture2D).get_image()
		var empty_row := false
		var seen_opaque := false
		var detached := false
		for y in range(shoe.get_height()):
			var any_opaque := false
			for x in range(shoe.get_width()):
				if shoe.get_pixel(x, y).a > 0.5:
					any_opaque = true
					break
			if empty_row and any_opaque:
				detached = true
			if any_opaque:
				seen_opaque = true
			elif seen_opaque:
				# Margem transparente ANTES da peça é perfeitamente normal.
				# Só sinalizar lacunas depois que a silhueta começou.
				empty_row = true
		_check(not detached, "sapato %d não inclui fragmento de outra fileira" % index)

	# Capturas sem UI para comparar visualmente modelo, roupa e sapatos no
	# mesmo sistema de coordenadas utilizado pelo compartilhamento.
	if DisplayServer.get_name() == "headless":
		print("Renderização por pixels indisponível no renderer dummy; testar em Android.")
		print("Regressões visuais (alpha e geometria): %d falhas" % failures)
		quit(1 if failures else 0)
		return
	var state := StudioState.new()
	state.owned_pro = true
	var viewport := SubViewport.new()
	viewport.size = Vector2i(540, 640)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var portrait := PortraitCanvas.new()
	portrait.studio_state = state
	viewport.add_child(portrait)
	for model_index in range(4):
		state.model_index = model_index
		state.outfit["dress"] = "dress_03"
		state.outfit["shoes"] = "shoes_01"
		portrait.queue_redraw()
		await process_frame
		await process_frame
		var rendered: Image = viewport.get_texture().get_image()
		_check(rendered != null and rendered.get_width() == 540,
			"retrato com dimensões corretas para modelo %d" % model_index)
		if rendered != null:
			rendered.save_png("user://visual_model_%d.png" % model_index)
	viewport.queue_free()
	await process_frame
	print("Regressões visuais: %d falhas" % failures)
	quit(1 if failures else 0)
