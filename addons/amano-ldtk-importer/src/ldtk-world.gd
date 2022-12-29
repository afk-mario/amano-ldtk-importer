@tool

const Util = preload("../util/util.gd")
const PostImport = preload("../util/post-import.gd")

const Level = preload("ldtk-level.gd")


static func create_world(
	world_data: Dictionary,
	levels: Array,
	source_file: String,
	options: Dictionary
) -> Node2D:
	var world = Node2D.new()
	world.name = source_file.get_file().get_basename()

	if options.world_add_metadata:
		world.set_meta("LDtk_raw_data", world_data)
		world.set_meta("LDtk_source_file", source_file)

	for level in levels:
		world.add_child(level)
		level.set_owner(world)

		for node in level.get_children():
			Util.recursive_set_owner(node, world, null)


	world = PostImport.run_post_import(
		world,
		options.world_post_import_script,
		source_file,
		"World"
	)

	return world


static func create_world_with_external_levels(
	world_data: Dictionary,
	levels_paths: Array,
	source_file: String,
	options: Dictionary
) -> Node2D:
	var world = Node2D.new()
	world.name = source_file.get_file().get_basename()

	if options.world_add_metadata:
		world.set_meta("LDtk_raw_data", world_data)
		world.set_meta("LDtk_source_file", source_file)

	for level_path in levels_paths:
		if ResourceLoader.exists(level_path):
			var packed_level = load(level_path)
			var level = packed_level.instantiate()

			world.add_child(level)
			level.set_owner(world)


	world = PostImport.run_post_import(
		world,
		options.world_post_import_script,
		source_file,
		"World"
	)

	return world
