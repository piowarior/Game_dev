extends CanvasLayer

@onready var panel: Panel = $Panel
@onready var list: ItemList = $Panel/VBoxContainer/ScrollContainer/ItemList
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton

func _ready():
	panel.visible = false
	close_button.pressed.connect(hide_ui)

func toggle_ui():
	panel.visible = !panel.visible
	if panel.visible:
		load_backpack()

func hide_ui():
	panel.visible = false

func load_backpack():
	list.clear()

	for item_name in GameState.backpack:
		var data = GameState.get_item_data(item_name)
		if data and data.icon:
			list.add_item(item_name, data.icon)
		else:
			list.add_item(item_name)
