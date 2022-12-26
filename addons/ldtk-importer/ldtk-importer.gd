@tool
extends EditorPlugin

var import_world_plugin = null

func _get_plugin_name() -> String:
	return "LDtk importer"

func _enter_tree() -> void:
	import_world_plugin = preload("ldtk-world-importer.gd").new()
	add_import_plugin(import_world_plugin)

func _exit_tree() -> void:
	remove_import_plugin(import_world_plugin)
	import_world_plugin = null
