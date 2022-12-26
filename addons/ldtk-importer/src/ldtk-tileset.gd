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
	var tile_size := Vector2i(tileset_data.tileGridSize, tileset_data.tileGridSize)
	tileset.tile_size = tile_size
	tileset_source.texture_region_size = tile_size
	tileset.add_source(tileset_source)
	
	for y in range(0, grid_height):
		for x in range(0, grid_with):
			var grid_coords := Vector2i(x,y)
			var tile_region := Tile.get_tile_region(grid_coords, tileset_data)
			var tile_image := texture_image.get_region(tile_region)

			if not tile_image.is_invisible():
				tileset_source.create_tile(grid_coords)
					

	var tiles_data := get_tiles_data(tileset_data)
	
	if tiles_data.keys().size() > 0:
		var custom_data_layer_index := 0
		tileset.add_custom_data_layer()
		tileset.set_custom_data_layer_name(custom_data_layer_index, "LDtk")
		tileset.set_custom_data_layer_type(custom_data_layer_index, TYPE_DICTIONARY)
	
		for tile_id in tiles_data:
			var data :Dictionary= tiles_data[tile_id]
			var alternative_tile := 0
			var grid_coords := Tile.tile_id_to_grid_coords(tile_id, grid_with)
			var tile_data :TileData = tileset_source.get_tile_data(grid_coords, alternative_tile)
			tile_data.set_custom_data_by_layer_id(custom_data_layer_index, data)
		
	
	if not options.tileset_post_import_script.is_empty():
		var script = load(options.tileset_post_import_script)
		if not script or not script is GDScript:
			printerr("Tileset post import script is not a GDScript.")
			return tileset

		script = script.new()
		if not script.has_method("post_import"):
			printerr("Tileset post import script does not have a 'post_import' method.")
			return tileset

		tileset = script.post_import(tileset)
	
	return tileset

static func get_tiles_data(tileset_data: Dictionary) -> Dictionary:
	var dict = {}
	for tag in tileset_data.enumTags:
		var value = tag.enumValueId
		var tiles_ids :Array= tag.tileIds
		
		for tile_id in tiles_ids:
			dict[int(tile_id)] = {
				"enum": value
			}
		
	for tile_data in tileset_data.customData:
		var tile_id :int= tile_data.tileId
		var data :Dictionary= JSON.parse_string(tile_data.data)
		var prev_data :Dictionary = dict.get(tile_id, {})
		dict[tile_id] = data.merge(prev_data)
	
	return dict

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

