extends SceneTree
## Imagens GEOMÉTRICAS sintéticas, criadas apenas para testar código no CI.
## Não simulam qualidade, acabamento ou licença das ilustrações reais.

const OUTPUT := "res://assets/paper/"


func _initialize() -> void:
	var target := ProjectSettings.globalize_path(OUTPUT)
	if FileAccess.file_exists(OUTPUT + "model_0.png"):
		print("Arte local encontrada; fixtures sintéticas não serão criadas.")
		quit()
		return
	if DirAccess.make_dir_recursive_absolute(target) != OK:
		push_error("Não foi possível criar diretório de fixtures.")
		quit(1)
		return
	for index in range(4):
		_write("model_%d" % index, 501, 875, Rect2i(90, 8, 310, 835), Color("d7a48a"))
		_write("model_%d_bare" % index, 501, 875, Rect2i(90, 8, 310, 780), Color("d7a48a"))
	for slot in ["top", "bottom", "dress", "shoes"]:
		var count := 6 if slot == "shoes" else 8
		for index in range(count):
			var name := "%s_%02d" % [slot, index]
			match slot:
				"top": _write(name, 221, 198, Rect2i(10, 12, 200, 170), Color("78bdd5"))
				"bottom": _write(name, 224, 231, Rect2i(14, 18, 196, 190), Color("80c2a8"))
				"dress": _write(name, 207, 397, Rect2i(15, 14, 177, 370), Color("81a1ca"))
				"shoes": _write(name, 190, 90, Rect2i(5, 12, 180, 70), Color("c28dca"))
	for index in range(3):
		_write("accessory_%02d" % index, 120, 120,
			Rect2i(20, 20, 80, 80), Color("d9a66d"))
	print("Fixtures sintéticas geradas: 41 arquivos, sem arte de terceiros.")
	quit()


func _write(name: String, width: int, height: int, body: Rect2i, color: Color) -> void:
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	image.fill_rect(body, color)
	if name.begins_with("dress_0") and int(name.right(2)) in [3, 4, 5]:
		for row in range(body.position.y + 24, body.end.y - 24, 28):
			image.fill_rect(Rect2i(body.position.x, row, body.size.x, 9), Color.WHITE)
	var err := image.save_png(OUTPUT + name + ".png")
	if err != OK:
		push_error("Falha ao criar fixture " + name)
