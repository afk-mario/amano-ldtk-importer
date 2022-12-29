@tool
const Util = preload("../util/util.gd")
const Level = preload("../util/level.gd")
const Field = preload("../util/field.gd")
const PostImport = preload("../util/post-import.gd")

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

		var level = create_level(source_file, world_data, level_data, layers_dict, tilesets_dict, options)
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
	world_data: Dictionary,
	level_data: Dictionary,
	layers_dict: Dictionary,
	tilesets_dict: Dictionary,
	options: Dictionary
) -> Node2D:
	var level = Node2D.new()
	var base_dir :String = source_file.get_base_dir()
	level.name = level_data.identifier
	level.position = Level.get_world_position(world_data, level_data)

	var fields = Field.get_field_instances_as_dict(level_data.fieldInstances)
	level.set_meta("LDtk_level_fields", fields)

	if options.level_add_metadata:
		level.set_meta("LDtk_raw_data", level_data)
		level.set_meta("LDtk_raw_defs", world_data.defs)
		level.set_meta("LDtk_source_file", source_file)

	if level_data.bgRelPath != null:
		var bg_data :Dictionary= level_data.__bgPos
		var sprite = Sprite2D.new()
		var texture_filepath :String = base_dir + "/" + level_data.bgRelPath
		var texture = load(texture_filepath)
		sprite.name = "Bg image"
		sprite.centered = false
		sprite.texture = texture
		if bg_data:
			if bg_data.cropRect:
				sprite.region_enabled = true
				sprite.region_rect = Rect2(
					bg_data.cropRect[0],
					bg_data.cropRect[1],
					bg_data.cropRect[2],
					bg_data.cropRect[3]
				)
			if bg_data.scale:
				sprite.scale = Vector2(bg_data.scale[0], bg_data.scale[1])
			if bg_data.topLeftPx:
				sprite.offset = Vector2(bg_data.topLeftPx[0], bg_data.topLeftPx[1])
		level.add_child(sprite)

	var layer_instances = Layer.get_level_layer_instances(
		source_file,
		world_data,
		level_data,
		layers_dict,
		tilesets_dict,
		options
	)

	for layer_instance in layer_instances:
		level.add_child(layer_instance)

	level = PostImport.run_post_import(
		level,
		options.level_post_import_script,
		source_file,
		"Level"
	)

	return level
