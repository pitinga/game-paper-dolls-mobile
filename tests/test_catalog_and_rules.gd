extends SceneTree
## Catalog, entitlement, model isolation, saved-outfit migration and undo.

const Catalog = preload("res://scripts/catalog.gd")
const FreeCollection = preload("res://scripts/free_collection.gd")
const KawaiiCollection = preload("res://scripts/kawaii_collection.gd")
const StudioState = preload("res://scripts/studio_state.gd")
var errors := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, description: String) -> void:
	if not ok:
		errors += 1
		push_error("FALHOU: " + description)


func _run() -> void:
	_check(Catalog.MODEL_SELECTION.size() == 13, "3 bonecas Free + 10 PRO visíveis")
	_check(Catalog.MODEL_NAMES.size() == 14 and not Catalog.model_is_selectable(3),
		"índice antigo 3 aposentado sem renumerar os 10 modelos PRO")
	_check(Catalog.CATEGORIES.size() == 5 and not Catalog.CATEGORIES.has("hair"),
		"cinco categorias novas sem penteados externos")
	_check(FreeCollection.ITEMS.size() == 75 and FreeCollection.MODEL_SPRITES.size() == 3,
		"75 roupas Free e 3 bonecas originais")
	_check(KawaiiCollection.ITEMS.size() == 150 and KawaiiCollection.MODEL_SPRITES.size() == 10,
		"coleção PRO original permanece com 160 PNGs")
	_check(Catalog.count("", true) == 75, "somente 75 itens gratuitos novos")
	_check(Catalog.count() == 225, "catálogo funcional com 75 Free + 150 PRO")
	var ids := {}
	for item in Catalog.all_items():
		var id: String = str(item["id"])
		_check(not ids.has(id), "ID único: " + id)
		ids[id] = true
		_check(Catalog.SLOTS.has(item["slot"]), "slot válido: " + id)
		_check(not str(item.get("sprite", "")).is_empty(), "sprite explícito: " + id)
		_check(not str(item.get("sprite", "")).begins_with("paper/"),
			"nenhuma dependência das antigas pranchas: " + id)
	for model_index in range(3):
		_check(not Catalog.model_requires_pro(model_index), "modelo Free %d desbloqueado" % model_index)
		for slot in Catalog.CATEGORIES:
			_check(Catalog.filtered_for_model(slot, false, model_index).size() == 5,
				"cinco peças por slot e boneca Free: %s/%d" % [slot, model_index])
	for model_index in range(4, 14):
		_check(Catalog.model_requires_pro(model_index), "PRO bloqueado: %d" % model_index)
		for slot in Catalog.CATEGORIES:
			var expected := 50 if slot == "accessory" else 25
			_check(Catalog.filtered_for_model(slot, true, model_index).size() == expected,
				"catálogo PRO intacto %s/%d" % [slot, model_index])
			_check(Catalog.filtered_for_model(slot, false, model_index).is_empty(),
				"sem Free disfarçado de PRO: %s/%d" % [slot, model_index])

	var nonce := str(Time.get_ticks_usec())
	var path := "user://test_free_%s.cfg" % nonce
	var free := StudioState.new()
	free.storage_path = path
	_check(not free.select_model(3), "modelo retirado não pode ser escolhido")
	_check(not free.select_model(4), "PRO exige direito real")
	_check(not free.wear("pro_kawaii_dress_00"), "roupa PRO exige direito")
	_check(free.wear("free_top_00_00"), "Amora veste blusa Free")
	_check(free.wear("free_bottom_00_00"), "Amora veste saia Free")
	_check(free.wear("free_dress_00_00"), "Amora veste vestido Free")
	_check(free.outfit["top"] == "" and free.outfit["bottom"] == "",
		"vestido substitui blusa e saia")
	_check(free.undo(), "desfazer restaura blusa/saia")
	_check(free.outfit["top"] == "free_top_00_00", "blusa recuperada")
	_check(free.save() == OK, "look Free salvo")
	var loaded := StudioState.new()
	loaded.storage_path = path
	loaded.load_saved()
	_check(loaded.outfit["top"] == "free_top_00_00", "look Free restaurado")
	_check(loaded.select_model(1), "Céu selecionável")
	_check(loaded.outfit["top"] == "" and loaded.outfit["bottom"] == "",
		"troca de modelo Free remove roupa exclusiva de outra")
	_check(not loaded.wear("free_top_00_00"), "Céu não usa roupas da Amora")
	_check(loaded.wear("free_top_01_04"), "Céu usa seus próprios itens")
	_check(loaded.select_model(2), "Mel selecionável")
	_check(loaded.wear("free_dress_02_02"), "Mel usa vestido original")
	_check(not loaded.wear("free_dress_01_02"), "sem sobreposição entre bonecas Free")
	_check(loaded.select_challenge(2), "desafio parque selecionável")
	_check(loaded.wear("free_top_02_00"), "trocar vestido por blusa")
	_check(loaded.wear("free_bottom_02_00"), "saia combinada")
	_check(loaded.challenge_progress() == 2, "desafio resolvido usando Free")

	var owned := StudioState.new()
	owned.owned_pro = true
	_check(owned.select_model(4), "Luna PRO selecionável")
	_check(owned.wear("pro_kawaii_dress_24") and owned.wear("pro_kawaii_accessory_49"),
		"últimos itens PRO continuam vestíveis")
	_check(owned.select_model(13), "Tainá PRO selecionável")
	_check(owned.outfit["dress"] == "pro_kawaii_dress_24" and
		owned.outfit["accessory"] == "pro_kawaii_accessory_49",
		"troca entre bonecas PRO preserva look")
	_check(owned.select_model(0), "retorno a Free")
	_check(owned.outfit["dress"] == "" and owned.outfit["accessory"] == "",
		"não expõe roupa PRO em boneca Free")
	var pro_save := "user://test_pro_%s.cfg" % nonce
	owned.storage_path = pro_save
	_check(owned.save() == OK, "salvar PRO")
	var fake := ConfigFile.new()
	fake.set_value("studio", "model", 13)
	fake.set_value("outfit", "dress", "pro_kawaii_dress_24")
	fake.save(path)
	var not_owned := StudioState.new()
	not_owned.storage_path = path
	not_owned.load_saved()
	_check(not_owned.model_index == 0 and not_owned.outfit["dress"].is_empty() == false,
		"arquivo alterado não libera PRO")
	fake.set_value("studio", "model", 3)
	fake.save(path)
	not_owned.load_saved()
	_check(not_owned.model_index == 0, "índice de modelo legado 3 migra para Amora")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(pro_save))
	print("Catálogo Free + PRO: %d falhas" % errors)
	quit(1 if errors > 0 else 0)
