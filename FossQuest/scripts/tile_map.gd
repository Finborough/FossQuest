extends TileMapLayer

@onready var world = get_parent()

var moisture = FastNoiseLite.new()
var temperature = FastNoiseLite.new()
var altitude = FastNoiseLite.new()

# World size
@export var world_chunk_radius: int = 6
# Chunk size
var chunk_width = 12
var chunk_height = 12

var world_min := Vector2i(
	-world_chunk_radius * chunk_width,
	-world_chunk_radius * chunk_height
)

# Modify how high the sea level is (how much water)
var sea_level = -1

var noise_type = FastNoiseLite

var loaded_chunks = []

# Tracks built and destroyed tiles so the world gen doesn't overwrite them
var modified_tiles: Dictionary = {}

var last_chunk_pos: Vector2i
var initialized = false

@onready var player = get_tree().current_scene.get_node("Player")
@onready var snake = preload("res://snake.tscn")
@onready var deer = preload("res://deer.tscn")


func _ready() -> void:
	Global.logPrint("Destroy Count von Finborough!")

	moisture.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	temperature.noise_type = FastNoiseLite.TYPE_PERLIN
	altitude.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	
	moisture.seed = randi()
	temperature.seed = randi()
	altitude.seed = randi()
	
	altitude.frequency = 0.008
	temperature.frequency = 0.008
	moisture.frequency = 0.01
	
	update_chunks(player.position)
	print(world_min)

func set_custom_tile(world_pos: Vector2i, source_id: int, atlas_coords: Vector2i):
	modified_tiles[world_pos] = {"source_id": source_id, "atlas": atlas_coords}
	set_cell(world_pos, source_id, atlas_coords)

var render_distance: int = 1

func update_chunks(center_chunk_pos: Vector2i):
	
	print("Chunks updated")

	for x in range(-render_distance, render_distance + 1):
		for y in range(-render_distance, render_distance + 1):

			# Position of this chunk in world/tile coordinates
			var chunk_pos := Vector2i(
				center_chunk_pos.x + (x * chunk_width),
				center_chunk_pos.y + (y * chunk_height)
			)

			# Convert world position to chunk coordinates
			var chunk_coord := Vector2i(
				floori(float(chunk_pos.x) / chunk_width),
				floori(float(chunk_pos.y) / chunk_height)
			)

			# Don't generate outside the world boundary
			if abs(chunk_coord.x) > world_chunk_radius:
				continue

			if abs(chunk_coord.y) > world_chunk_radius:
				continue


			if chunk_pos not in loaded_chunks:
				generate_chunk(chunk_pos)
	world.get_node("HUD/CanvasLayer/MarginContainer/SubViewportContainer/SubViewport/Map").generate_minimap()

	

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
			temp = clamp(abs(temp), 0, 1000)
			if temp > 3:
				temp = 3
			# Generate ocean
			if alt < sea_level: 
				set_cell(cell_pos, 0, Vector2i(6, 0))

			# Generate mountains
			elif alt > 5 and moist < 1:
				set_cell(cell_pos, 0, Vector2i(5, 0))

			# Generate everything else
			else:
				var atlas_pos := Vector2i(
					int(round(2 * abs(moist * 10) / 20)),
					int(round(2 * (temp * 10) / 20))
				)
				set_cell(cell_pos, 0, atlas_pos)
				var tile_data = get_cell_tile_data(cell_pos)
				
				if tile_data != null and tile_data.get_custom_data("snake_green") and randi_range(1,300) == 1:
					var snake_instance = snake.instantiate()
					snake_instance.global_position = to_global(map_to_local(cell_pos))
					get_tree().current_scene.add_child.call_deferred(snake_instance)
				if tile_data != null and tile_data.get_custom_data("deer") and randi_range(1,300) == 1:
					var deer_instance = deer.instantiate()
					deer_instance.global_position = to_global(map_to_local(cell_pos))
					get_tree().current_scene.add_child.call_deferred(deer_instance)
				if tile_data != null and tile_data.get_custom_data("stone_dungeon") and randi_range(1,1000) == 1:
					set_cell(cell_pos, 0, Vector2(3,5))
				if tile_data != null and tile_data.get_custom_data("village") and randi_range(1,75) == 1:
					set_pattern(cell_pos, tile_set.get_pattern(0))
				
			var tile_data = get_cell_tile_data(cell_pos)

			if tile_data:
				var color = tile_data.get_custom_data("minimap_color")
				WorldData.set_tile_minimap_color(cell_pos, color)




	loaded_chunks.append(pos)

func get_cell_tile_data_from_atlas_coords(atlas_coords: Vector2i) -> TileData:
	#tile_map_layer holds your TileMapLayer
	var tile_set = get_tile_set()
	
	#assuming tile set source id is 0
	var tile_set_source = tile_set.get_source(0)
	
	#assuming that tile set source is TileSetAtlasSource, not TileSetScenesCollectionSource
	#and assuming that you need the original tile data (0), not the alternative
	return tile_set_source.get_tile_data(atlas_coords, 0)



func _process(_delta):

	var player_tile_pos = local_to_map(player.position)

	var current_chunk_x = int(floor(float(player_tile_pos.x) / chunk_width)) * chunk_width + (chunk_width / 2)
	var current_chunk_y = int(floor(float(player_tile_pos.y) / chunk_height)) * chunk_height + (chunk_height / 2)
	var current_chunk_pos = Vector2i(current_chunk_x, current_chunk_y)

	if not initialized or current_chunk_pos != last_chunk_pos:
		last_chunk_pos = current_chunk_pos
		initialized = true
		update_chunks(current_chunk_pos)

	while player.check_if_stuck():
		pass


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



func damage_tile(map_pos):
	var original_tile = get_cell_atlas_coords(map_pos)
	set_cell(map_pos, 0, Vector2(0,8))
	await get_tree().create_timer(0.2).timeout
	set_cell(map_pos, 0, original_tile)

func destroy_tile(pos, treasure : bool):
	print("DESTROYED!!!")
	var tile_data: TileData = get_cell_tile_data(pos)
	print(tile_data)
	if tile_data.get_custom_data("tree"):
		
		player.add_to_inv("wood")
		Global.logPrint("Picked up wood.")
	elif tile_data.get_custom_data("rock"):
		player.add_to_inv("rock")
		Global.logPrint("Picked up rocks.")
	else:
		print(tile_data.get_custom_data("tree"))
	world.get_node("AudioStreamPlayer").play()
	set_cell(pos, 0, Vector2(0,8))
	await get_tree().create_timer(0.2).timeout
	

		
	
	if treasure:
		check_treasure(tile_data, pos)
		return
	
	set_cell(pos, 0, Vector2(1,1))

func check_treasure(tile_data : TileData, map_pos : Vector2) -> String:
	
	if tile_data.get_custom_data("apple"):
		player.add_to_inv("apple")
		set_cell(map_pos, 0, Vector2(1,1))
		Global.logPrint("Picked up an apple.")
		return "apple"
	elif tile_data.get_custom_data("pear"):
		player.add_to_inv("pear")
		set_cell(map_pos, 0, Vector2(1,1))
		Global.logPrint("Picked up a pear.")
		return "pear"
	elif tile_data.get_custom_data("coconut"):
		player.add_to_inv("coconut")
		set_cell(map_pos, 0, Vector2(0,3))
		Global.logPrint("Picked up a coconut.")
		return "coconut"
	elif tile_data.get_custom_data("mountain"):
		set_cell(map_pos, 0, Vector2(6,3))
		Global.logPrint("Found a cave entrance!")
		return "mountain"
	set_cell(map_pos, 0, Vector2(1,1))
	return "none"




func build_tile(pos, atlas_pos, type):
	var tile_data: TileData = get_cell_tile_data(local_to_map(pos))
	print(tile_data)
	if tile_data.get_custom_data("water"):
		if player.remove_from_inv(type, 1):
			set_cell(local_to_map(pos), 0, atlas_pos)
		else:
			Global.logPrint("Not enough " + type + ".")
	else:
		Global.logPrint("Can't place bridge on land!")
