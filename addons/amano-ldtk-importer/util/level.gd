@tool

static func get_world_position(world_data: Dictionary, level_data: Dictionary) -> Vector2i:
	var level_uids :Array = world_data.levels.map(
		func(item): return item.uid
	)
	match world_data.worldLayout:
		"GridVania", "Free":
			return Vector2i(level_data.worldX, level_data.worldY)
		"LinearHorizontal":
			var level_index = level_uids.find(level_data.uid)
			if level_index == 0:
				return Vector2i(0, 0)

			var x :int = world_data.levels.slice(0, level_index).reduce(
				func(acc, curr):
					return acc + curr.pxWid
			, 0)
			return Vector2i(x, 0)
		"LinearVertical":
			var level_index = level_uids.find(level_data.uid)
			if level_index == 0:
				return Vector2i(0, 0)

			var y :int = world_data.levels.slice(0, level_index).reduce(
				func(acc, curr):
					return acc + curr.pxHei
			, 0)
			return Vector2i(0, y)
		_:
			push_warning("World layout not supported: ", world_data.worldLayout)
			return Vector2i.ZERO
