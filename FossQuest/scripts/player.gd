extends CharacterBody2D

# Stats and Inventory
var hp = 3
var food = 0
var gold = 0
var rubies = 0

# Movement
@export var speed: float = 200.0
var anim_direction: String = "down"
var atk_direction : Vector2
var can_atk : bool = true

# Scenes and Nodes
@onready var animated_sprite: AnimatedSprite2D = $CanvasGroup/AnimatedSprite2D
@onready var atk_timer: Timer = $AtkTimer
@onready var world = get_parent()
@onready var tilemap = get_parent().get_node("GroundTiles")
@onready var projectile = preload("res://projectile.tscn")

var inventory : Dictionary = {
	
}

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
	if knockback_timer > 0.0:
		velocity = knockback
		knockback_timer -= delta
		if knockback_timer <= 0.0:
			knockback = Vector2.ZERO
	else:
		movement(delta)
	
	move_and_slide()

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		var atk_pos = position + atk_direction * 8
		tilemap.build_tile(atk_pos, Vector2(0,4), "wood")


func movement(delta):
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
	else:
		inventory[item] = 1

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
