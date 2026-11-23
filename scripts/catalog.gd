extends RefCounted
## Identificadores estáveis: looks antigos continuam legíveis após atualizações.

const KawaiiCollection = preload("res://scripts/kawaii_collection.gd")

const SLOTS := ["hair", "top", "bottom", "dress", "shoes", "accessory"]
const CATEGORIES := ["top", "bottom", "dress", "shoes", "hair", "accessory"]
const CATEGORY_NAMES := {
	"top": "Blusas", "bottom": "Shorts e saias", "dress": "Vestidos",
	"shoes": "Sapatos", "hair": "Cabelos", "accessory": "Acessórios"
}
const MODEL_NAMES := ["Lia", "Bia", "Nina", "Duda", "Luna", "Yumi", "Maya", "Clara",
	"Jade", "Sol", "Amira", "Sofia", "Isis", "Tainá"]
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
	var colors := ["ff7498", "65bfe0", "edb551", "a68ade", "62be9a", "ef8e61", "df72b6", "5a9de7"]
	var tags := ["festa", "praia", "parque", "inverno", "fantasia", "festa", "parque", "praia"]
	var motifs := ["coracao", "estrela", "flor", "bolinhas", "listras", "fruta", "borboleta", "simples"]
	var shapes := {
		"top": ["camiseta", "regata", "manga", "blusa", "cropped", "casaco", "camiseta", "manga"],
		"bottom": ["shorts", "calca", "shorts", "shorts", "calca", "calca", "shorts", "calca"],
		"dress": ["rodado", "reto", "rodado", "festa", "reto", "rodado", "festa", "reto"],
		"shoes": ["tenis", "sandalia", "bota", "sapato", "tenis", "bota"]
	}
	var names := {
		"top": ["Doce surpresa", "Docinho do mar", "Joaninha", "Corujinha", "Flor do campo", "Joaninha feliz", "Doces", "Cupcake"],
		"bottom": ["Short esportivo", "Calça de passeio", "Short de verão", "Short leve", "Calça de brincar", "Calça confortável", "Short de praia", "Calça de festa"],
		"dress": ["Vestido de babados", "Vestido estampado", "Vestido de bolinhas", "Macacão listrado", "Macacão de verão", "Macacão de passeio", "Vestido girassol", "Vestido cereja"],
		"shoes": ["Tênis com cadarço", "Sandália leve", "Botas de passeio", "Botinhas", "Sapatos de festa", "Sapatilhas"]
	}
	for slot in ["top", "bottom", "dress", "shoes"]:
		for index in range(shapes[slot].size()):
			_all.append(_item(slot + "_%02d" % index, names[slot][index], slot,
				shapes[slot][index], Color(colors[index]), motifs[index], tags[index]))
	# Quatro opções de cabelo livres para os quatro modelos.
	for index in range(4):
		_all.append(_item("hair_%02d" % index, ["Coquinhos", "Soltinho", "Tranças", "Cacheado"][index],
			"hair", ["coques", "solto", "trancas", "cacheado"][index],
			Color(["734f42", "d28641", "332837", "9b5f32"][index]), "simples", tags[index]))
	var accessories := [
		["Óculos coração", "oculos", "festa"], ["Bolsa flor", "bolsa", "parque"],
		["Chapéu de praia", "chapeu", "praia"], ["Colar de estrelas", "colar", "festa"],
		["Laço de fita", "laco", "fantasia"], ["Bolsa arco-íris", "bolsa", "parque"],
		["Óculos sol", "oculos", "praia"], ["Coroa", "coroa", "fantasia"],
		["Cachecol", "cachecol", "inverno"], ["Tiara flor", "tiara", "parque"],
		["Colar coração", "colar", "festa"], ["Gorrinho", "gorro", "inverno"]
	]
	for index in range(accessories.size()):
		_all.append(_item("accessory_%02d" % index, accessories[index][0], "accessory",
			accessories[index][1], Color(colors[index % colors.size()]), motifs[index % motifs.size()], accessories[index][2]))
	# Peças extras Pro: itens básicos acima permanecem gratuitos.
	for slot in ["top", "bottom", "dress", "shoes", "hair", "accessory"]:
		for index in range(4):
			var styles: Array = shapes.get(slot, ["coques", "solto", "trancas", "cacheado"] if slot == "hair" else ["coroa", "bolsa", "tiara", "cachecol"])
			_all.append(_item("pro_%s_%02d" % [slot, index], "Coleção brilho %d" % (index + 1),
				slot, styles[index % styles.size()], Color(colors[(index + 4) % colors.size()]),
				motifs[(index + 2) % motifs.size()], tags[(index + 3) % tags.size()], true))
	# Os 150 assets premium originais têm sprite próprio, IDs estáveis
	# e podem ser usados nas dez bonecas kawaii (índices 4..13).
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


static func model_requires_pro(index: int) -> bool:
	return index >= KAWAII_MODEL_INDEX


static func item_matches_model(item: Dictionary, model_index: int) -> bool:
	if model_index >= KAWAII_MODEL_INDEX:
		return bool(item.get("kawaii", false))
	return not bool(item.get("kawaii", false))


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
