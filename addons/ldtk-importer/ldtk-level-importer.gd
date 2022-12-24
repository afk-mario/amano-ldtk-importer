@tool
extends EditorImportPlugin

enum Presets { PRESET_DEFAULT }

func _get_importer_name() -> String:
	return "LDtk_level.import"

func _get_visible_name() -> String:
	return "LDtk Level Scene"

func _get_priority() -> float:
	return 1.0

func _get_import_order() -> int:
	return 200

func _get_resource_type() -> String:
	return "PackedScene"
	
func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["ldtkl"])

func _get_save_extension() -> String:
	return "scn"

func _get_preset_count() -> int:
	return Presets.size()
	
func _get_preset_name(preset_index: int) -> String:
	match preset_index:
		Presets.PRESET_DEFAULT:
			return "Default"
	return ""

func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array, gen_files: Array) -> int:
	return 0
