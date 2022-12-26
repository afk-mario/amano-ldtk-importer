@tool
extends Node

var scripts = [
	preload("./post-import-level-show-collisions.gd"),
	preload("./post-import-add-level-areas.gd"),
	preload("./minimap/post-import-level-gen-minimap.gd")
]

func post_import(level: Node2D, level_data: Dictionary, source_file: String) -> Node2D:
	for script in scripts:
		var instance = script.new()
		level = instance.post_import(level, level_data, source_file)

	return level
