extends MarginContainer

func open_menu() -> void:
	show()
	PauseManager.register_menu(self)

func close_menu() -> void:
	hide()
	PauseManager.unregister_menu(self)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("map"):
		if visible:
			close_menu()
		else:
			open_menu()
