extends CanvasLayer

@onready var player = get_tree().current_scene.get_node("Player")

func _process(delta: float) -> void:
	$VBoxContainer/Label.text = "Hearts: " + str(player.hp)
	$PanelContainer/Label.text = "Ruby: " + str(player.rubies)
	$PanelContainer/Label2.text = "Gold: " + str(player.gold)
	$Logs.text = array_to_string(Global.logs)

func array_to_string(arr: Array) -> String:
	var s = ""
	for i in arr:
		s += String(i) + "\n"
	return s

var toggle = 0

func _input(event: InputEvent) -> void:
	
	if Input.is_action_just_pressed("map"):
		toggle += 1
	if toggle == 1:
		$MarginContainer.visible = true
	if toggle == 0:
		$MarginContainer.visible = false
	if toggle > 1:
		toggle = 0
