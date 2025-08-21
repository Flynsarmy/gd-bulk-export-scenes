@tool
extends EditorPlugin

# We need a reference to our custom context menu plugin to add and remove it.
var export_context_menu_plugin: EditorContextMenuPlugin

# This function is called when the plugin is enabled.
func _enter_tree():
	# Create a new instance of our custom context menu plugin.
	export_context_menu_plugin = preload("export_context_menu_plugin.gd").new()
	# Add the plugin to the editor. This makes our menu option appear.
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM, export_context_menu_plugin)

	# We also need a FileDialog for single exports. Create it here.
	export_context_menu_plugin.file_dialog = FileDialog.new()
	export_context_menu_plugin.file_dialog.access = FileDialog.ACCESS_RESOURCES
	export_context_menu_plugin.file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	export_context_menu_plugin.file_dialog.add_filter("*.gltf, *.glb")

	# We need a DirectoryDialog for bulk exports. Create it here.
	export_context_menu_plugin.dir_dialog = FileDialog.new()
	export_context_menu_plugin.dir_dialog.access = FileDialog.ACCESS_RESOURCES
	export_context_menu_plugin.dir_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	export_context_menu_plugin.dir_dialog.add_option('format', ['glTF Binary (.glb)', 'glTF Separate (.gltf + .bin + textures)'], 0)

	# Connect the signals to the correct callback functions.
	export_context_menu_plugin.file_dialog.connect("file_selected", export_context_menu_plugin._on_file_selected)
	export_context_menu_plugin.dir_dialog.connect("dir_selected", export_context_menu_plugin._on_dir_selected)

	# Add both dialogs to the scene tree so they can be displayed.
	get_editor_interface().get_editor_main_screen().add_child(export_context_menu_plugin.file_dialog)
	get_editor_interface().get_editor_main_screen().add_child(export_context_menu_plugin.dir_dialog)


# This function is called when the plugin is disabled.
func _exit_tree():
	# Remove the plugin from the editor. This is crucial for cleanup.
	if export_context_menu_plugin:
		# Always remember to free the dialogs from the scene tree.
		if is_instance_valid(export_context_menu_plugin.file_dialog):
			export_context_menu_plugin.file_dialog.queue_free()
		if is_instance_valid(export_context_menu_plugin.dir_dialog):
			export_context_menu_plugin.dir_dialog.queue_free()

		remove_context_menu_plugin(export_context_menu_plugin)
		export_context_menu_plugin = null
