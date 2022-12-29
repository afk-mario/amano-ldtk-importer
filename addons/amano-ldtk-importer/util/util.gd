@tool

static func remove_recursive(path: String) -> void:
	# Open directory
	var directory := DirAccess.open(path)
	if directory:
		# List directory content
		directory.list_dir_begin()
		var file_name = directory.get_next()
		while file_name != "":
			if directory.current_is_dir():
				remove_recursive(path + "/" + file_name)
			else:
				directory.remove(file_name)
			file_name = directory.get_next()

		# Remove current path
		directory.remove(path)
	else:
		printerr("Error removing " + path)


static func get_save_folder_path(source_file: String) -> String:
	var directory_path = source_file.get_base_dir()
	var source_file_name = source_file.get_file().get_slice(".", 0)
	var save_path = directory_path + "/" + source_file_name

	return save_path


# Get LDtk file as JSON.
static func parse_ldtk_file(source_file: String) -> Dictionary:
	var json_file = FileAccess.open(source_file, FileAccess.READ)
	var data = JSON.parse_string(json_file.get_as_text())
	json_file = null
#	data["base_dir"] = source_file.get_base_dir()

	return data


static func recursive_set_owner(node: Node, new_owner: Node, root: Node):
	if node.owner != root and node.owner != null:
		return

	node.set_owner(new_owner)
	for child in node.get_children():
		recursive_set_owner(child, new_owner, root)


static func get_level_indicies(world_data: Dictionary, options: Dictionary) -> Array:
	var import_all = options.import_all_levels
	var level_indices = []

	if import_all:
		for i in world_data.levels.size():
			level_indices.append(i)
	else:
		level_indices = options.levels_to_import.split_floats(",", false)

	return level_indices
