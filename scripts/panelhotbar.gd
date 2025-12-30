extends Panel

@export var slot_index: int

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			get_parent().slot_clicked(slot_index)
