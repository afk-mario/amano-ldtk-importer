@tool

const Tile = preload("../util/tile.gd")
const Util = preload("../util/util.gd")

# Only create one custom data layer per tileset with the name LDtk
const CUSTOM_DATA_LAYER_INDEX := 0
const CUSTOM_DATA_LAYER_NAME := 'LDtk'

static func get_tileset_save_path(source_file: String) -> String:
	var save_path = Util.get_save_folder_path(source_file) + "/tilesets"
	return save_path


static func get_tilesets_dict(source_file: String, tilesets_data: Array, base_dir: String, options: Dictionary) -> Dictionary:
	var dict :Dictionary = tilesets_data.reduce(
		func(acc: Dictionary, curr: Dictionary):
			var tile_grid_size :int= curr.tileGridSize
			if not acc.has(tile_grid_size):
				acc[tile_grid_size] = create_tileset(
					source_file, tile_grid_size, options
				)
			create_tileset_source(acc[tile_grid_size], base_dir, curr, options)
			return acc
	,{}
	)
	
	if not options.tileset_post_import_script.is_empty():
		var script = load(options.tileset_post_import_script)
		if not script or not script is GDScript:
			printerr("Tileset post import script is not a GDScript.")
			dict

		script = script.new()
		if not script.has_method("post_import"):
			printerr("Tileset post import script does not have a 'post_import' method.")
			return dict

		for key in dict:
			dict[key] = script.post_import(dict[key])
	
	return dict

static func create_tileset(source_file: String, tile_grid_size: int, options: Dictionary) -> TileSet:
	var tileset := TileSet.new()
	var source_file_name = source_file.get_file().get_slice(".", 0)
	tileset.resource_name = source_file_name + "-tileset-" + str(tile_grid_size) + "x" + str(tile_grid_size)
	tileset.tile_size = Vector2i(tile_grid_size, tile_grid_size)
	tileset.add_custom_data_layer()
	tileset.set_custom_data_layer_name(CUSTOM_DATA_LAYER_INDEX, CUSTOM_DATA_LAYER_NAME)
	tileset.set_custom_data_layer_type(CUSTOM_DATA_LAYER_INDEX, TYPE_DICTIONARY)
	
	return tileset


static func create_tileset_source(tileset: TileSet, base_dir: String, tileset_data: Dictionary, options: Dictionary) -> TileSetSource:
	if tileset_data.relPath == null:
		return null

	var texture_filepath :String = base_dir + "/" + tileset_data.relPath
	var texture := load(texture_filepath)
	var texture_image :Image = texture.get_image()
	
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
	tileset.add_source(tileset_source, tileset_data.uid)
	
	for y in range(0, grid_height):
		for x in range(0, grid_with):
			var grid_coords := Vector2i(x,y)
			var tile_region := Tile.get_tile_region(grid_coords, tileset_data)
			var tile_image := texture_image.get_region(tile_region)

			if not tile_image.is_invisible():
				tileset_source.create_tile(grid_coords)
					

	var tiles_data := get_tiles_data(tileset_data)
	
	if tiles_data.keys().size() > 0:
		for tile_id in tiles_data:
			var data :Dictionary= tiles_data[tile_id]
			var alternative_tile := 0
			var grid_coords := Tile.tile_id_to_grid_coords(tile_id, grid_with)
			var tile_data :TileData = tileset_source.get_tile_data(grid_coords, alternative_tile)
			tile_data.set_custom_data_by_layer_id(CUSTOM_DATA_LAYER_INDEX, data)
	
	return tileset_source

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

static func create_tileset_resources(source_file: String, tilesets_dict: Dictionary) -> Array:
	var save_path = get_tileset_save_path(source_file)
	var gen_files = []
	var directory := DirAccess.open(source_file.get_base_dir())
	directory.make_dir_recursive(save_path)

	for key in tilesets_dict.keys():
		var tileset: Resource = tilesets_dict.get(key)
		var path = "%s/%s.%s" % [save_path, tileset.resource_name, "res"]

		var err = ResourceSaver.save(tileset, path)
		if err == OK:
			gen_files.push_back(path)

	return gen_files
