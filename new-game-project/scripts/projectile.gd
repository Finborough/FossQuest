extends CharacterBody2D

@onready var player = get_tree().current_scene.get_node("Player")
@onready var tilemap = get_tree().current_scene.get_node("GroundTiles")
@onready var sprite = $CanvasGroup/Sprite2D

var speed = 100
var direction = Vector2(1,0)

func _ready() -> void:
	direction = player.atk_direction
	look_at(position + direction)

func _physics_process(delta: float) -> void:
	velocity = direction * speed
	move_and_slide()




func _on_area_2d_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, _local_shape_index: int) -> void:
	if body is TileMapLayer:
		# 1. Try the primary, perfect method (Physics RID lookup)
		var map_pos: Vector2i = tilemap.get_coords_for_body_rid(body_rid)
		
		# 2. FALLBACK SAFETY: If map_pos comes back invalid, calculate it using global space
		if map_pos == Vector2i(-1, -1) or tilemap.get_cell_source_id(map_pos) == -1:
			# Use this Area2D's global position instead of the player's center
			var local_pos: Vector2 = tilemap.to_local(global_position)
			map_pos = tilemap.local_to_map(local_pos)
			
		# 3. Final verification check
		var source_id: int = tilemap.get_cell_source_id(map_pos)
		if source_id != -1 and speed > 0:
			# 4. Check if the tile actually contains physics data (double verification)
			var tile_data: TileData = tilemap.get_cell_tile_data(map_pos)
			if tile_data and tile_data.get_collision_polygons_count(0) > 0:
				print("Successfully locked onto tile at: ", map_pos)
				tilemap.destroy_tile(map_pos)

				queue_free()
				
				
				# Commit to chunk system and erase
				#ChunkManager.erased_tiles[map_pos] = true 
				
