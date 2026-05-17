extends Control

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_tree().quit()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		get_tree().quit()
