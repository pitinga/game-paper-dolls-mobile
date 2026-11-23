extends SceneTree
## Verifica o novo pack autoral no Git, inclusive no CI sem assets/paper/.

const Catalog = preload("res://scripts/catalog.gd")
const Sprites = preload("res://scripts/paper_sprites.gd")

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error("FALHOU: " + label)


func _run() -> void:
	var ids := ["model_4", "pro_kawaii_top_00", "pro_kawaii_bottom_00",
		"pro_kawaii_dress_00", "pro_kawaii_shoes_00"]
	for id in ids:
		var path: String = "res://assets/kawaii/" + str(id) + ".png"
		var texture: Texture2D = load(path)
		_check(texture != null, "PNG kawaii presente: " + id)
		if texture == null:
			continue
		var img := texture.get_image()
		_check(img.get_size() == Vector2i(1024, 1536), "canvas único: " + id)
		_check(img.get_pixel(0, 0).a < 0.05 and img.get_pixel(1023, 1535).a < 0.05,
			"cantos transparentes: " + id)
		_check(img.get_used_rect().size.x > 40 and img.get_used_rect().size.y > 40,
			"imagem não vazia: " + id)
	for id in ids.slice(1):
		var item := Catalog.by_id(id)
		_check(not item.is_empty() and bool(item.get("pro", false)), "item premium: " + id)
		_check(Sprites._sprite_name(item) == "kawaii/" + id, "sprite exclusivo: " + id)
		_check(Catalog.item_matches_model(item, Catalog.KAWAII_MODEL_INDEX), "compatível com Luna: " + id)
		_check(not Catalog.item_matches_model(item, 0), "incompatível com modelos antigos: " + id)
	print("Coleção kawaii: %d falhas" % failures)
	quit(1 if failures else 0)
