static func get_field_instances_as_dict(field_instances: Array) -> Dictionary:
	var dict := {}

	for field_instance in field_instances:
		var key :String= field_instance.__identifier
		dict[key] = get_field_as_value(field_instance)

	return dict

static func get_field_as_value(field_instance: Variant) -> Variant:
	var value = field_instance.__value
	var type :String = field_instance.__type
	match type:
		"Int":
			return int(value)
		"Float", "Bool", "String", "Multilines":
			return value
		"Color":
			return Color.from_string(value, Color.MAGENTA)
		"Point":
			if value == null:
				return null
			return Vector2i(value.cx, value.cy)
		"FilePath":
			return value
		"EntityRef":
			return value
		"Array<Int>":
			return value.map(func(item): return int(item))
		"Array<Point>":
			return value.map(
				func(item):
					if item == null:
						return null
					return Vector2i(item.cx, item.cy)
			)
		"Array<Multilines>":
			return value
		_:
			return value
