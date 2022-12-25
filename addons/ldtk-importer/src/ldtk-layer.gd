@tool
const CHILDREN_META = "children"

const Entity = preload("ldtk-entity.gd")
const Tilemap = preload("ldtk-tilemap.gd")


static func get_level_layer_instances(
	source_file: String,
	level_data: Dictionary,
	tilesets_dict: Dictionary,
	options: Dictionary,
	is_external_level := false
) -> Array:
	var layer_instances: Array = level_data.layerInstances
	var layers := []

	for index in range(layer_instances.size()-1, -1, -1):
		var layer_data = layer_instances[index]
		var layer
		match layer_data.__type:
			"Entities":
				layer = create_entity_layer(layer_data, options)
			"Tiles", "IntGrid", "AutoLayer":
				layer = Tilemap.create_tilemap(
					source_file, layer_data, tilesets_dict, options, is_external_level
				)

		if layer:
			layer.z_index = layer_instances.size() - index
			layers.push_front(layer)

	return layers


static func create_entity_layer(data: Dictionary, options: Dictionary) -> Node2D:
	var layer = null
	layer = Node2D.new()

	layer.name = data.__identifier

	var entities = Entity.get_layer_entities(data, options)

	for key in entities.keys():
		var entity = entities[key]
		if entity.has_meta(CHILDREN_META):
			for ref in entity.get_meta(CHILDREN_META):
				var child = entities[ref.entityIid]
				child.position -= entity.position
				entity.add_child(child)

	for key in entities.keys():
		var entity = entities[key]
		var oldParent = entity.get_parent()
		if !oldParent:
			layer.add_child(entity)

	return layer
