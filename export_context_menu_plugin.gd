# This script extends EditorContextMenuPlugin and defines the custom menu action.
@tool
extends EditorContextMenuPlugin

# We need a reference to the FileDialog and DirectoryDialog nodes, which will be created in the main plugin script.
var file_dialog: FileDialog
var dir_dialog: FileDialog
var selected_paths: Array[String] = []

# This function is called by Godot when a context menu is about to be displayed.
# The 'paths' argument contains a list of paths to the selected items.
func _popup_menu(paths: PackedStringArray) -> void:
	# Ensure only one file is selected to avoid unexpected behavior.
	if paths.size() < 1:
		return

	# Reset our array of paths
	selected_paths = []

	for path in paths:
		# Check if the selected file is a .tscn file.
		if path.ends_with(".tscn"):
			selected_paths.push_back(path)

	# Add our custom menu item if we've selected at least one TSCN
	if selected_paths.size() == 1:
		add_context_menu_item("Export scene as GLTF", _on_export_selected)
	elif selected_paths.size() > 1:
		add_context_menu_item("Bulk export scenes as GLTF", _on_bulk_export_selected)

# Export multiple scenes
func _on_bulk_export_selected(paths: PackedStringArray) -> void:
	dir_dialog.title = "Select a folder to export scenes to"
	dir_dialog.popup_centered()

# This function handles the bulk export after the user selects a directory.
# This is connected to the 'dir_selected' signal of the DirectoryDialog.
func _on_dir_selected(save_path: String) -> void:
	var errors: int = 0

	var extension: String = ".glb"
	if dir_dialog.get_selected_options()['format'] == 1:
		extension = '.gltf'

	# Loop through all the selected scene paths.
	for from in selected_paths:
		# Construct the 'to' path by combining the save directory with the scene's base name.
		var to: String = save_path.path_join(from.get_file().get_basename() + extension)
		var error: Error = _export_scene(from, to)

		if error != OK:
			errors += 1

	# Print a summary of the export operation.
	if errors == 0:
		print("Successfully exported ", selected_paths.size(), " scenes to: ", save_path)
	elif errors == selected_paths.size():
		push_error("Failed to export all ", errors, " scenes.")
	else:
		push_warning("Failed to export ", errors, " out of ", selected_paths.size(), " scenes.")

# Export a single scene
func _on_export_selected(paths: PackedStringArray) -> void:
	# We'll suggest a filename based on the selected scene's name.
	#var scene_name = selected_paths[0].get_file().get_basename()
	file_dialog.title = "Export Scene as GLTF"
	file_dialog.current_path = selected_paths[0] + ".glb"
	file_dialog.popup_centered()

## This is the new function that handles the file export after the user selects a location.
func _on_file_selected(to: String) -> void:
	var error: Error = _export_scene(selected_paths[0], to)

	# Print the result to the console.
	if error == OK:
		print("Successfully exported scene to: ", to)

func _export_scene(from: String, to: String) -> Error:
	# Load the scene file as a PackedScene.
	var scene_resource: PackedScene = ResourceLoader.load(from)

	# Check if the load was successful.
	if not scene_resource:
		push_error("Failed to load scene: ", from)
		return ERR_FILE_CORRUPT

	# Instance the scene to get the root node.
	var root_node = scene_resource.instantiate()

	# Create a new GLTFDocument and GLTFState to handle the export.
	var gltf_document: GLTFDocument = GLTFDocument.new()
	var gltf_state: GLTFState = GLTFState.new()

	# Append the scene's data to the GLTFState.
	var error = gltf_document.append_from_scene(root_node, gltf_state)

	# Check for errors during the append operation.
	if error != OK:
		push_error("Failed to append scene to GLTF state. Error code: ", error)
		root_node.queue_free()
		return error

	# Save the GLTF state to the new path.
	error = gltf_document.write_to_filesystem(gltf_state, to)

	# Free the temporary node.
	root_node.queue_free()
	return error
