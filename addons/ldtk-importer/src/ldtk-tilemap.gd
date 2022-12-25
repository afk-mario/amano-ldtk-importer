@tool

const Tile = preload("../util/tile.gd")
const Tileset = preload("ldtk-tileset.gd")


# Create TileMap from tilemap_data.
static func create_tilemap(
	source_file: String,
	tilemap_data: Dictionary,
	tilesets_dict: Dictionary,
	options: Dictionary,
	is_external_level := false
) -> TileMap:
	var import_collisions :bool = options.Import_Collisions
	var tilemap := TileMap.new()

	if not tilemap_data.__tilesetDefUid:
		return null
		
	var tileset_uid = int(tilemap_data.__tilesetDefUid)
	var tile_set
	var tileset_path := (
		Tileset.get_tileset_save_path(source_file, is_external_level)
		+ "/"
		+ str(tileset_uid)
		+ ".tres"
	)
	if is_external_level:
#		tile_set = load(tileset_path)
		tile_set = tilesets_dict[tileset_uid]
	else:
		tile_set = tilesets_dict[tileset_uid]

	tilemap.tile_set = tile_set
	tilemap.name = tilemap_data.__identifier
	tilemap.position = Vector2(0, 0)
	tilemap.cell_quadrant_size = tilemap_data.__gridSize
	tilemap.set_layer_modulate(0, Color(1, 1, 1, tilemap_data.__opacity))
	tilemap.visible = tilemap_data.visible
#	tilemap.collision_layer = options.Collision_Layer
#	tilemap.collision_mask = 0

	var tiles: Array = tilemap_data.autoLayerTiles
	var coordinate_index := 1
	var grid_size := Vector2i( tilemap_data.__gridSize,  tilemap_data.__gridSize)
	var grid_offset := Vector2i(tilemap_data.__pxTotalOffsetX, tilemap_data.__pxTotalOffsetY)
	# TODO: Get this somehow that it's not hardcoded
	var layer = 0
	var tileset_source_id := 0
	var tileset_source := tilemap.tile_set.get_source(tileset_source_id)
#
	if tilemap_data.__type == "Tiles":
		tiles = tilemap_data.gridTiles
		coordinate_index = 0

	for tile in tiles:
		var flip := int(tile["f"])
		var flip_x := bool(flip & 1)
		var flip_y := bool(flip & 2)
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
		tilemap.set_cell(layer, cell_grid_coords, tileset_source_id, tile_grid_coords)

	return tilemap
