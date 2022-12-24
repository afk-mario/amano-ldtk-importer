@tool
const Util = preload("../util/util.gd")

const Layer = preload("ldtk-layer.gd")
const Minimap = preload("ldtk-minimap.gd")


static func get_level_save_path(source_file: String) -> String:
	var save_path = Util.get_save_folder_path(source_file) + "/levels"
	return save_path


static func get_external_levels_paths(
	source_file: String, world_data: Dictionary, options: Dictionary
) -> Array:
	var directory_path = source_file.get_base_dir()
	var level_indices = Util.get_level_indicies(world_data, options)
	var levels_paths := []

	for i in level_indices:
		var level_data = world_data.levels[i]
		var path = directory_path + "/" + level_data.externalRelPath
		levels_paths.append(path)

	return levels_paths


static func create_world_levels(
	source_file: String, world_data: Dictionary, tilesets_dict: Dictionary, options: Dictionary
) -> Array:
	var level_indices = Util.get_level_indicies(world_data, options)
	var levels := []

	for i in level_indices:
		var level_data = world_data.levels[i]
		var level = create_level(source_file, level_data, tilesets_dict, options)
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
	tilesets_dict: Dictionary,
	options: Dictionary,
	is_external_level := false
) -> Node2D:
	if options.Generate_Minimaps:
		Minimap.create_level_mini_map(level_data, source_file, options, is_external_level)

	var level = Node2D.new()

	level.name = level_data.identifier
	level.position = Vector2(level_data.worldX, level_data.worldY)
	
	var layer_instances = Layer.get_level_layer_instances(
		source_file, level_data, tilesets_dict, options, is_external_level
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

		level = script.post_import(level)

		if not level or not level is Node2D:
			printerr("Invalid scene returned from post import script.")
			return null
	
	if options.Create_Level_Areas:
		var level_area = get_level_area(level_data, options)
		level.add_child(level_area)

	return level


static func get_level_area(level_data: Dictionary, options: Dictionary) -> Area2D:
	var level_meta = {}
	for field in level_data.fieldInstances:
		level_meta[field.__identifier] = field.__value

	var level_area = Area2D.new()
	var level_size = Vector2(level_data.pxWid, level_data.pxHei)
	var level_extents = (level_size / 2) + options.Level_Area_Padding
	var area_collision_layer = options.Level_Area_Collision_Layer

	level_area.name = "Level Area"

	if level_meta.has("Color"):
		level_area.modulate = Color(level_meta.Color)
		level_area.modulate.a = options.Level_Area_Opacity

	level_area.position.x = level_extents.x
	level_area.position.y = level_extents.y
	level_area.collision_layer = area_collision_layer
	level_area.collision_mask = 0

	var level_area_shape = CollisionShape2D.new()
	level_area_shape.name = "Level Area Collission Shape"
	level_area_shape.shape = RectangleShape2D.new()
	level_area_shape.shape.extents = level_extents

	level_area.add_child(level_area_shape)

	return level_area
