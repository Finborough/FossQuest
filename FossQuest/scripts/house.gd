extends Node2D

@onready var villager = preload("res://villager.tscn")

func _ready() -> void:
	await get_tree().create_timer(randf_range(1.0, 3.0)).timeout
	randomize()
	#if randi_range(1,8):
	var villager_instance = villager.instantiate()
	villager_instance.global_position = position
	get_tree().current_scene.add_child.call_deferred(villager_instance)
