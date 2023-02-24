@tool
extends EditorImportPlugin

const Util = preload("util/util.gd")

const LdtkWorld = preload("src/ldtk-world.gd")
const Level = preload("src/ldtk-level.gd")
const Tileset = preload("src/ldtk-tileset.gd")


enum Presets { PRESET_DEFAULT }

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
	return ""

func _get_import_options(path: String, preset_index: int) -> Array:
	return [
		{
			"name": "world_add_metadata",
			"default_value": false,
			"hint_string": "If true, will add the original LDtk data as metadata."
		},
		{
			"name": "world_post_import_script",
			"default_value": "",
			"property_hint": PROPERTY_HINT_FILE,
			"hint_string": "*.gd;GDScript"
		},
		{"name": "Tilesets", "default_value": "", "usage": PROPERTY_USAGE_GROUP},
		{
			"name": "tileset_add_metadata",
			"default_value": true,
			"hint_string": "If true, will add the original LDtk data as metadata."
		},
		{"name": "import_tileset_custom_data", "default_value": true},
		{
			"name": "tileset_post_import_script",
			"default_value": "",
			"property_hint": PROPERTY_HINT_FILE,
			"hint_string": "*.gd;GDScript"
		},
		{"name": "Levels", "default_value": "", "usage": PROPERTY_USAGE_GROUP},
		{
			"name": "level_add_metadata",
			"default_value": true,
			"hint_string": "If true, will add the original LDtk data as metadata."
		},
		{"name": "import_all_levels", "default_value": true},
		{
			"name": "levels_to_import",
			"default_value": "0,1",
			"hint_string": "usage: 1,3,6 where the numbers represent the level index"
		},
		{"name": "pack_levels", "default_value": false},
		{
			"name": "level_post_import_script",
			"default_value": "",
			"property_hint": PROPERTY_HINT_FILE,
			"hint_string": "*.gd;GDScript"
		},
		{"name": "Entities", "default_value": "", "usage": PROPERTY_USAGE_GROUP},
		{
			"name": "import_entities",
			"default_value": true,
			"hint_string":
			"If true, will only use this project's scenes. If false, will import objects as simple scenes."
		},
		{
			"name": "entity_add_metadata",
			"default_value": true,
			"hint_string": "If true, will add the original LDtk data as metadata."
		},
		{
			"name": "entity_post_import_script",
			"default_value": "",
			"property_hint": PROPERTY_HINT_FILE,
			"hint_string": "*.gd;GDScript"
		},
	]

func _get_option_visibility(path: String, option_name: StringName, options: Dictionary) -> bool:
	match option_name:
		"levels_to_import":
			return not options.import_all_levels
		"entity_add_metadata", "entity_post_import_script":
			return options.import_entities
	return true


func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array, gen_files: Array) -> Error:
	var world_data := Util.parse_ldtk_file(source_file)
	var has_external_levels: bool = world_data.externalLevels
	var tilesets_dict := Tileset.get_tilesets_dict(
		source_file, world_data, options
	)

	var world
	var tilesets_paths := Tileset.create_tileset_resources(source_file, tilesets_dict)

	for file_path in tilesets_paths:
		gen_files.push_back(file_path)

	if has_external_levels:
		printerr("External levels are not supported")
		return ERR_INVALID_DATA

	var levels := Level.create_world_levels(source_file, world_data, tilesets_dict, options)

	if options.pack_levels == true:
		var levels_paths := Level.save_levels(levels, save_path, _get_save_extension())

		for file_path in levels_paths:
			gen_files.push_back(file_path)

		world = LdtkWorld.create_world_with_external_levels(world_data, levels_paths, source_file, options)
	else:
		world = LdtkWorld.create_world(world_data, levels, source_file, options)

	var packed_world = PackedScene.new()
	packed_world.pack(world)

	return ResourceSaver.save(packed_world, "%s.%s" % [save_path, _get_save_extension()])
