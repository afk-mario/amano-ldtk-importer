@tool
const CHILDREN_META = "children"

const Tileset = preload("ldtk-tileset.gd")

const Tile = preload("../util/tile.gd")
const Field = preload("../util/field.gd")
const PostImport = preload("../util/post-import.gd")

static func get_level_layer_instances(
	source_file: String,
	world_data: Dictionary,
	level_data: Dictionary,
	layers_dict: Dictionary,
	tilesets_dict: Dictionary,
	options: Dictionary
) -> Array:
	var layers := []

	for key in layers_dict:
		var layer_instances :Dictionary = layers_dict[key]
		var tilemap := TileMap.new()
		tilemap.name = level_data.identifier + "-tilemap-" + str(key) + "x" + str(key)
		tilemap.cell_quadrant_size = key
		var tile_set = tilesets_dict.get(key, null)
		tilemap.tile_set = tile_set

		var tile_layer_index := 0

		for index in range(layer_instances.size()-1, -1, -1):
			var layer_data = layer_instances[layer_instances.keys()[index]]
			var match_data :Dictionary = {
				"type": layer_data.__type,
				"tileset": layer_data.get("__tilesetDefUid", null) != null
			}
			match match_data:
				{"type": "Entities", ..}:
					if options.import_entities:
						var layer = create_entity_layer(source_file, world_data, layer_data, options)
						layers.push_front(layer)
				{"type": "IntGrid", "tileset": false}:
					var layer_created := create_int_layer(
						tilemap, tile_layer_index, layer_data, world_data, options
					)
					if layer_created:
						tile_layer_index += 1
				{"type": "IntGrid", "tileset": true}:
					var layer_created := create_int_layer(
						tilemap, tile_layer_index, layer_data, world_data, options
					)
					if layer_created:
						tile_layer_index += 1

					layer_created = create_tile_layer(
						tilemap, tile_layer_index, layer_data, options
					)
					if layer_created:
						tile_layer_index += 1

				{"type": "Tiles", "tileset": true}, \
				{"type": "AutoLayer", "tileset": true}:
					var layer_created := create_tile_layer(
						tilemap, tile_layer_index, layer_data, options
					)
					if layer_created:
						tile_layer_index += 1
				_:
					push_warning("LDtk: Tried importing an unsupported layer type", match_data)
		layers.push_front(tilemap)

	return layers

static func create_int_layer(
	tilemap: TileMap,
	tile_layer_index: int,
	layer_data: Dictionary,
	world_data: Dictionary,
	options: Dictionary
) -> bool:
	if tile_layer_index > 0:
		tilemap.add_layer(-1)

	# Find the layer definition of the layer to get all the values
	var layer_def :Dictionary = world_data.defs.layers.filter(
		func(item): return item.uid == layer_data.layerDefUid
	)[0]
	var int_grid_values = layer_def.intGridValues.map(
		func(item): return item.value
	)
	var layer_index := tilemap.get_layers_count() - 1
	tilemap.set_layer_name(layer_index, str(layer_data.__identifier) + "-int-values")
	tilemap.set_layer_modulate(layer_index, Color(1, 1, 1, layer_data.__opacity))
	tilemap.set_layer_enabled(layer_index, layer_data.visible)
	var tiles: Array = layer_data.intGridCsv
	var grid_size := Vector2i(layer_data.__gridSize, layer_data.__gridSize)
	var tileset_source_id :int = layer_data.layerDefUid
	var tileset_source := tilemap.tile_set.get_source(tileset_source_id)
	var columns :int= layer_data.__cWid

	for index in range(0, tiles.size()):
		var value = tiles[index]
		var value_index :int = int_grid_values.find(value)
		if value_index != -1:
			var cell_grid_coords := Tile.get_cell_coords_from_index(index, columns)
			var tile_grid_coords := Vector2i(value_index, 0)
			tilemap.set_cell(layer_index, cell_grid_coords, tileset_source_id, tile_grid_coords)

	return false

static func create_tile_layer(
	tilemap: TileMap,
	tile_layer_index: int,
	layer_data: Dictionary,
	options: Dictionary
) -> bool:
	if not layer_data.__tilesetDefUid:
		return false

	if tile_layer_index > 0:
		tilemap.add_layer(-1)

	var layer_index := tilemap.get_layers_count() - 1
	tilemap.set_layer_name(layer_index, layer_data.__identifier)
	tilemap.set_layer_modulate(layer_index, Color(1, 1, 1, layer_data.__opacity))
	tilemap.set_layer_enabled(layer_index, layer_data.visible)

	var tiles: Array = layer_data.autoLayerTiles
	var grid_size := Vector2i(layer_data.__gridSize, layer_data.__gridSize)
	var grid_offset := Vector2i(layer_data.__pxTotalOffsetX, layer_data.__pxTotalOffsetY)

	var tileset_source_id :int = layer_data.__tilesetDefUid
	var tileset_source := tilemap.tile_set.get_source(tileset_source_id)

	if layer_data.__type == "Tiles":
		tiles = layer_data.gridTiles

	for tile in tiles:
		var cell_pixel_coords := Vector2i(tile.px[0], tile.px[1])
		var tile_pixel_coords := Vector2i(tile.src[0], tile.src[1])
		var cell_grid_coords := Tile.cell_px_coords_to_grid_coords(
			cell_pixel_coords,
			grid_size,
			grid_offset
		)
		var tile_grid_coords := Tile.cell_px_coords_to_grid_coords(
			tile_pixel_coords,
			Vector2i(tileset_source.texture_region_size),
			Vector2i.ZERO
		)
		tilemap.set_cell(layer_index, cell_grid_coords, tileset_source_id, tile_grid_coords)

	return true

static func create_entity_layer(source_file: String, world_data: Dictionary, layer_data: Dictionary, options: Dictionary) -> Node2D:
	var layer = null
	layer = Node2D.new()

	layer.name = layer_data.__identifier
	var entity_instances :Array = layer_data.entityInstances

	var entities_data :Array = entity_instances.map(
		func(entity):
			var data :Dictionary = {
				"iid": entity.iid,
				"def_uid": entity.defUid,
				"identifier": entity.__identifier,
				"smart_color": Color.from_string(entity.__smartColor, Color.WHITE),
				"width": entity.width,
				"height": entity.height,
				"grid": Vector2i(entity.__grid[0], entity.__grid[1]),
				"px": Vector2i(entity.px[0], entity.px[1]),
				"pivot": Vector2(entity.__pivot[0], entity.__pivot[1]),
				"tags": entity.__tags,
				"fields": Field.get_field_instances_as_dict(entity.fieldInstances)
			}
			return data
	)

	layer.set_meta("LDtk_entity_instances", entities_data)

	if options.entity_add_metadata:
		layer.set_meta("LDtk_raw_data", entity_instances)
		layer.set_meta("LDtk_raw_defs", world_data.defs)
		layer.set_meta("LDtk_source_file", source_file)

	layer = PostImport.run_post_import(
		layer,
		options.entity_post_import_script,
		source_file,
		"Layer"
	)

	return layer
