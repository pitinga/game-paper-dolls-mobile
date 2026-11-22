extends SceneTree

const Catalog = preload("res://scripts/catalog.gd")
const StudioState = preload("res://scripts/studio_state.gd")

var errors := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, label: String) -> void:
	if not ok:
		push_error("FALHOU: " + label)
		errors += 1


func _run() -> void:
	var scratch := "user://test_paper_%d.cfg" % Time.get_ticks_usec()
	_check(Catalog.MODEL_NAMES.size() == 4, "quatro modelos jogáveis")
	_check(Catalog.count("accessory", true) == 12, "12 acessórios grátis")
	_check(Catalog.count("hair", true) == 4, "quatro penteados grátis")
	var clothing := 0
	for slot in ["top", "bottom", "dress", "shoes"]:
		clothing += Catalog.count(slot, true)
	_check(clothing == 30, "30 peças de roupas grátis")
	_check(Catalog.count("", false) >= 70, "coleções Pro adicionais")
	var ids := {}
	for item in Catalog.all_items():
		_check(not ids.has(item["id"]), "item sem ID duplicado " + item["id"])
		ids[item["id"]] = true
		_check(Catalog.SLOTS.has(item["slot"]), "item sem slot desconhecido")
	var state := StudioState.new()
	state.storage_path = scratch
	_check(state.wear("top_00"), "vestir camiseta")
	_check(state.wear("bottom_00"), "vestir shorts")
	_check(state.wear("dress_00"), "vestir vestido")
	_check(state.outfit["top"] == "" and state.outfit["bottom"] == "", "vestido substitui top/baixo")
	_check(state.undo(), "desfazer vestido")
	_check(state.outfit["top"] == "top_00" and state.outfit["bottom"] == "bottom_00", "undo restaura conjunto")
	_check(state.wear("top_01"), "trocar blusa")
	_check(state.outfit["top"] == "top_01", "nova blusa substitui anterior")
	_check(not state.wear("pro_dress_00"), "Pro não desbloqueável por ação local")
	_check(not state.select_background(5), "cenário Pro fica bloqueado")
	_check(state.save() == OK, "persistência inicial")
	state.outfit["top"] = "top_02"  # muda apenas memória, não arquivo
	var reloaded := StudioState.new()
	reloaded.storage_path = scratch
	reloaded.load_saved()
	_check(reloaded.outfit["top"] == "top_01", "round-trip realmente lê do arquivo")
	reloaded.reset_outfit()
	_check(reloaded.outfit["top"] == "", "limpar look")
	_check(reloaded.undo() and reloaded.outfit["top"] == "top_01", "limpeza reversível")
	_check(reloaded.select_model(3), "trocar modelo")
	_check(reloaded.model_index == 3, "modelo escolhido")
	_check(reloaded.select_color(4), "trocar cor")
	_check(reloaded.color_variant == 4, "cor escolhida")
	_check(reloaded.select_challenge(0), "desafio praia")
	_check(reloaded.background_index == 2, "desafio define cenário")
	for item in Catalog.all_items():
		if item["tag"] == "praia" and item["slot"] != "hair" and item["slot"] != "accessory" and not item["pro"]:
			reloaded.wear(item["id"])
			if reloaded.challenge_progress() == 2:
				break
	_check(reloaded.challenge_progress() == 2, "desafio satisfeito por combinação real")
	var pro_state := StudioState.new()
	pro_state.owned_pro = true
	_check(pro_state.wear("pro_dress_00"), "premium com direito verificado")
	_check(pro_state.select_background(5), "cenário Pro permitido")
	var invalid := ConfigFile.new()
	invalid.set_value("studio", "model", 99)
	invalid.set_value("studio", "background", 99)
	invalid.set_value("outfit", "dress", "injected_bad_id")
	invalid.save(scratch)
	var safe := StudioState.new()
	safe.storage_path = scratch
	safe.load_saved()
	_check(safe.model_index == 3, "clamp do modelo corrompido")
	_check(safe.background_index == 0, "cenário premium não restaurado sem direito")
	_check(safe.outfit["dress"] == "", "ignorar peça inexistente no arquivo")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch))
	print("Regras e catálogo: %d falhas" % errors)
	quit(1 if errors > 0 else 0)
