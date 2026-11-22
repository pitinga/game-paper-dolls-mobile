extends RefCounted
## Galeria (Android 10+) e compartilhamento via FileProvider (Android 7+).
## Não solicita acesso a fotos, armazenamento nem internet.


static func can_save_to_gallery() -> bool:
	if OS.get_name() != "Android" or not Engine.has_singleton("AndroidRuntime"):
		return false
	var wrapper: Object = Engine.get_singleton("JavaClassWrapper")
	if wrapper == null:
		return false
	var Version: Object = wrapper.wrap("android.os.Build$VERSION")
	return Version != null and int(Version.SDK_INT) >= 29


static func save_png(local_path: String) -> String:
	if not can_save_to_gallery():
		return ""
	var wrapper: Object = Engine.get_singleton("JavaClassWrapper")
	var runtime: Object = Engine.get_singleton("AndroidRuntime")
	var context: Object = runtime.getApplicationContext()
	var resolver: Object = context.getContentResolver()
	var Media: Object = wrapper.wrap("android.provider.MediaStore$Images$Media")
	var ContentValues: Object = wrapper.wrap("android.content.ContentValues")
	var File: Object = wrapper.wrap("java.io.File")
	var Files: Object = wrapper.wrap("java.nio.file.Files")
	if Media == null or ContentValues == null or File == null or Files == null:
		return ""
	var values: Object = ContentValues.ContentValues()
	values.put("_display_name", local_path.get_file())
	values.put("mime_type", "image/png")
	values.put("relative_path", "Pictures/Veste e Cria")
	values.put("is_pending", 1)
	var uri: Object = resolver.insert(Media.EXTERNAL_CONTENT_URI, values)
	if wrapper.get_exception() != null or uri == null:
		push_warning("MediaStore não aceitou a criação da imagem.")
		return ""
	var output_stream: Object = resolver.openOutputStream(uri)
	var succeeded := false
	if output_stream != null and wrapper.get_exception() == null:
		var file: Object = File.File(ProjectSettings.globalize_path(local_path))
		var copied: int = int(Files.copy(file.toPath(), output_stream))
		succeeded = copied == FileAccess.get_file_as_bytes(local_path).size() and wrapper.get_exception() == null
	if output_stream != null:
		output_stream.close()
		if wrapper.get_exception() != null:
			succeeded = false
	if not succeeded:
		resolver.delete(uri, null, null)
		push_warning("Falha ao copiar o PNG para a galeria; original preservado no app.")
		return ""
	values.clear()
	values.put("is_pending", 0)
	var updated: int = int(resolver.update(uri, values, null, null))
	if wrapper.get_exception() != null or updated < 1:
		resolver.delete(uri, null, null)
		push_warning("Falha ao confirmar a imagem na galeria.")
		return ""
	return str(uri.toString())


static func share_image(local_path: String, gallery_uri: String = "") -> bool:
	if local_path.is_empty() or not FileAccess.file_exists(local_path) or OS.get_name() != "Android" or not Engine.has_singleton("AndroidRuntime"):
		return false
	var wrapper: Object = Engine.get_singleton("JavaClassWrapper")
	var runtime: Object = Engine.get_singleton("AndroidRuntime")
	if wrapper == null:
		return false
	var Intent: Object = wrapper.wrap("android.content.Intent")
	var ClipData: Object = wrapper.wrap("android.content.ClipData")
	var Uri: Object = wrapper.wrap("android.net.Uri")
	var File: Object = wrapper.wrap("java.io.File")
	var FileProvider: Object = wrapper.wrap("androidx.core.content.FileProvider")
	if Intent == null or ClipData == null or Uri == null or File == null or FileProvider == null:
		return false
	var context: Object = runtime.getApplicationContext()
	var uri: Object = null
	if not gallery_uri.is_empty():
		uri = Uri.parse(gallery_uri)
	else:
		# FileProvider já faz parte do template Android 4.7.2; o Manifest
		# exportado declara <package>.fileprovider e files-path para user://.
		uri = FileProvider.getUriForFile(context, str(context.getPackageName()) + ".fileprovider",
			File.File(ProjectSettings.globalize_path(local_path)))
	if uri == null or wrapper.get_exception() != null:
		return false
	var intent: Object = Intent.Intent()
	intent.setAction(Intent.ACTION_SEND)
	intent.setType("image/png")
	intent.putExtra(Intent.EXTRA_STREAM, uri)
	# O mesmo URI em ClipData assegura a permissão temporária de leitura
	# também para aplicativos que ignoram a entrada EXTRA_STREAM.
	intent.setClipData(ClipData.newUri(context.getContentResolver(), "Criação", uri))
	intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
	var chooser: Object = Intent.createChooser(intent, "Compartilhar criação")
	chooser.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
	var activity: Object = runtime.getActivity()
	if wrapper.get_exception() != null or activity == null:
		return false
	# startActivity deve ocorrer na thread UI do Android.
	var task := func() -> void:
		activity.startActivity(chooser)
	activity.runOnUiThread(runtime.createRunnableFromGodotCallable(task))
	return wrapper.get_exception() == null
