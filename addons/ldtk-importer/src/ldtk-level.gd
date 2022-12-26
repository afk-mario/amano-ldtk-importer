@tool
const Util = preload("../util/util.gd")

const Layer = preload("ldtk-layer.gd")


static func get_level_save_path(source_file: String) -> String:
	var save_path = Util.get_save_folder_path(source_file) + "/levels"
	return save_path

static func create_world_levels(
	source_file: String, world_data: Dictionary, tilesets_dict: Dictionary, options: Dictionary
) -> Array:
	var level_indices = Util.get_level_indicies(world_data, options)
	var levels := []
	
	
	for i in level_indices:
		var level_data = world_data.levels[i]
		# Group layers defs in to grid size level and add the index information
		var current_index = 0
		var layers_data := []
	
		for j in range(0, level_data.layerInstances.size()):
			var layer_data :Dictionary = level_data.layerInstances[j]
			layer_data.index = j
			layers_data.append(layer_data)
		
		var layers_dict :Dictionary = layers_data.reduce(
			func (acc, curr):
				var grid_size :int=curr.__gridSize
				if acc.get(grid_size) == null:
					acc[grid_size] = {}
				acc[int(grid_size)][int(curr.layerDefUid)] = curr
				return acc
		,{})
		
		var level = create_level(source_file, level_data, layers_dict, tilesets_dict, options)
		levels.push_back(level)

	return levels


static func save_levels(levels: Array, save_path: String, save_extension: String) -> Array:
	var levels_paths := []
	for level in levels:
		var level_path := "%s-%s-.%s" % [save_path, level.name, save_extension]
		var packed_level := pack_level(level)

		var err = ResourceSaver.save(packed_level, level_path)
		if err == OK:
			levels_paths.append(level_path)

	return levels_paths


static func pack_level(level: Node2D) -> PackedScene:
	for node in level.get_children():
		Util.recursive_set_owner(node, level, null)

	var packed_level = PackedScene.new()
	packed_level.pack(level)

	return packed_level


static func create_level(
	source_file: String,
	level_data: Dictionary,
	layers_dict: Dictionary,
	tilesets_dict: Dictionary,
	options: Dictionary
) -> Node2D:
	var level = Node2D.new()

	level.name = level_data.identifier
	level.position = Vector2(level_data.worldX, level_data.worldY)
	
	var layer_instances = Layer.get_level_layer_instances(
		source_file, level_data, layers_dict, tilesets_dict, options
	)

	for layer_instance in layer_instances:
		level.add_child(layer_instance)

	if not options.post_import_level_script.is_empty():
		var script = load(options.post_import_level_script)
		if not script or not script is GDScript:
			printerr("Post import script is not a GDScript.")
			return null

		script = script.new()
		if not script.has_method("post_import"):
			printerr("Post import script does not have a 'post_import' method.")
			return null

		level = script.post_import(level, level_data, source_file)

		if not level or not level is Node2D:
			printerr("Invalid scene returned from post import script.")
			return null

	return level
