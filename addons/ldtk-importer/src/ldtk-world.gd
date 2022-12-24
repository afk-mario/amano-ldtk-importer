@tool

const Util = preload("../util/util.gd")
const Level = preload("ldtk-level.gd")


static func create_world(name: String, levels: Array) -> Node2D:
	var world = Node2D.new()
	world.name = name

	for level in levels:
		world.add_child(level)
		level.set_owner(world)

		for node in level.get_children():
			Util.recursive_set_owner(node, world, null)

	return world


static func create_world_with_external_levels(name: String, levels_paths: Array) -> Node2D:
	var world = Node2D.new()
	world.name = name

	for level_path in levels_paths:
		if ResourceLoader.exists(level_path):
			var packed_level = load(level_path)
			var level = packed_level.instantiate()

			world.add_child(level)
			level.set_owner(world)

	return world
