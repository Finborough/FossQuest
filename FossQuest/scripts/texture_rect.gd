extends TextureRect

@export var minimap_size: Vector2i = Vector2i(72, 72)
@export var world_size: Vector2i = Vector2i(4096, 4096)
@export var world_origin: Vector2i = Vector2i.ZERO

@onready var player = get_tree().current_scene.get_node("Player")
@onready var tilemap = get_tree().current_scene.get_node("GroundTiles")

@onready var player_icon = $PlayerIcon

func _ready() -> void:
	player_icon.play("default")
	world_size = abs(tilemap.world_min)
	world_origin = abs(tilemap.world_min)


func _process(delta: float) -> void:
	player_icon.position = (player.global_position / 8.0) + Vector2(world_origin)


func generate_minimap() -> void:
	await _ready() 
	var world_size = Vector2i(
		(tilemap.world_chunk_radius * 2 + 1) * tilemap.chunk_width,
		(tilemap.world_chunk_radius * 2 + 1) * tilemap.chunk_height
	)

	var world_min = Vector2i(
		-tilemap.world_chunk_radius * tilemap.chunk_width,
		-tilemap.world_chunk_radius * tilemap.chunk_height
	)

	var img : Image = Image.create(
		world_size.x,
		world_size.y,
		false,
		Image.FORMAT_RGBA8
	)

	for y in range(world_size.y):
		for x in range(world_size.x):
			var world_pos = world_min + Vector2i(x, y)
			var color : Color = WorldData.get_tile_minimap_color(world_pos)

			img.set_pixel(x, y, color)

	texture = ImageTexture.create_from_image(img)
