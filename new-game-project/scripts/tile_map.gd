extends TileMapLayer

var moisture = FastNoiseLite.new()
var temperature = FastNoiseLite.new()
var altitude = FastNoiseLite.new()

var width = 32
var height = 32

var sea_level = 0
var noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH

var loaded_chunks = []

# Tracks custom player/script changes so noise generation won't overwrite them
var modified_tiles: Dictionary = {}

@onready var player = get_tree().current_scene.get_node("Player")

func _ready() -> void:
	moisture.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	temperature.noise_type = FastNoiseLite.TYPE_VALUE
	altitude.noise_type = noise_type
	
	moisture.seed = randi()
	temperature.seed = randi()
	altitude.seed = randi()
	
	altitude.frequency = 0.008

# Call this function whenever you want to change a tile via script!
func set_custom_tile(world_pos: Vector2i, source_id: int, atlas_coords: Vector2i):
	modified_tiles[world_pos] = {"source_id": source_id, "atlas": atlas_coords}
	set_cell(world_pos, source_id, atlas_coords)

var render_distance: int = 1 

func update_chunks():
	var player_tile_pos = local_to_map(player.position)
	
	# Get player's current chunk center
	var current_chunk_x = int(floor(float(player_tile_pos.x) / width)) * width + (width / 2)
	var current_chunk_y = int(floor(float(player_tile_pos.y) / height)) * height + (height / 2)
	var center_chunk_pos = Vector2i(current_chunk_x, current_chunk_y)

	# Generate all chunks within the render distance grid
	for x in range(-render_distance, render_distance + 1):
		for y in range(-render_distance, render_distance + 1):
			var chunk_pos = Vector2i(
				center_chunk_pos.x + (x * width),
				center_chunk_pos.y + (y * height)
			)
			
			if chunk_pos not in loaded_chunks:
				generate_chunk(chunk_pos)

	# Unload chunks beyond the render boundary
	unload_distant_chunks(center_chunk_pos)

func generate_chunk(pos: Vector2i):
	for x in range(width):
		for y in range(height):
			var cell_pos := Vector2i(pos.x - (width / 2) + x, pos.y - (height / 2) + y)
			
			# Preserve modified tiles
			if cell_pos in modified_tiles:
				var data = modified_tiles[cell_pos]
				set_cell(cell_pos, data["source_id"], data["atlas"])
				continue

			var moist = moisture.get_noise_2d(cell_pos.x, cell_pos.y) * 10
			var temp = temperature.get_noise_2d(cell_pos.x, cell_pos.y) * 10
			var alt = altitude.get_noise_2d(cell_pos.x, cell_pos.y) * 10
			
			moist = clamp(abs(moist), 0, 4)
			temp = clamp(abs(temp), 0, 3)

			if alt < sea_level: 
				set_cell(cell_pos, 0, Vector2i(6, 0))
			else:
				var atlas_pos := Vector2i(
					int(round(2 * abs(moist * 10) / 20)),
					int(round(2 * (temp * 10) / 20))
				)
				set_cell(cell_pos, 0, atlas_pos)

	loaded_chunks.append(pos)
	
	if not player.found_spawn_tile:
		player.check_if_stuck()

func unload_distant_chunks(player_chunk_pos: Vector2i):
	var unload_distance_threshold = (width * 3)

	for i in range(loaded_chunks.size() - 1, -1, -1):
		var chunk = loaded_chunks[i]
		var distance_to_player = chunk.distance_to(player_chunk_pos)

		if distance_to_player > unload_distance_threshold:
			clear_chunk(chunk)
			loaded_chunks.remove_at(i)

func clear_chunk(pos: Vector2i):
	for x in range(width):
		for y in range(height):
			var cell_pos := Vector2i(pos.x - (width / 2) + x, pos.y - (height / 2) + y)
			# Do not erase cell if player modified it, or erase standard cells
			set_cell(cell_pos, -1)

func _on_timer_timeout() -> void:
	if player.velocity != Vector2.ZERO or not player.found_spawn_tile:
		update_chunks()

func destroy_tile(pos):
	set_cell(pos, 0, Vector2(3,6))
	await get_tree().create_timer(0.2).timeout
	set_cell(pos, 0, Vector2(1,2))

func build_tile(pos):
	set_cell(pos, 0, Vector2(1,4))
