@tool
extends Node

var Minimap = preload("./minimap.gd")
var ignore_data_layers = ""
var ignore_data_values = ""

# This script goes generates a minimap based on the IntLayers on LDtk
func post_import(level: Node2D, level_data: Dictionary, source_file: String) -> Node2D:
	Minimap.create_level_mini_map(level_data, source_file, {
		"ignore_data_layers": ignore_data_layers,
		"ignore_data_values": ignore_data_values
	})
	return level
