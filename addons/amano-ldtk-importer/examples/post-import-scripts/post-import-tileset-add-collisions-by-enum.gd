@tool
extends Node

const Tile = preload("res://addons/amano-ldtk-importer/util/tile.gd")

const CUSTOM_DATA_LAYER_NAME := 'LDtk_tile_data'

var collision_layer := 1

# This script adds a square collision polygon the size of the tile
# to all the tiles that have the "Collision" enum
func post_import(tileset: TileSet) -> TileSet:
	var physics_layer_id := 0
	var source_count := tileset.get_source_count()
	for index in range(0, source_count):
		var source_index := int(index)
		var tileset_source_id := tileset.get_source_id(source_index)
		var tileset_source := tileset.get_source(tileset_source_id)
		var tileset_data_layer_id := tileset.get_custom_data_layer_by_name(CUSTOM_DATA_LAYER_NAME)

		# There is no TilesetDataLayer with name "LDtk"
		if tileset_data_layer_id == -1:
			return tileset

		tileset.add_physics_layer()
		tileset.set_physics_layer_collision_layer(physics_layer_id, collision_layer)
		tileset.set_physics_layer_collision_mask(physics_layer_id, 0)
		var tile_size := tileset.tile_size
		var tile_extents := Vector2(tile_size.x/2, tile_size.y/2)
		var grid_size :Vector2i = tileset_source.get_atlas_grid_size()

		for y in range(0, grid_size.y):
			for x in range(0, grid_size.x):
				var alternative_tile := 0
				var grid_coords := Vector2i(x,y)

				var has_tile :bool = tileset_source.get_tile_at_coords(grid_coords) != Vector2i(-1,-1)
				if has_tile:
					var tile_id := Tile.tile_grid_coords_to_tile_id(grid_coords, grid_size.x)
					var tile_data :TileData = tileset_source.get_tile_data(grid_coords, alternative_tile)
					var tile_custom_data :Dictionary= tile_data.get_custom_data(CUSTOM_DATA_LAYER_NAME)
					if tile_custom_data != null and tile_custom_data != {}:
						var enums :Array = tile_custom_data.get("enums")
						if enums.has("Walls"):
							tile_data.add_collision_polygon(physics_layer_id)
							tile_data.set_collision_polygon_points(
								physics_layer_id,
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

	return tileset
