# Amano LDtk Importer

LDtk importer for Godot 4


**Note: This plugin is incomplete, it's public in hopes that it will be helpful for someone migrating their project to Godot 4**

---


## Features

- [x] Import LDtk Tilesets as Godot Tilesets
	- [x] Generate Godot TileSetAtlasSources from LDtk Tilesets
	- [x] Import custom data from LDtk in to Tilesets custom data layers
- [x] Import LDtk levels in to Godot
	- [x] Generate Godot Tilemaps from LDtk layers of the following types:
		- Tiles
		- IntGrid
		- AutoLayer
	- [x] Support Godot tilemap layers
	- [x] Support LDtk layers of different grid sizes
	- [ ] Add z-index to Godot layers based on LDtk layer order
- [x] Post import hand modifications using scripts for:
	- Tilesets
	- Levels
	- World
- [x] Import level background images
- [x] Import int layers without tile atlases
- [x] Support level positioning on "GridVania", "Free", "LinearHorizontal" and "LinearVertical" layouts
- [x] Import LDtk Entities
- [ ] Import CSV from simple LDtk export

## Limitations

- [Godot4 doesn't support flipped tiles](https://github.com/godotengine/godot-proposals/issues/3967)
- [Can't support LDtk external with the current LDtk implementation](https://github.com/deepnight/ldtk/issues/734)
- LDtk support for multiple tiles in a single layer using auto tile rules, this plugin will not support that.

## Post Import Scripts

You can modify the resulting scene by hooking up to the post import scripts in the import options, an example of the structure of the scripts is as follows:

### Post Import tileset

```gdscript
@tool
extends Node

func post_import(tileset: TileSet) -> TileSet:
	var grid_size :Vector2i = tileset_source.get_atlas_grid_size()

	for y in range(0, grid_size.y):
		for x in range(0, grid_size.x):
			# modify the tile at position [x,y]
			...

	return tileset

```

### Post Import Level

```gdscript
@tool
extends Node

func post_import(level: Node2D, _level_data: Dictionary, _source_file: String) -> Node2D:
	# modify level
	...
	return level

```

### Post import World

```gdscript
@tool
extends Node

func post_import(world: Node2D) -> Node2D:
	# modify world
	...
	return world
```


for more examples check the [examples](https://github.com/afk-mario/amano-ldtk-importer/tree/main/addons/amano-ldtk-importer/examples/post-import-scripts) directory.


## Collisions

LDtk doesn't have a UI to create collision polygons on each tile like Tiled or the Godot tile map UI. It does support custom data on the tiles, so you can use that to generate the physics layers and collision polygons using a post script. There is a [basic example](https://github.com/afk-mario/amano-ldtk-importer/blob/main/addons/amano-ldtk-importer/examples/post-import-scripts/post-import-tileset-add-collisions.gd) in the example folders.

## Notes

Started as a fork from https://github.com/levigilbert/godot-LDtk-import

Used internally by https://amano.games/
