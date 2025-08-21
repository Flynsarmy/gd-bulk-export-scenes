# This script extends EditorContextMenuPlugin and defines the custom menu action.
@tool
extends EditorContextMenuPlugin

# Single file export dialog
var file_dialog: FileDialog
# Bulk file export dialog
var dir_dialog: FileDialog
# List of TSCN paths selected in FileSystem
var selected_paths: Array[String] = []

func _popup_menu(paths: PackedStringArray) -> void:
	# Nothing to do
	if paths.size() < 1:
		return

	# Reset our array of paths
	selected_paths = []

	# Cache .tscn paths
	for path in paths:
		if path.ends_with(".tscn"):
			selected_paths.push_back(path)

	# Add single export menu item
	if selected_paths.size() == 1:
		add_context_menu_item("Export scene as GLTF", _on_export_selected)
	# Add bulk export menu item
	elif selected_paths.size() > 1:
		add_context_menu_item("Bulk export scenes as GLTF", _on_bulk_export_selected)

# Export multiple scenes
func _on_bulk_export_selected(_paths: PackedStringArray) -> void:
	dir_dialog.title = "Select a folder to export scenes to"
	dir_dialog.popup_centered()

# A directory was chosen. Run the export
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
func _on_export_selected(_paths: PackedStringArray) -> void:
	file_dialog.title = "Export Scene as GLTF"
	file_dialog.current_path = selected_paths[0] + ".glb"
	file_dialog.popup_centered()

# A filepath was chosen. Run the export
func _on_file_selected(to: String) -> void:
	var error: Error = _export_scene(selected_paths[0], to)

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
