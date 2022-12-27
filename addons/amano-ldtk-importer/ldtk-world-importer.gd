@tool
extends EditorImportPlugin

const Util = preload("util/util.gd")

const LdtkWorld = preload("src/ldtk-world.gd")
const Level = preload("src/ldtk-level.gd")
const Tileset = preload("src/ldtk-tileset.gd")


enum Presets { PRESET_DEFAULT, PRESET_COLLISIONS }

func _get_importer_name() -> String:
	return "LDtk_world.import"


func _get_visible_name() -> String:
	return "LDtk World Scene"


func _get_priority() -> float:
	return 1.0


func _get_import_order() -> int:
	return 100


func _get_resource_type() -> String:
	return "PackedScene"


func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["ldtk"])


func _get_save_extension() -> String:
	return "scn"


func _get_preset_count() -> int:
	return Presets.size()


func _get_preset_name(preset: int) -> String:
	match preset:
		Presets.PRESET_DEFAULT:
			return "Default"
		Presets.PRESET_COLLISIONS:
			return "Import Collisions"
	return ""

func _get_import_options(path: String, preset_index: int) -> Array:
	return [
		{
			"name": "world_post_import_script",
			"default_value": "",
			"property_hint": PROPERTY_HINT_FILE,
			"hint_string": "*.gd;GDScript"
		},
		{"name": "Tilesets", "default_value": "", "usage": PROPERTY_USAGE_GROUP},
		{"name": "import_tileset_custom_data", "default_value": true},
		{
			"name": "tileset_post_import_script",
			"default_value": "",
			"property_hint": PROPERTY_HINT_FILE,
			"hint_string": "*.gd;GDScript"
		},
		{"name": "Levels", "default_value": "", "usage": PROPERTY_USAGE_GROUP},
		{
			"name": "post_import_level_script",
			"default_value": "",
			"property_hint": PROPERTY_HINT_FILE,
			"hint_string": "*.gd;GDScript"
		},
		{"name": "import_all_levels", "default_value": true},
		{
			"name": "Levels_To_import",
			"default_value": "0,1",
			"hint_string": "usage: 1,3,6 where the numbers represent the level index"
		},
		{"name": "pack_levels", "default_value": false},
		{"name": "Entities", "default_value": "", "usage": PROPERTY_USAGE_GROUP},
		{
			"name": "import_custom_entities",
			"default_value": true,
			"hint_string":
			"If true, will only use this project's scenes. If false, will import objects as simple scenes."
		},
		{
			"name": "import_metadata",
			"default_value": true,
			"hint_string": "If true, will import entity fields as metadata."
		}
	]

func _get_option_visibility(path: String, option_name: StringName, options: Dictionary) -> bool:
	if option_name == "Levels_To_import":
		return not options.import_all_levels
	return true


func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array, gen_files: Array) -> int:
	var world_data := Util.parse_ldtk_file(source_file)
	var has_external_levels: bool = world_data.externalLevels
	var tilesets_dict := Tileset.get_tilesets_dict(
		source_file, world_data, options
	)

	var world
	var world_name := source_file.get_file().get_basename()
	var tilesets_paths := Tileset.create_tileset_resources(source_file, tilesets_dict)

	for file_path in tilesets_paths:
		gen_files.push_back(file_path)

	if has_external_levels:
		printerr("External levels are not supported")
	else:
		var levels := Level.create_world_levels(source_file, world_data, tilesets_dict, options)

		if options.pack_levels == true:
			var levels_paths := Level.save_levels(levels, save_path, _get_save_extension())

			for file_path in levels_paths:
				gen_files.push_back(file_path)

			world = LdtkWorld.create_world_with_external_levels(world_name, levels_paths)
		else:
			world = LdtkWorld.create_world(world_name, levels)

	if not options.world_post_import_script.is_empty():
		var script = load(options.world_post_import_script)
		if not script or not script is GDScript:
			printerr("Post import script is not a GDScript.")
			return ERR_INVALID_PARAMETER

		script = script.new()
		if not script.has_method("post_import"):
			printerr("World post import script does not have a 'post_import' method.")
			return ERR_INVALID_PARAMETER

		world = script.post_import(world)

		if not world or not world is Node2D:
			printerr("Invalid scene returned from post import script.")
			return ERR_INVALID_DATA

	var packed_world = PackedScene.new()
	packed_world.pack(world)

	return ResourceSaver.save(packed_world, "%s.%s" % [save_path, _get_save_extension()])
