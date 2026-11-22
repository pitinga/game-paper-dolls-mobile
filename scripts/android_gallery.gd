extends RefCounted
## Ponte opcional para a galeria nativa do Android 10+ (API 29+).
## Android 7-9 continua salvando o PNG no armazenamento privado do app.
## Baseado nas APIs públicas MediaStore e ACTION_SEND, sem plugin de anúncios.


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
	var FileInputStream: Object = wrapper.wrap("java.io.FileInputStream")
	var Channels: Object = wrapper.wrap("java.nio.channels.Channels")
	if Media == null or ContentValues == null or FileInputStream == null or Channels == null:
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
	var input_stream: Object = FileInputStream.FileInputStream(ProjectSettings.globalize_path(local_path))
	var output_stream: Object = resolver.openOutputStream(uri)
	var succeeded := false
	if input_stream != null and output_stream != null and wrapper.get_exception() == null:
		var source_channel: Object = input_stream.getChannel()
		var destination_channel: Object = Channels.newChannel(output_stream)
		var bytes: int = int(source_channel.size())
		var transferred: int = int(source_channel.transferTo(0, bytes, destination_channel))
		succeeded = transferred == bytes and wrapper.get_exception() == null
	if output_stream != null:
		output_stream.close()
	if input_stream != null:
		input_stream.close()
	if not succeeded:
		resolver.delete(uri, null, null)
		push_warning("Falha ao copiar o PNG para a galeria; original preservado no app.")
		return ""
	values.clear()
	values.put("is_pending", 0)
	resolver.update(uri, values, null, null)
	if wrapper.get_exception() != null:
		push_warning("Falha ao confirmar a imagem na galeria.")
		return ""
	return str(uri.toString())


static func share_image(gallery_uri: String) -> bool:
	if gallery_uri.is_empty() or OS.get_name() != "Android" or not Engine.has_singleton("AndroidRuntime"):
		return false
	var wrapper: Object = Engine.get_singleton("JavaClassWrapper")
	var runtime: Object = Engine.get_singleton("AndroidRuntime")
	if wrapper == null:
		return false
	var Intent: Object = wrapper.wrap("android.content.Intent")
	var Uri: Object = wrapper.wrap("android.net.Uri")
	if Intent == null or Uri == null:
		return false
	var uri: Object = Uri.parse(gallery_uri)
	var intent: Object = Intent.Intent()
	intent.setAction(Intent.ACTION_SEND)
	intent.setType("image/png")
	intent.putExtra(Intent.EXTRA_STREAM, uri)
	intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
	var chooser: Object = Intent.createChooser(intent, "Compartilhar criação")
	var activity: Object = runtime.getActivity()
	if wrapper.get_exception() != null or activity == null:
		return false
	# startActivity deve ocorrer na thread UI do Android.
	var task := func() -> void:
		activity.startActivity(chooser)
	activity.runOnUiThread(runtime.createRunnableFromGodotCallable(task))
	return wrapper.get_exception() == null
