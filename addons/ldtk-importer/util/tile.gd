@tool

static func tile_grid_coords_to_px_coords(
	grid_coords: Vector2i, atlas_grid_size: int, padding: int, spacing: int
) -> Vector2i:
	var pixel_tile_x = padding + grid_coords.x * (atlas_grid_size + spacing)
	var pixel_tile_y = padding + grid_coords.y * (atlas_grid_size + spacing)

	return Vector2i(pixel_tile_x, pixel_tile_y)

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


#converts coord_id to grid coordinates.
static func coord_id_to_grid_coords(coord_id: int, grid_width: int) -> Vector2:
	var grid_y = floor(coord_id / grid_width)
	var grid_x = coord_id - grid_y * grid_width

	return Vector2(grid_x, grid_y)


#converts tileId to grid coordinates.
static func tile_id_to_grid_coords(tile_id: int, atlas_grid_width: int) -> Vector2:
	var grid_tile_x = tile_id - atlas_grid_width * int(tile_id / atlas_grid_width)
	var grid_tile_y = int(tile_id / atlas_grid_width)

	return Vector2(grid_tile_x, grid_tile_y)


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
