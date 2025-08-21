@tool
extends EditorPlugin

var export_context_menu_plugin: EditorContextMenuPlugin

func _enter_tree():
	export_context_menu_plugin = preload("export_context_menu_plugin.gd").new()
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM, export_context_menu_plugin)

	# Single export dialog window
	export_context_menu_plugin.file_dialog = FileDialog.new()
	export_context_menu_plugin.file_dialog.access = FileDialog.ACCESS_RESOURCES
	export_context_menu_plugin.file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	export_context_menu_plugin.file_dialog.add_filter("*.gltf, *.glb")
	export_context_menu_plugin.file_dialog.connect("file_selected", export_context_menu_plugin._on_file_selected)
	get_editor_interface().get_editor_main_screen().add_child(export_context_menu_plugin.file_dialog)

	# Bulk export dialog window
	export_context_menu_plugin.dir_dialog = FileDialog.new()
	export_context_menu_plugin.dir_dialog.access = FileDialog.ACCESS_RESOURCES
	export_context_menu_plugin.dir_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	export_context_menu_plugin.dir_dialog.add_option('format', ['glTF Binary (.glb)', 'glTF Separate (.gltf + .bin + textures)'], 0)
	export_context_menu_plugin.dir_dialog.connect("dir_selected", export_context_menu_plugin._on_dir_selected)
	get_editor_interface().get_editor_main_screen().add_child(export_context_menu_plugin.dir_dialog)


func _exit_tree():
	if export_context_menu_plugin:
		if is_instance_valid(export_context_menu_plugin.file_dialog):
			export_context_menu_plugin.file_dialog.queue_free()
		if is_instance_valid(export_context_menu_plugin.dir_dialog):
			export_context_menu_plugin.dir_dialog.queue_free()

		remove_context_menu_plugin(export_context_menu_plugin)
		export_context_menu_plugin = null
