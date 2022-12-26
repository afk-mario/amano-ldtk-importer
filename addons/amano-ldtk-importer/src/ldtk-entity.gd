@tool

const Collision = preload("../util/collisions.gd")


static func get_entity_metadata(data: Dictionary) -> Dictionary:
	var metadata = {}
	for field in data.fieldInstances:
		if field.__identifier != "node_type":
			var identifier = field.__identifier
			metadata[identifier] = field.__value

	return metadata


static func get_layer_entities(layer_data: Dictionary, options: Dictionary) -> Dictionary:
	if layer_data.__type != "Entities":
		return {}

	var entities = {}
	for entity in layer_data.entityInstances:
		var new_entity = create_new_entity(entity, options)
		if new_entity:
			entities[entity.iid] = new_entity

	return entities


static func create_new_entity(entity_data: Dictionary, options: Dictionary) -> Node:
	if entity_data.fieldInstances == null:
		printerr("Could not load entity data: ", entity_data)
		return null

	var new_entity
	var metadata = get_entity_metadata(entity_data)
	var is_custom_entity = false

	for field in entity_data.fieldInstances:
		if field.__identifier == "node_type" and field.__type == "String":
			var node_type = field.__value
			match node_type:
				"Marker2D":
					new_entity = Marker2D.new()
					new_entity.name = node_type
				"Area2D":
					new_entity = Area2D.new()
					new_entity.name = node_type
				"CharacterBody2D":
					new_entity = CharacterBody2D.new()
					new_entity.name = node_type
				"RigidBody2D":
					new_entity = RigidBody2D.new()
					new_entity.name = node_type
				"StaticBody2D":
					new_entity = StaticBody2D.new()
					new_entity.name = node_type
				_:
					if not options.import_custom_entities:
						return null

					new_entity = create_custom_entity(entity_data, node_type, metadata)

	if not new_entity:
		return null

	for key in metadata.keys():
		if key in new_entity:
			new_entity[key] = metadata[key]
		else:
			new_entity.set_meta(key, metadata[key])

	match new_entity.name:
		"Area2D", "KinematicBody2D", "RigidBody2D", "StaticBody2D":
			var col_shape = Collision.create_rectangle_collision_shape(
				Vector2(entity_data.width, entity_data.height)
			)
			new_entity.add_child(col_shape)

	new_entity.name = entity_data.__identifier
	new_entity.position = Vector2(entity_data.px[0], entity_data.px[1])

	return new_entity


static func create_custom_entity(data: Dictionary, path: String, metadata: Dictionary) -> Node:
	var resource = load(path)
	var entity

	if not resource:
		printerr("Could not load resource: ", path)
		return null

	entity = resource.instance()
	var base_size_w = metadata.get("base_size_w", 8)
	var base_size_h = metadata.get("base_size_h", 8)
	var size = Vector2(data.width, data.height)
	size.x = size.x / base_size_w
	size.y = size.y / base_size_h
	entity.scale = size

	return entity
