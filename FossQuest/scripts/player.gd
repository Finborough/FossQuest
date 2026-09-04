extends CharacterBody2D

# Stats and Inventory
var max_hp = 3
var hp = 3
var food = 0
var gold = 0
var rubies = 0

var inventory : Dictionary = {
	"2": 1,
	"3": 0
}
var hotbar : Array = [
	"sword",
	"apple"
]
var current_slot = 0

# Movement
@export var speed: float = 200.0
var anim_direction: String = "down"
var atk_direction : Vector2
var can_atk : bool = true

# Scenes and Nodes
@onready var animated_sprite: AnimatedSprite2D = $CanvasGroup/AnimatedSprite2D
@onready var atk_timer: Timer = $AtkTimer
@onready var world = get_parent()
@onready var hud = get_parent().get_node("HUD/CanvasLayer")
@onready var tilemap = get_parent().get_node("GroundTiles")
@onready var projectile = preload("res://projectile.tscn")


var found_spawn_tile : bool = false

var knockback : Vector2 = Vector2.ZERO
var knockback_timer : float = 0.0



func check_if_stuck() -> bool:
	if test_move(global_transform, Vector2.ZERO):
		print("Spawn area is obstructed! Moving...")
		position.y += randf_range(-50, 50)
		position.x += randf_range(-50, 50)

	return false

func _process(delta: float) -> void:
	if hp <= 0:
		get_tree().reload_current_scene()

func _physics_process(delta: float) -> void:
	clamp_to_camera()
	if knockback_timer > 0.0:
		velocity = knockback
		knockback_timer -= delta
		if knockback_timer <= 0.0:
			knockback = Vector2.ZERO
	else:
		movement(delta)
	
	move_and_slide()

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		var atk_pos = position + atk_direction * 8
		if hotbar[current_slot] == "wood":
			tilemap.build_tile(atk_pos, Vector2(0,4), "wood")
			hud.update_inv("wood")
		if hotbar[current_slot] == "rock":
			tilemap.build_tile(atk_pos, Vector2(0,7), "rock")
			hud.update_inv("rock")
		
		if inventory[hotbar[current_slot]] > 0 and hp < max_hp:
			
			if hotbar[current_slot] == "apple" or hotbar[current_slot] == "pear" or hotbar[current_slot] == "coconut":
					hp += 1
					Global.logPrint("Healed 1 heart.")
					remove_from_inv(hotbar[current_slot], 1)
					hud.update_inv(hotbar[current_slot])

			if hotbar[current_slot] == "meat" or hotbar[current_slot] == "fish":
					hp += 2
					Global.logPrint("Healed 2 hearts.")
					remove_from_inv(hotbar[current_slot], 1)
					hud.update_inv(hotbar[current_slot])

func clamp_to_camera() -> void:
	# 1. Get the current camera node in the scene
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return # Exit safely if no camera is active
		
	# 2. Get the center position and the total size of the screen
	var cam_center = camera.get_screen_center_position()
	var view_size = get_viewport_rect().size / camera.zoom # Adjusts automatically if you use camera zoom
	
	# 3. Calculate the edges (Top-Left and Bottom-Right corners)
	var min_bound = cam_center - (view_size / 2.0)
	var max_bound = cam_center + (view_size / 2.0)
	
	# 4. Restrict player position within those bounds (including player margin)
	global_position.x = clamp(global_position.x, min_bound.x + 0, max_bound.x - 0)
	global_position.y = clamp(global_position.y, min_bound.y + 0, max_bound.y - 0)



func movement(delta):
	var direction : Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if direction != Vector2.ZERO and not Input.is_action_pressed("ui_accept"):
		velocity = direction * speed
		update_animation_direction(direction)
		animated_sprite.play("walk_" + anim_direction)
		atk_direction = direction
	elif Input.is_action_just_pressed("ui_accept") and can_atk and hotbar[current_slot] == "sword":
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

func update_animation_direction(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		anim_direction = "right" if dir.x > 0 else "left"
	else:
		anim_direction = "down" if dir.y > 0 else "up"

func apply_knockback(dir: Vector2, force: float, knockback_duration: float) -> void:
	knockback = dir * force
	knockback_timer = knockback_duration

func add_to_inv(item : String):
	if item in inventory:
		inventory[item] += 1
		hud.update_inv(item)
	else:
		inventory[item] = 1
		hud.add_to_inv(item)


func remove_from_inv(item : String, amount : int) -> bool:
	if item in inventory:
		if amount <= inventory[item]:
			inventory[item] -= 1
			return true
		print("Not enough of this item.")
		return false
	else:
		print("No such item.")
		return false

func _on_atk_timer_timeout() -> void:
	can_atk = true


func _on_hurt_box_body_entered(body: Node2D) -> void:
	
	if not body.is_in_group("enemy"):
		return
	body.attack()
	body.atk_timer.start()


func _on_hurt_box_body_exited(body: Node2D) -> void:
	if not body.is_in_group("enemy"):
		return
	body.atk_timer.stop()


func _on_stun_timer_timeout() -> void:
	animated_sprite.play("walk_right")
