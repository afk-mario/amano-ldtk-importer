@tool
extends Node2D

class_name EntityRefTest

@export
var target_path :NodePath

@onready
var target = get_node(target_path)

func _draw() -> void:
	if Engine.is_editor_hint():
		if target_path:
			var _target = get_node(target_path)
			draw_line(
				Vector2(0, 0),
				_target.global_position - position,
				Color.MAGENTA, 1
			)
