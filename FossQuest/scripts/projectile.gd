extends CharacterBody2D

@onready var player = get_tree().current_scene.get_node("Player")
@onready var tilemap = get_tree().current_scene.get_node("GroundTiles")
@onready var sprite = $CanvasGroup/Sprite2D
@onready var world = get_parent()

var damage = 1
var speed = 100
var direction = Vector2(1,0)

var first_pos = Vector2()
var range = 16

func _ready() -> void:
	first_pos = position
	direction = player.atk_direction
	look_at(position + direction)

func _physics_process(delta: float) -> void:
	velocity = direction * speed
	move_and_slide()
	
	if position.distance_to(first_pos) > range:
		sprite.frame = 1
		speed = 0
		await get_tree().create_timer(0.2).timeout
		queue_free()




func _on_area_2d_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, _local_shape_index: int) -> void:
	if body is TileMapLayer:
		var map_pos: Vector2i = tilemap.get_coords_for_body_rid(body_rid)
		
		if map_pos == Vector2i(-1, -1) or tilemap.get_cell_source_id(map_pos) == -1:
			var local_pos: Vector2 = tilemap.to_local(global_position)
			map_pos = tilemap.local_to_map(local_pos)
		handle_tile_damage(map_pos, 0.1)



func handle_tile_damage(map_pos: Vector2i, speed: float) -> void:
	world.get_node("AudioStreamPlayer").play()
	var source_id: int = tilemap.get_cell_source_id(map_pos)
	
	if source_id != -1 and speed > 0:
		var tile_data: TileData = tilemap.get_cell_tile_data(map_pos)
		
		if tile_data and tile_data.get_collision_polygons_count(0) > 0:
			if not world.tile_hp_registry.has(map_pos):
				world.tile_hp_registry[map_pos] = tile_data.get_custom_data("hp")
			

			world.tile_hp_registry[map_pos] -= 1


			if world.tile_hp_registry[map_pos] <= 0:
				# Tile-specific treasure rarity is set from the TileSet editor
				var chance = tile_data.get_custom_data("rarity")
				tilemap.destroy_tile(map_pos, randi_range(chance.x, chance.y) == 1)
				world.tile_hp_registry.erase(map_pos)
				queue_free() 
				return
			tilemap.damage_tile(map_pos)
			queue_free()

			


func _on_area_2d_body_entered(body: Node2D) -> void:
	if not body.is_in_group("enemy"):
		return
	queue_free()
	world.get_node("AudioStreamPlayer").play()
	body.animated_sprite.play("damage")
	var knockback_direction = direction
	body.apply_knockback(knockback_direction, 50.0, 0.2)
	body.hp -= damage
	body.get_node("StunTimer").start()
