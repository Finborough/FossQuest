extends CanvasLayer

@onready var player = get_tree().current_scene.get_node("Player")
@onready var inventory_node = $InventoryContainer/ScrollContainer/Inventory

var item_atlas_pos : Dictionary = {
	"sword": Vector2(0,48),
	"gold_sword": Vector2(8,48),
	"crossbow": Vector2(16,48),
	"armour": Vector2(24,48),
	"rock": Vector2(0,56),
	"wood": Vector2(0,64),
	"bomb": Vector2(8,56),
	"apple": Vector2(16,56),
	"pear": Vector2(24,56),
	"meat": Vector2(8,64),
	"fish": Vector2(16,64),
	"coconut": Vector2(24,64),
}

func _ready() -> void:
	$PauseText.hide()
	player.add_to_inv("sword")
	player.add_to_inv("apple")

func _process(delta: float) -> void:
	$HotBar/Slot1/TextureRect.texture.region = Rect2(item_atlas_pos[player.hotbar[0]], Vector2(8.0,8.0))
	$HotBar/Slot2/TextureRect2.texture.region = Rect2(item_atlas_pos[player.hotbar[1]], Vector2(8.0,8.0))
	
	if get_tree().paused:
		$PauseText.show()
	else:
		$PauseText.hide()
	
	$Hearts.value = player.hp
	
	$PanelContainer/Label.text = "Ruby: " + str(player.rubies)
	$PanelContainer/Label2.text = "Gold: " + str(player.gold)
	$Logs.text = array_to_string(Global.logs)
	
	if player.current_slot == 0:
		$HotBar/Slot1/Label.text = "(1 – " + str(player.hotbar[0]) + ")"
		$HotBar/Slot2/Label.text = "2 – " + str(player.hotbar[1])
	else:
		$HotBar/Slot1/Label.text = "1 – " + str(player.hotbar[0])
		$HotBar/Slot2/Label.text = "(2 – " + str(player.hotbar[1]) + ")"
	if player.inventory[player.hotbar[0]] != 1:
		$HotBar/Slot1/Label.text += " x" + str(player.inventory[player.hotbar[0]])
	if player.inventory[player.hotbar[1]] != 1:
		$HotBar/Slot2/Label.text += " x" + str(player.inventory[player.hotbar[1]])

func array_to_string(arr: Array) -> String:
	var s = ""
	for i in arr:
		s += String(i) + "\n"
	return s

func dic_to_string(inventory: Dictionary) -> String:
	var string = ""
	for item in inventory:
		string += String(item) + ": " + str(inventory[item]) + "\n"
		
	return string

func add_to_inv(item):
	var inventory = player.inventory
	var button = Button.new()
	button.text = str(item)
	button.name = item
	button.custom_minimum_size = Vector2(290.0,0.0)
	button.add_theme_font_size_override("font_size", 24)
	inventory_node.add_child(button)

func update_inv(update_item):
	var inventory = player.inventory
	for button in inventory_node.get_children():
		button.text = str(button.name) + " x" + str(inventory[str(button.name)])

var paused = false

func pauseMenu():
	if paused:
		get_tree().paused = false
		paused = false
	else:
		get_tree().paused = true
		paused = true
	paused != paused


var toggle = 0

func _input(event: InputEvent) -> void:
	if Input.is_action_pressed("slot1"):
		player.current_slot = 0
	if Input.is_action_pressed("slot2"):
		player.current_slot = 1
	
	for button in inventory_node.get_children():
		if button.has_focus():
			if event.is_action_pressed("ui_accept"):
				get_viewport().set_input_as_handled()

			elif event is InputEventKey and event.pressed and not event.echo:
				if event.keycode == KEY_1:
					#option_1()
					Global.logPrint("Equipped " + button.name + " to slot 1.")
					player.hotbar[0] = str(button.name)
					get_viewport().set_input_as_handled()

				elif event.keycode == KEY_2:
					#option_2()
					Global.logPrint("Equipped " + button.name + " to slot 2.")
					player.hotbar[1] = str(button.name)
					get_viewport().set_input_as_handled()
