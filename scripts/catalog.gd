extends RefCounted
## Identificadores estáveis: looks antigos continuam legíveis após atualizações.

const KawaiiCollection = preload("res://scripts/kawaii_collection.gd")
const FreeCollection = preload("res://scripts/free_collection.gd")

const SLOTS := ["hair", "top", "bottom", "dress", "shoes", "accessory"]
const CATEGORIES := ["top", "bottom", "dress", "shoes", "accessory"]
const CATEGORY_NAMES := {
	"top": "Blusas", "bottom": "Shorts e saias", "dress": "Vestidos",
	"shoes": "Sapatos", "hair": "Cabelos", "accessory": "Acessórios"
}
# Index 3 is intentionally retired to preserve old Pro save indices 4..13.
# The UI lists MODEL_SELECTION (3 Free + 10 Pro), never the retired model.
const MODEL_NAMES := ["Amora", "Céu", "Mel", "", "Luna", "Yumi", "Maya", "Clara",
	"Jade", "Sol", "Amira", "Sofia", "Isis", "Tainá"]
const MODEL_SELECTION := [0, 1, 2, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]
const KAWAII_MODEL_INDEX := 4
const MODEL_SKIN := [
	Color("f5b68f"), Color("c98060"), Color("8f533f"), Color("e5a47c")
]
const MODEL_HAIR := [
	Color("e7c690"), Color("cf6d37"), Color("282125"), Color("86532e")
]
const BACKGROUNDS := [
	{"name": "Ateliê", "top": Color("ffedf5"), "bottom": Color("ffd7e7"), "pro": false},
	{"name": "Jardim", "top": Color("dff8e5"), "bottom": Color("b8e9c6"), "pro": false},
	{"name": "Praia", "top": Color("d7f8ff"), "bottom": Color("ffe0aa"), "pro": false},
	{"name": "Festa", "top": Color("efe3ff"), "bottom": Color("d6bdfc"), "pro": false},
	{"name": "Parque", "top": Color("e2f5fc"), "bottom": Color("ffe6c5"), "pro": false},
	{"name": "Noite estrelada", "top": Color("465481"), "bottom": Color("a9a0dc"), "pro": true},
	{"name": "Castelo", "top": Color("ffe8bc"), "bottom": Color("f9cfd5"), "pro": true},
	{"name": "Arco-íris", "top": Color("f5d5ff"), "bottom": Color("f5f6ba"), "pro": true}
]
const CHALLENGES := [
	{"name": "Dia de praia", "tag": "praia", "background": 2, "hint": "Combine 2 peças de praia!"},
	{"name": "Festa colorida", "tag": "festa", "background": 3, "hint": "Combine 2 peças de festa!"},
	{"name": "Passeio no parque", "tag": "parque", "background": 4, "hint": "Combine 2 peças de passeio!"},
	{"name": "Inverno quentinho", "tag": "inverno", "background": 0, "hint": "Combine 2 peças de inverno!"},
	{"name": "Baile à fantasia", "tag": "fantasia", "background": 3, "hint": "Combine 2 peças de fantasia!"}
]

static var _all: Array[Dictionary] = []


static func all_items() -> Array[Dictionary]:
	if _all.is_empty():
		_populate()
	return _all


static func _populate() -> void:
	# 75 unique Free pieces; each doll has 5 tops, bottoms, dresses,
	# shoes and accessories. No old licensed/paper sprites are referenced.
	var free_colors := ["b4e5cb", "a9c9f3", "f5cf80"]
	for spec in FreeCollection.ITEMS:
		var slot: String = str(spec["slot"])
		var id: String = str(spec["id"])
		var model_index: int = int(spec["model"])
		var style := "blusa" if slot == "top" else ("shorts" if slot == "bottom"
			else ("rodado" if slot == "dress" else ("sapato" if slot == "shoes" else "tiara")))
		var tag := "inverno" if str(spec["name"]).to_lower().contains("inverno") else (
			"praia" if slot == "shoes" else ("festa" if slot == "dress" else "parque"))
		var item := _item(id, str(spec["name"]), slot, style,
			Color(free_colors[model_index]), "simples", tag)
		item["sprite"] = str(spec["sprite"])
		item["free_model_index"] = model_index
		_all.append(item)

	# The 160 original PRO images are unchanged (10 dolls and 150 wearables).
	# Preserve their historic item IDs and model indexes 4..13.
	var kawaii_colors := ["ff9cbc", "ac98dc", "8ecdc2", "f2c578", "8eb7e0"]
	for spec in KawaiiCollection.ITEMS:
		var slot: String = str(spec["slot"])
		var id: String = str(spec["id"])
		var anchor: String = str(spec["anchor"])
		var style := "laco"
		match slot:
			"top": style = "blusa"
			"bottom": style = "shorts"
			"dress": style = "rodado"
			"shoes": style = "sapato"
			"accessory":
				style = {"bag": "bolsa", "eyes": "oculos", "hat": "chapeu",
					"crown": "coroa", "neck": "colar", "wrist": "pulseira",
					"head": "tiara"}.get(anchor, "laco")
		var index := int(id.get_slice("_", id.get_slice_count("_") - 1))
		var tag := "festa"
		if slot == "bottom" or slot == "top":
			tag = "parque"
		if anchor == "feet" or anchor == "bag":
			tag = "praia"
		if "cachecol" in str(spec["name"]).to_lower() or "gorro" in str(spec["name"]).to_lower():
			tag = "inverno"
		var item := _item(id, str(spec["name"]), slot, style,
			Color(kawaii_colors[index % kawaii_colors.size()]), "simples", tag, true)
		item["sprite"] = "kawaii/" + id
		item["model_index"] = KAWAII_MODEL_INDEX
		item["kawaii"] = true
		item["anchor"] = anchor
		_all.append(item)


static func model_is_selectable(index: int) -> bool:
	return MODEL_SELECTION.has(index)


static func model_requires_pro(index: int) -> bool:
	return index >= KAWAII_MODEL_INDEX


static func item_matches_model(item: Dictionary, model_index: int) -> bool:
	if not model_is_selectable(model_index):
		return false
	if model_requires_pro(model_index):
		return bool(item.get("kawaii", false))
	return item.has("free_model_index") and int(item["free_model_index"]) == model_index


static func _item(id: String, title: String, slot: String, style: String, color: Color,
		motif: String, tag: String, premium: bool = false) -> Dictionary:
	return {"id": id, "name": title, "slot": slot, "style": style, "color": color,
		"motif": motif, "tag": tag, "pro": premium}


static func by_id(id: String) -> Dictionary:
	for item in all_items():
		if item["id"] == id:
			return item
	return {}


static func filtered(slot: String, include_pro: bool = true) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in all_items():
		if item["slot"] == slot and (include_pro or not bool(item["pro"])):
			result.append(item)
	return result


static func filtered_for_model(slot: String, include_pro: bool, model_index: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in filtered(slot, include_pro):
		if item_matches_model(item, model_index):
			result.append(item)
	return result


static func count(slot: String = "", free_only: bool = false) -> int:
	var quantity := 0
	for item in all_items():
		if (slot.is_empty() or item["slot"] == slot) and (not free_only or not bool(item["pro"])):
			quantity += 1
	return quantity
