@tool
extends EditorPlugin

var import_world_plugin = null
var import_level_plugin = null

func _get_plugin_name() -> String:
	return "LDtk importer"

func _enter_tree() -> void:
	import_world_plugin = preload("ldtk-world-importer.gd").new()
	import_level_plugin = preload("ldtk-level-importer.gd").new()
	add_import_plugin(import_world_plugin)
	add_import_plugin(import_level_plugin)



func _exit_tree() -> void:
#	remove_import_plugin(import_world_plugin)
	remove_import_plugin(import_level_plugin)
	import_world_plugin = null
	import_level_plugin = null
