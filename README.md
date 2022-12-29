# Amano LDtk Importer

LDtk importer for Godot 4

---

![](https://img.shields.io/badge/Godot%20Compatible-4.0%2B-%234385B5)

> ⚠ **Disclaimer: Godot 4 is not released yet. As a result the plugin may be unstable to use, and the API may change.**

# Installation

1. [Download]()
2. Unpack the `amano-ldtkk-importer` folder into your `/addons` folder within the Godot project
3. Enable this addon within the Godot settings: `Project > Project Settings > Plugins`

# Features

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

# Limitations

- [Godot4 doesn't support flipped tiles](https://github.com/godotengine/godot-proposals/issues/3967)
- [Can't support LDtk external level files with the current LDtk implementation](https://github.com/deepnight/ldtk/issues/734)
- LDtk support for multiple tiles in a single layer using auto tile rules, this plugin will not support that.

# Metadata

Metada information will be set on the World root node, the level root node, the tileset resource and the entities root node, from the import options you can choose to skip all the raw metadata and source file entries. This information can be used in the post-script scripts or at runtime.

## World Metadata

In the world root node two metadata keys are added:

- `LDtk_raw_data` The full LDTK parsed JSON as a dictionary
- `LDtk_source_file` the imported LDtk file path

## Tilesets Metadata

In the tileset resources there are two keys added:

- `LDtk_raw_data` The tileset definition parsed JSON as a dictionary, the importer will generate a new tileset and tileset source for IntGrid layers, this don't have the metadata key.
- `LDtk_source_file` the imported LDtk file path

## Tile Metadata

Every tileset will have a custom data layer named `LDtk_tile_data` with the following structure:
```gdscript
{
	enums: [], # Array of all enums as strings each tile has,
	... # All the other fields each tile has in the LDtk custom data 
}
```

Also the importer will create a `TilesetSource` per IntGrid Layer and append a custom data layer to the `Tileset` with the name of the IntGrid layer from LDtk 

## Level Metadata

In the root level node there are three keys added:
- `LDtk_level_fields` The level `fieldInstances` parsed and converted to Godot Types.
- `LDtk_raw_data` The level instance LDtk parsed JSON as a dictionary
- `LDtk_raw_reds` The world refs parsed JSON as a dictionary
- `LDtk_source_file` the imported LDtk file path

## Entity Metadata

In Node created for each entity layer there are two keys added.
- `LDtk_entity_instances` the parsed entity data for each layer in the following format:
	```gdscript
	{
		"iid": ...,
		"def_uid": ...,
		"identifier": ...,
		"smart_color": ...,
		"width": ...,
		"height": ...,
		"grid": ...,
		"px": ...,
		"pivot": ...,
		"tags": ...,
		"fields": ..., # The fieldInstances from LDtk parsed and converted to Godot Types.
	}
	```
- `LDtk_raw_data` The raw `entityInstances` parsed JSON data as a dictionary
- `LDtk_source_file` the imported LDtk file path


# Post Import Scripts

You can modify the resulting scene by hooking up to the post import scripts in the import options, an example of the structure of the scripts is as follows:

## Post Import tileset

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

## Post Import Level

```gdscript
@tool
extends Node

func post_import(level: Node2D) -> Node2D:
	# modify level
	...
	return level

```

## Post import World

```gdscript
@tool
extends Node

func post_import(world: Node2D) -> Node2D:
	# modify world
	...
	return world
```


for more examples check the [examples](https://github.com/afk-mario/amano-ldtk-importer/tree/main/addons/amano-ldtk-importer/examples/post-import-scripts) directory.


# Collisions

LDtk doesn't have a UI to create collision polygons on each tile like Tiled or the Godot tile map UI. It does support custom data on the tiles, so you can use that metadata to generate the physics layers and collision polygons using a post script. There is a [basic example](https://github.com/afk-mario/amano-ldtk-importer/blob/main/addons/amano-ldtk-importer/examples/post-import-scripts/post-import-tileset-add-collisions.gd) using enums or using [IntGrid]() layers in the example folders.

# Notes

Started as a fork from https://github.com/levigilbert/godot-LDtk-import

Used internally by https://amano.games/
