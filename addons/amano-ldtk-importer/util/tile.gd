@tool

static func tile_grid_coords_to_px_coords(
	grid_coords: Vector2i, atlas_grid_size: int, padding: int, spacing: int
) -> Vector2i:
	var pixel_tile_x = padding + grid_coords.x * (atlas_grid_size + spacing)
	var pixel_tile_y = padding + grid_coords.y * (atlas_grid_size + spacing)

	return Vector2i(pixel_tile_x, pixel_tile_y)

static func tile_grid_coords_to_tile_id(grid_coords: Vector2i, atlas_grid_width: int) -> int:
	return  grid_coords.x + grid_coords.y * atlas_grid_width;

static func cell_px_coords_to_grid_coords(px_coords: Vector2i, grid_size: Vector2i, offset: Vector2i) -> Vector2i:
	var x :int= floor(px_coords.x/grid_size.x)
	var y :int= floor(px_coords.y/grid_size.y)
	return Vector2i(x, y)

#converts tileId to pixel coordinates.
static func tile_id_to_px_coords(
	tile_id: int, atlas_grid_size: int, atlas_grid_width: int, padding: int, spacing: int
) -> Vector2i:
	var grid_coords := tile_id_to_grid_coords(tile_id, atlas_grid_width)
	return tile_grid_coords_to_px_coords(grid_coords, atlas_grid_size, padding, spacing)


#converts tileId to grid coordinagtes.
static func tile_id_to_grid_coords(tile_id: int, atlas_grid_width: int) -> Vector2i:
	var grid_tile_x := tile_id - atlas_grid_width * int(tile_id / atlas_grid_width)
	var grid_tile_y := int(tile_id / atlas_grid_width)

	return Vector2i(grid_tile_x, grid_tile_y)


#get tile region(Rect2) by tileId.
static func get_tile_region(tile_id: Vector2i, tileset_data: Dictionary) -> Rect2:
	var padding = tileset_data.padding
	var spacing = tileset_data.spacing
	var atlas_grid_size = tileset_data.tileGridSize
	var atlas_grid_width = tileset_data.pxWid / atlas_grid_size
	var pixel_tile := tile_grid_coords_to_px_coords(
		tile_id, atlas_grid_size, padding, spacing
	)

	var rect = Rect2(pixel_tile, Vector2(atlas_grid_size, atlas_grid_size))

	return rect

static func get_cell_coords_from_index(index: int, columns: int) -> Vector2i:
	var x = floor(index % columns)
	var y = floor(index / columns)
	return Vector2i(x, y)
