extends SceneTree

var problems := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(valid: bool, description: String) -> void:
	if not valid:
		push_error(description)
		problems += 1


func _run() -> void:
	var presets := ConfigFile.new()
	_check(presets.load("res://export_presets.cfg") == OK, "Preset carregável")
	for production in [0, 1]:
		var section := "preset.%d" % production
		var flags: String = str(presets.get_value(section, "custom_features", ""))
		_check(not flags.contains("paper_dolls_pro_test"), "Pro teste NÃO deve entrar no preset oficial " + section)
		_check(str(presets.get_value(section + ".options", "package/unique_name", "")) == "com.pitinga.paperdolls", "Identidade do aplicativo principal")
	# O arquivo exportado nunca deve empacotar sprites legados de terceiros.
	for index in range(3):
		var excludes: String = str(presets.get_value("preset.%d" % index, "exclude_filter", ""))
		_check(excludes.contains("assets/paper/*") and excludes.contains("assets/paper/**/*"),
			"Preset %d exclui pasta assets/paper, inclusive subpastas" % index)
	var debug_flags: String = str(presets.get_value("preset.2", "custom_features", ""))
	_check(debug_flags.contains("paper_dolls_pro_test"), "Preset de teste tem flag exclusiva")
	_check(str(presets.get_value("preset.2.options", "package/unique_name", "")) == "com.pitinga.paperdolls.protest", "Pacote de teste separado")
	_check(not bool(presets.get_value("preset.2.options", "gradle_build/use_gradle_build", true)), "Teste usa exportação direta, sem dependências Gradle")
	_check(not bool(presets.get_value("preset.2.options", "permissions/internet", true)), "APK Pro offline não deve solicitar INTERNET")
	_check(bool(presets.get_value("preset.2.options", "architectures/arm64-v8a", false)), "ARM64 incluído")
	_check(not bool(presets.get_value("preset.2.options", "architectures/armeabi-v7a", true)), "32 bits não incluído")
	print("Preset Pro de teste: %d falhas" % problems)
	quit(1 if problems > 0 else 0)
