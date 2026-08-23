extends TileMapLayer

@onready var world = get_parent()

var moisture = FastNoiseLite.new()
var temperature = FastNoiseLite.new()
var altitude = FastNoiseLite.new()

var chunk_width = 24
var chunk_height = 24
var size = 1

var sea_level = 0
var noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH

var loaded_chunks = []

# Tracks custom player/script changes so noise generation won't overwrite them
var modified_tiles: Dictionary = {}

var last_chunk_pos: Vector2i
var initialized := false

@onready var player = get_tree().current_scene.get_node("Player")
@onready var snake = preload("res://snake.tscn")

func _ready() -> void:
	moisture.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	temperature.noise_type = FastNoiseLite.TYPE_VALUE
	altitude.noise_type = noise_type
	
	moisture.seed = randi()
	temperature.seed = randi()
	altitude.seed = randi()
	
	altitude.frequency = 0.008
	
	update_chunks(player.position)

# Call this function whenever you want to change a tile via script!
func set_custom_tile(world_pos: Vector2i, source_id: int, atlas_coords: Vector2i):
	modified_tiles[world_pos] = {"source_id": source_id, "atlas": atlas_coords}
	set_cell(world_pos, source_id, atlas_coords)

var render_distance: int = 1 

func update_chunks(center_chunk_pos: Vector2i):
	print("Chunks updated")

	for x in range(-render_distance, render_distance + 1):
		for y in range(-render_distance, render_distance + 1):
			var chunk_pos = Vector2i(
				center_chunk_pos.x + (x * chunk_width),
				center_chunk_pos.y + (y * chunk_height)
			)

			if chunk_pos not in loaded_chunks:
				generate_chunk(chunk_pos)


	unload_distant_chunks(center_chunk_pos)

	unload_distant_chunks(center_chunk_pos)

func generate_chunk(pos: Vector2i):
	for x in range(chunk_width):
		for y in range(chunk_height):
			var cell_pos := Vector2i(pos.x - (chunk_width / 2) + x, pos.y - (chunk_height / 2) + y)
			
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
			elif alt > 4 and moist < 1:
				set_cell(cell_pos, 0, Vector2i(5, 0))
			else:
				var atlas_pos := Vector2i(
					int(round(2 * abs(moist * 10) / 20)),
					int(round(2 * (temp * 10) / 20))
				)
				set_cell(cell_pos, 0, atlas_pos)
				var tile_data = get_cell_tile_data(cell_pos)
				var spawned : bool = false
				
				if tile_data != null and tile_data.get_custom_data("snake_green") == true and randi_range(1,75) == 1:
					var snake_instance = snake.instantiate()
					snake_instance.global_position = to_global(map_to_local(cell_pos))
					get_tree().current_scene.add_child.call_deferred(snake_instance)


	loaded_chunks.append(pos)
	
	#if not player.found_spawn_tile:
	player.check_if_stuck()
		#print("Stuck!")



func _process(_delta):
	var player_tile_pos = local_to_map(player.position)

	var current_chunk_x = int(floor(float(player_tile_pos.x) / chunk_width)) * chunk_width + (chunk_width / 2)
	var current_chunk_y = int(floor(float(player_tile_pos.y) / chunk_height)) * chunk_height + (chunk_height / 2)
	var current_chunk_pos = Vector2i(current_chunk_x, current_chunk_y)

	if not initialized or current_chunk_pos != last_chunk_pos:
		last_chunk_pos = current_chunk_pos
		initialized = true
		update_chunks(current_chunk_pos)



func unload_distant_chunks(player_chunk_pos: Vector2i):
	var unload_distance_threshold = (chunk_width * 3)

	for i in range(loaded_chunks.size() - 1, -1, -1):
		var chunk = loaded_chunks[i]
		var distance_to_player = chunk.distance_to(player_chunk_pos)

		if distance_to_player > unload_distance_threshold:
			clear_chunk(chunk)
			loaded_chunks.remove_at(i)

func clear_chunk(pos: Vector2i):
	for x in range(chunk_width):
		for y in range(chunk_height):
			var cell_pos := Vector2i(pos.x - (chunk_width / 2) + x, pos.y - (chunk_height / 2) + y)
			set_cell(cell_pos, -1)

func _on_timer_timeout() -> void:
	#player.check_if_stuck()
	pass

func destroy_tile(pos):
	world.get_node("AudioStreamPlayer").play()
	set_cell(pos, 0, Vector2(0,8))
	await get_tree().create_timer(0.2).timeout
	set_cell(pos, 0, Vector2(1,2))


func build_tile(pos):
	set_cell(local_to_map(pos), 0, Vector2(0,4))
