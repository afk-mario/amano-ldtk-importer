@tool

const Tile = preload("../util/tile.gd")
const Util = preload("../util/util.gd")


static func get_tileset_save_path(source_file: String, is_external_level := false) -> String:
	var save_path = Util.get_save_folder_path(source_file, is_external_level) + "/tilesets"
	return save_path


static func get_tilesets_dict(tilesets_data: Array, base_dir: String, options: Dictionary) -> Dictionary:
	var dict := {}

	for data in tilesets_data:
		var tileset = create_tileset(base_dir, data, options)
		if tileset:
			dict[int(data.uid)] = tileset

	return dict


static func create_tileset_resources(source_file: String, tilesets_dict: Dictionary) -> Array:
	var save_path = get_tileset_save_path(source_file)
	var gen_files = []
	var directory := DirAccess.open(source_file.get_base_dir())
	directory.make_dir_recursive(save_path)

	for key in tilesets_dict.keys():
		var tileset: Resource = tilesets_dict.get(key)
		var path = "%s/%s.%s" % [save_path, key, "res"]

		var err = ResourceSaver.save(tileset, path)
		if err == OK:
			gen_files.push_back(path)

	return gen_files


static func create_tileset(base_dir: String, tileset_data: Dictionary, options: Dictionary) -> TileSet:
	if tileset_data.relPath == null:
		return null

	var import_collisions :bool = options.Import_Collisions
	var tileset := TileSet.new()
	tileset.resource_name = tileset_data.identifier
	
	var texture_filepath :String = base_dir + "/" + tileset_data.relPath
	var texture := load(texture_filepath)
	var texture_image :Image = texture.get_image()
	
	var collision_tiles_ids := get_tiles_ids_by_tag(tileset_data, "Collision")
	var tileset_source := TileSetAtlasSource.new()
	tileset_source.texture = texture

	var grid_with :int = (
		(tileset_data.pxWid - tileset_data.padding)
		/ (tileset_data.tileGridSize + tileset_data.spacing)
	)
	var grid_height :int = (
		(tileset_data.pxHei - tileset_data.padding)
		/ (tileset_data.tileGridSize + tileset_data.spacing)
	)

	var gridSize := grid_with * grid_height
	var shape_id := 0
	var tile_size := Vector2i(tileset_data.tileGridSize, tileset_data.tileGridSize)
	var tile_extents := Vector2(tile_size.x/2, tile_size.y/2)
	tileset.tile_size = tile_size
	tileset_source.texture_region_size = tile_size
	var layer_id := 0
	var tileset_source_id := tileset.add_source(tileset_source)
	
	# TODO: Instead of triying to guess the best way create collisions for the user
	# import all the custom data from LDtk including the enum tags and let a 
	# plugin modify the results as they want, for example creating a square
	# collision shape per tile with a certain tag like here.
	if import_collisions:
		tileset.add_physics_layer()
		tileset.set_physics_layer_collision_layer(layer_id, options.Collision_Layer)
		tileset.set_physics_layer_collision_mask(layer_id, 0)

	for y in range(0, grid_height):
		for x in range(0, grid_with):
			var grid_coords := Vector2i(x,y)
			var tile_region := Tile.get_tile_region(grid_coords, tileset_data)
			var tile_image := texture_image.get_region(tile_region)

			if not tile_image.is_invisible():
				tileset_source.create_tile(grid_coords)

				if import_collisions:
					var tile_id := Tile.tile_grid_coords_to_tile_id(grid_coords, grid_with)
					var has_collision = collision_tiles_ids.has(tile_id)

					if has_collision:
						var alternative_tile := 0
						var tile_data :TileData = tileset_source.get_tile_data(grid_coords, alternative_tile)
						tile_data.add_collision_polygon(layer_id)
						tile_data.set_collision_polygon_points(
							layer_id, 
							0, 
							PackedVector2Array(
								[
									Vector2(-tile_extents.x, -tile_extents.y), 
									Vector2(-tile_extents.x, tile_extents.y), 
									Vector2(tile_extents.x, tile_extents.y),  
									Vector2(tile_extents.x, -tile_extents.y)
								]
							)
						)

					shape_id += 1

	return tileset


static func get_tiles_ids_by_tag(data: Dictionary, tag_id: String) -> Array:
	var tags: Array = data.enumTags
	if tags.size() == 0:
		return []

	var solidEnum = null

	for tag in tags:
		if tag.enumValueId == tag_id:
			solidEnum = tag

	if solidEnum:
		return solidEnum.tileIds.map(func(id): return int(id))

	return []

