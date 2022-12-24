@tool

const Tile = preload("../util/tile.gd")
const Util = preload("../util/util.gd")


static func get_tileset_save_path(source_file: String, is_external_level := false) -> String:
	var save_path = Util.get_save_folder_path(source_file, is_external_level) + "/tilesets"
	return save_path


static func get_tilesets_dict(tilesets_data: Array, base_dir: String, options: Dictionary) -> Dictionary:
	var dict := {}

	for data in tilesets_data:
		var tileset = create_tileset(base_dir, data, options.Import_Collisions)
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


static func create_tileset(base_dir: String, tileset_data: Dictionary, import_collisions: bool) -> TileSet:
	if tileset_data.relPath == null:
		return null

	var tileset := TileSet.new()
	tileset.resource_name = tileset_data.identifier
	
	var texture_filepath :String = base_dir + "/" + tileset_data.relPath
	var texture := load(texture_filepath)
	var texture_image :Image = texture.get_image()
	
	var collision_tiles_ids := get_tiles_ids_by_tag(tileset_data, "Collision")

	var tileset_source := TileSetAtlasSource.new()
	tileset_source.texture = texture

	var gridWidth :int = (
		(tileset_data.pxWid - tileset_data.padding)
		/ (tileset_data.tileGridSize + tileset_data.spacing)
	)
	var gridHeight :int = (
		(tileset_data.pxHei - tileset_data.padding)
		/ (tileset_data.tileGridSize + tileset_data.spacing)
	)

	var gridSize := gridWidth * gridHeight
	var shape_id := 0
	var tile_size := Vector2i(tileset_data.tileGridSize, tileset_data.tileGridSize)
	tileset.tile_size = tile_size
	tileset_source.texture_region_size = tile_size

	var base_collision_shape := RectangleShape2D.new()
	base_collision_shape.set_size(tile_size)

	for y in range(0, gridHeight):
		for x in range(0, gridWidth):
			var atlas_coords := Vector2i(x,y)
			var tile_region := Tile.get_tile_region(atlas_coords, tileset_data)
			var tile_image := texture_image.get_region(tile_region)

			if not tile_image.is_invisible():
				tileset_source.create_tile(atlas_coords)

				var has_collision = collision_tiles_ids.has(atlas_coords)

				var col_shape = null
				var col_offset = tile_size / 2
				var is_one_way = false

				if has_collision:
					col_shape = base_collision_shape
					tileset.tile_set_shape(atlas_coords, shape_id, col_shape)
					tileset.tile_set_shape_offset(atlas_coords, shape_id, col_offset)
					tileset.tile_set_shape_one_way(atlas_coords, shape_id, is_one_way)

				shape_id += 1

	tileset.add_source(tileset_source)
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
		return solidEnum.tileIds

	return []

