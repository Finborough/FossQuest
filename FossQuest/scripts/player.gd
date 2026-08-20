extends CharacterBody2D

# Movement
@export var speed: float = 200.0
var anim_direction: String = "down"
var atk_direction : Vector2
var can_atk = true

# Scenes and Nodes
@onready var animated_sprite: AnimatedSprite2D = $CanvasGroup/AnimatedSprite2D
@onready var atk_timer: Timer = $AtkTimer
@onready var world = get_parent()
@onready var tilemap = get_parent().get_node("GroundTiles")
@onready var projectile = preload("res://projectile.tscn")

var found_spawn_tile : bool = false


func check_if_stuck() -> bool:
	# Keep picking random positions until we find an empty spot
	if test_move(global_transform, Vector2.ZERO):
		print("Spawn area is obstructed! Moving...")
		# Forces PhysicsServer2D to sync immediately before testing again
		while test_move(global_transform, Vector2.ZERO):
			global_position.x += 8
			force_update_transform() 
	await get_tree().create_timer(0.1).timeout
	#if is_standing_on_tile() and test_move(global_transform, Vector2.ZERO) == false:
		##found_spawn_tile = true
		#print("Spawn tile found!")

	return true

func _physics_process(delta: float) -> void:

	var direction : Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if direction != Vector2.ZERO and not Input.is_action_pressed("ui_accept"):
		velocity = direction * speed
		update_animation_direction(direction)
		animated_sprite.play("walk_" + anim_direction)
		atk_direction = direction
	elif Input.is_action_just_pressed("ui_accept") and can_atk:
		atk_timer.start()
		can_atk = false
		
		velocity = Vector2.ZERO
		animated_sprite.frame = 0
		animated_sprite.animation = "attack_" + anim_direction
		var projectile_instance = projectile.instantiate()
		projectile_instance.position = position
		world.add_child(projectile_instance)
	elif animated_sprite.animation != "attack_" + anim_direction:
		velocity = Vector2.ZERO
		animated_sprite.stop()
		animated_sprite.frame = 1
	if Input.is_action_just_released("ui_accept"):
		animated_sprite.frame = 1
		
	move_and_slide()

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		tilemap.build_tile(position + atk_direction * 8)

func is_standing_on_tile() -> bool:
	
	# Convert player's position to tilemap grid coordinates
	var local_pos = tilemap.to_local(global_position)
	var cell_coords = tilemap.local_to_map(local_pos)
	
	# Returns -1 if the cell is empty/has no tile on layer 0
	return tilemap.get_cell_source_id(cell_coords) != -1

func update_animation_direction(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		anim_direction = "right" if dir.x > 0 else "left"
	else:
		anim_direction = "down" if dir.y > 0 else "up"


func _on_atk_timer_timeout() -> void:
	can_atk = true
