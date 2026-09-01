extends PanelContainer

func open_menu() -> void:
	show()
	PauseManager.register_menu(self)

func close_menu() -> void:
	hide()
	PauseManager.unregister_menu(self)

# Example: Handle the 'ui_cancel' (Esc/Start) button
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		if visible:
			close_menu()
		else:
			open_menu()
			if $ScrollContainer/Inventory.get_children():
				$ScrollContainer/Inventory.get_child(0).grab_focus()
