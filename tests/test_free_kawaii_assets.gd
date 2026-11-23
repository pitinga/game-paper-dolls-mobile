extends SceneTree
## 3 doll sprites + 3 * 5 slots * 5 items = 78 real RGBA PNGs.
const Free = preload("res://scripts/free_collection.gd")
const Catalog = preload("res://scripts/catalog.gd")
const Sprites = preload("res://scripts/paper_sprites.gd")
var errors := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, what: String) -> void:
	if not ok:
		errors += 1
		push_error("FALHOU: " + what)


func _check_png(path: String) -> void:
	_check(ResourceLoader.exists(path), "PNG importado: " + path)
	if not ResourceLoader.exists(path):
		return
	var texture: Texture2D = load(path)
	_check(texture != null, "textura carregada: " + path)
	if texture == null:
		return
	var image := texture.get_image()
	_check(image.get_size() == Vector2i(1024, 1536), "canvas padronizado: " + path)
	if image.get_size() != Vector2i(1024, 1536):
		return
	_check(image.get_pixel(0, 0).a < 0.05 and image.get_pixel(1023, 1535).a < 0.05,
		"cantos transparentes: " + path)
	var visible := image.get_used_rect()
	_check(visible.size.x >= 80 and visible.size.y >= 30,
		"imagem com área visível: " + path)


func _run() -> void:
	_check(Free.MODEL_SPRITES.size() == 3, "três bonecas originais Free")
	_check(Free.ITEMS.size() == 75, "75 itens originais Free")
	var seen := {}
	for i in range(3):
		var model: String = str(Free.MODEL_SPRITES[i])
		_check_png("res://assets/free_kawaii/" + model + ".png")
		_check(Sprites._model_sprite(i) == "free_kawaii/" + model, "boneca Free correta: " + model)
	for spec in Free.ITEMS:
		var id: String = str(spec["id"])
		var slot: String = str(spec["slot"])
		var model_index: int = int(spec["model"])
		_check(not seen.has(id), "ID único: " + id)
		seen[id] = true
		_check_png("res://assets/free_kawaii/" + id + ".png")
		var item: Dictionary = Catalog.by_id(id)
		_check(not item.is_empty() and not bool(item.get("pro", true)),
			"item Free verdadeiro: " + id)
		_check(Sprites._sprite_name(item) == "free_kawaii/" + id,
			"sprite Free correto: " + id)
		_check(Catalog.item_matches_model(item, model_index), "modelo apropriado: " + id)
		_check(not Catalog.item_matches_model(item, (model_index + 1) % 3),
			"vestuário não mistura poses Free: " + id)
		_check(not Catalog.item_matches_model(item, 4), "sem mistura com PRO: " + id)
	for i in range(3):
		for slot in Catalog.CATEGORIES:
			_check(Catalog.filtered_for_model(slot, false, i).size() == 5,
				"cinco itens %s para boneca Free %d" % [slot, i])
	print("Pack Free: 78 PNGs, %d falha(s)." % errors)
	quit(1 if errors else 0)
