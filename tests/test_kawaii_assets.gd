extends SceneTree
## Confere os 160 PNGs que entram no APK, o catálogo de itens e a seleção.
## Este é um teste estrutural de sprites, não uma aprovação estética manual.

const Catalog = preload("res://scripts/catalog.gd")
const Sprites = preload("res://scripts/paper_sprites.gd")
const Collection = preload("res://scripts/kawaii_collection.gd")

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error("FALHOU: " + label)


func _check_png(id: String) -> void:
	var path := "res://assets/kawaii/" + id + ".png"
	_check(ResourceLoader.exists(path), "sprite incluído no projeto: " + id)
	if not ResourceLoader.exists(path):
		return
	var texture: Texture2D = load(path)
	_check(texture != null, "PNG legível: " + id)
	if texture == null:
		return
	var img: Image = texture.get_image()
	_check(img != null and img.get_size() == Vector2i(1024, 1536), "canvas 1024x1536: " + id)
	if img == null or img.get_size() != Vector2i(1024, 1536):
		return
	_check(img.get_pixel(0, 0).a < 0.05 and img.get_pixel(1023, 1535).a < 0.05,
		"cantos transparentes: " + id)
	var visible := img.get_used_rect()
	_check(visible.size.x >= 20 and visible.size.y >= 20,
		"silhueta visível: " + id)


func _run() -> void:
	_check(Collection.MODEL_NAMES.size() == 10, "dez bonecas premium")
	_check(Collection.MODEL_SPRITES.size() == 10, "dez sprites de bonecas")
	_check(Collection.ITEMS.size() == 150, "150 peças do catálogo Kawaii")
	_check(Catalog.MODEL_NAMES.size() == 14, "quatro modelos livres e dez premium")
	var names := {}
	for i in range(Collection.MODEL_SPRITES.size()):
		var sprite: String = str(Collection.MODEL_SPRITES[i])
		_check_png(sprite)
		_check(Sprites._kawaii_model_sprite(4 + i) == "kawaii/" + sprite,
			"sprite correto para boneca " + str(4 + i))
		_check(Catalog.MODEL_NAMES[4 + i] == Collection.MODEL_NAMES[i],
			"nome de boneca correto: " + str(i))
	var tally := {"top": 0, "bottom": 0, "dress": 0, "shoes": 0, "accessory": 0}
	for spec in Collection.ITEMS:
		var id: String = str(spec["id"])
		var slot: String = str(spec["slot"])
		_check(not names.has(id), "id único " + id)
		names[id] = true
		_check(tally.has(slot), "categoria conhecida " + id)
		if tally.has(slot):
			tally[slot] += 1
		_check_png(id)
		var item: Dictionary = Catalog.by_id(id)
		_check(not item.is_empty() and bool(item.get("pro", false)) and
			bool(item.get("kawaii", false)), "item premium exclusivo " + id)
		_check(Sprites._sprite_name(item) == "kawaii/" + id, "sprite de item " + id)
		_check(Catalog.item_matches_model(item, 4) and Catalog.item_matches_model(item, 13)
			and not Catalog.item_matches_model(item, 0), "compatível só com bonecas premium: " + id)
	for slot in ["top", "bottom", "dress", "shoes"]:
		_check(tally[slot] == 25, "25 sprites categoria " + slot)
	_check(tally["accessory"] == 50, "50 acessórios")
	print("Kawaii PRO: %d sprites, %d falhas" % [Collection.MODEL_SPRITES.size() + Collection.ITEMS.size(), failures])
	quit(1 if failures else 0)
