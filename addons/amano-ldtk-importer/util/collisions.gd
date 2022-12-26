@tool

static func create_rectangle_collision_shape(size: Vector2) -> CollisionShape2D:
	var col_shape = CollisionShape2D.new()
	col_shape.shape = RectangleShape2D.new()
	col_shape.shape.extents = size / 2
	col_shape.position = size / 2

	return col_shape


static func create_collision_shape(
	tile_size: Vector2, start_position: Vector2, end_position: Vector2, tile_count: int
) -> CollisionShape2D:
	var col_shape = CollisionShape2D.new()
	col_shape.shape = RectangleShape2D.new()
	col_shape.shape.extents.x = tile_count * (tile_size.x / 2)
	col_shape.shape.extents.y = tile_size.y / 2
	col_shape.position.x = ((start_position.x + end_position.x) / 2)
	col_shape.position.y = ((start_position.y + end_position.y) / 2)

	return col_shape
