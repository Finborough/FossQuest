extends CanvasLayer

@onready var player = get_tree().current_scene.get_node("Player")

func _process(delta: float) -> void:
	$Label.text = "HEARTS: " + str(player.hp)
