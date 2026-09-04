extends CharacterBody2D

@onready var player = get_tree().current_scene.get_node("Player")
@onready var agent = $Navigation/NavigationAgent2D
@onready var animated_sprite = $CanvasGroup/AnimatedSprite2D
@onready var atk_timer : Timer = $AtkTimer

var anim_direction: String = "down"

var hp = 4

@export var BASE_SPEED = 15
var speed = BASE_SPEED
var stun = false

var knockback : Vector2 = Vector2.ZERO
var knockback_timer : float = 0.0



func _physics_process(delta: float) -> void:
	if test_move(global_transform, Vector2.ZERO):
		queue_free()
	
	if stun:
		return

	if knockback_timer > 0.0:
		velocity = knockback
		knockback_timer -= delta
		if knockback_timer <= 0.0:
			knockback = Vector2.ZERO
	else:
		movement(delta)
	
	move_and_slide()



func movement(delta):
	var direction = Vector2.ZERO

	
	if global_position.distance_to(player.global_position) < 64:


		direction = agent.get_next_path_position() - global_position
		direction = direction.normalized()
		
		velocity = direction * speed
		update_animation_direction(direction)
		animated_sprite.play("walk_" + anim_direction)
		
		
		move_and_slide()

func update_animation_direction(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		anim_direction = "right" if dir.x > 0 else "left"
	else:
		anim_direction = "down" if dir.y > 0 else "up"

func _on_nav_timer_timeout() -> void:
	agent.target_position = player.global_position


func _on_stun_timer_timeout() -> void:
	stun = false
	speed = BASE_SPEED
	if hp <= 0:
		die()
		

func apply_knockback(dir: Vector2, force: float, knockback_duration: float) -> void:
	knockback = dir * force
	knockback_timer = knockback_duration


func die():
	randomize()
	player.add_to_inv("meat")
	Global.logPrint("Looted 1 meat.")
	queue_free()

func attack():
	var knockback_direction = (player.global_position - global_position).normalized()
	player.apply_knockback(knockback_direction, 50.0, 0.2)
	player.hp -= 1
	player.animated_sprite.play("damage")
	player.get_node("StunTimer").start()

func _on_atk_timer_timeout() -> void:
	attack()
