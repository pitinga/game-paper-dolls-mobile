extends RefCounted

const Catalog = preload("res://scripts/catalog.gd")
const STORAGE_PATH := "user://paper_dolls_studio.cfg"
const HISTORY_LIMIT := 30

var model_index := 0
var background_index := 0
var color_variant := 0
var challenge_index := -1
var owned_pro := false
var outfit: Dictionary = {}
var history: Array[Dictionary] = []
var storage_path := STORAGE_PATH


func _init() -> void:
	for slot in Catalog.SLOTS:
		outfit[slot] = ""


func wear(id: String) -> bool:
	var item: Dictionary = Catalog.by_id(id)
	if item.is_empty() or (bool(item["pro"]) and not owned_pro):
		return false
	var slot: String = item["slot"]
	if outfit.get(slot, "") == id:
		return false
	_remember()
	if slot == "dress":
		outfit["top"] = ""
		outfit["bottom"] = ""
	elif slot == "top" or slot == "bottom":
		outfit["dress"] = ""
	outfit[slot] = id
	return true


func remove(slot: String) -> bool:
	if not Catalog.SLOTS.has(slot) or str(outfit.get(slot, "")).is_empty():
		return false
	_remember()
	outfit[slot] = ""
	return true


func reset_outfit() -> void:
	_remember()
	for slot in Catalog.SLOTS:
		outfit[slot] = ""


func select_model(index: int) -> bool:
	if index < 0 or index >= Catalog.MODEL_NAMES.size():
		return false
	if index == model_index:
		return false
	_remember()
	model_index = index
	return true


func select_background(index: int) -> bool:
	if index < 0 or index >= Catalog.BACKGROUNDS.size():
		return false
	if bool(Catalog.BACKGROUNDS[index]["pro"]) and not owned_pro:
		return false
	if index == background_index:
		return false
	_remember()
	background_index = index
	return true


func select_color(index: int) -> bool:
	if index < 0 or index > 4 or index == color_variant:
		return false
	_remember()
	color_variant = index
	return true


func select_challenge(index: int) -> bool:
	if index < -1 or index >= Catalog.CHALLENGES.size():
		return false
	_remember()
	challenge_index = index
	if index >= 0:
		background_index = int(Catalog.CHALLENGES[index]["background"])
	return true


func challenge_progress() -> int:
	if challenge_index < 0:
		return 0
	var tag: String = Catalog.CHALLENGES[challenge_index]["tag"]
	var matched := 0
	for id in outfit.values():
		var item: Dictionary = Catalog.by_id(str(id))
		if not item.is_empty() and item["tag"] == tag:
			matched += 1
	return mini(matched, 2)


func undo() -> bool:
	if history.is_empty():
		return false
	var snapshot: Dictionary = history.pop_back()
	model_index = int(snapshot["model"])
	background_index = int(snapshot["background"])
	color_variant = int(snapshot["color"])
	challenge_index = int(snapshot["challenge"])
	outfit = snapshot["outfit"].duplicate(true)
	return true


func _remember() -> void:
	history.append({"model": model_index, "background": background_index,
		"color": color_variant, "challenge": challenge_index, "outfit": outfit.duplicate(true)})
	if history.size() > HISTORY_LIMIT:
		history.pop_front()


func save() -> Error:
	var config := ConfigFile.new()
	config.set_value("studio", "model", model_index)
	config.set_value("studio", "background", background_index)
	config.set_value("studio", "color", color_variant)
	config.set_value("studio", "challenge", challenge_index)
	for slot in Catalog.SLOTS:
		config.set_value("outfit", slot, outfit.get(slot, ""))
	return config.save(storage_path)


func load_saved() -> void:
	var config := ConfigFile.new()
	if config.load(storage_path) != OK:
		return
	model_index = clampi(int(config.get_value("studio", "model", 0)), 0, Catalog.MODEL_NAMES.size() - 1)
	var stored_bg := clampi(int(config.get_value("studio", "background", 0)), 0, Catalog.BACKGROUNDS.size() - 1)
	background_index = stored_bg if owned_pro or not bool(Catalog.BACKGROUNDS[stored_bg]["pro"]) else 0
	color_variant = clampi(int(config.get_value("studio", "color", 0)), 0, 4)
	challenge_index = clampi(int(config.get_value("studio", "challenge", -1)), -1, Catalog.CHALLENGES.size() - 1)
	for slot in Catalog.SLOTS:
		var stored_id: String = str(config.get_value("outfit", slot, ""))
		var item: Dictionary = Catalog.by_id(stored_id)
		outfit[slot] = stored_id if not item.is_empty() and item["slot"] == slot and (owned_pro or not bool(item["pro"])) else ""
	# Arquivos externos não podem criar roupas incompatíveis entre si.
	if not outfit["dress"].is_empty():
		outfit["top"] = ""
		outfit["bottom"] = ""
	history.clear()
