@tool
extends Node

var entity_ref_test := preload("res://scenes/entity-ref-test.tscn")

func post_import(entity_layer: Node2D) -> Node2D:
	var data :Array = entity_layer.get_meta("LDtk_entity_instances")
	var entities_defs :Array = entity_layer.get_meta("LDtk_raw_defs").entities
	var entities_defs_uid := entities_defs.map(func(item): return int(item.uid))
	var label_settings := LabelSettings.new()
	label_settings.font_size = 8
	label_settings.line_spacing = 0

	for entity_data in data:
		var entity_def_index :int = entities_defs_uid.find(int(entity_data.def_uid))
		var entity_def :Dictionary = entities_defs[entity_def_index]
		var node
		var entity_size := Vector2(entity_data.width, entity_data.height)
		var entity_extents := entity_size * 0.5

		match entity_def.renderMode:
			"Ellipse":
				node = Area2D.new()
				var collision_shape := CollisionShape2D.new()
				collision_shape.shape = CircleShape2D.new()
				collision_shape.shape.radius = entity_data.width / 2
				node.add_child(collision_shape)
				collision_shape.debug_color = entity_data.smart_color
			"Rectangle":
				node = Polygon2D.new()
				node.polygon = PackedVector2Array([
					Vector2(-entity_extents.x, -entity_extents.y),
					Vector2(entity_extents.x, -entity_extents.y),
					Vector2(entity_extents.x, entity_extents.y),
					Vector2(-entity_extents.x, entity_extents.y),
				])
				node.color = entity_data.smart_color
				if entity_def.hollow:
					node.invert_enabled = true
					node.invert_border = 2
			"Cross":
				node = Marker2D.new()
			_:
				if entity_data.identifier == "EntityRefTest":
					node = entity_ref_test.instantiate()
				else:
					node = Node2D.new()

		if entity_def.identifier == "Labels":
			var label := Label.new()
			label.label_settings = label_settings
			label.text = entity_data.fields.text
			label.position = -entity_extents
			label.autowrap_mode = TextServer.AUTOWRAP_WORD
			label.custom_minimum_size = entity_size
			node.add_child(label)

		var pivot = entity_data.pivot
		node.name = entity_data.identifier
		node.position = entity_data.px
		node.position += entity_extents
		node.position -= entity_size * pivot
		node.set_meta("entity_data", entity_data)
		entity_layer.add_child(node)

	var children := entity_layer.get_children()

	# This would only work for entities that have a reference
	# on entities in the same level/layer, for referencing entities on
	# different levels/layers a world-post-script would need to be used.
	for child in children:
		var entity_meta :Dictionary = child.get_meta("entity_data")
		if entity_meta.identifier == "EntityRefTest":
			var entity_ref_node :EntityRefTest = child
			var target_field = entity_meta.fields.get("target", null)
			if target_field != null:
				var target_node = children.filter(
					func(item):
						var item_meta = item.get_meta("entity_data")
						return item_meta.iid == target_field.entityIid
				)[0]
				var path := entity_ref_node.get_path_to(target_node)
				entity_ref_node.target_path = path

	return entity_layer
