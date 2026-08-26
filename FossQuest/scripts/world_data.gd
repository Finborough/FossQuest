extends Node

var minimap_data: Dictionary = {}

func set_tile_minimap_color(world_pos: Vector2i, color: Color) -> void:
	minimap_data[world_pos] = color

func get_tile_minimap_color(world_pos: Vector2i) -> Color:
	return minimap_data.get(world_pos, Color.TRANSPARENT)
