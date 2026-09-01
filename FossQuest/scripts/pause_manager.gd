extends Node

signal pause_toggled(is_paused: bool)

var active_menus: Array[Control] = []

func register_menu(menu: Control) -> void:
	if not active_menus.has(menu):
		active_menus.append(menu)
		_update_pause_state()

func unregister_menu(menu: Control) -> void:
	if active_menus.has(menu):
		active_menus.erase(menu)
		_update_pause_state()

func _update_pause_state() -> void:
	var should_pause = active_menus.size() > 0
	get_tree().paused = should_pause
	pause_toggled.emit(should_pause)
