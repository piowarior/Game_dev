extends CanvasLayer

@onready var panel: Panel = $Panel
@onready var list: ItemList = $Panel/VBoxContainer/ScrollContainer/ItemList
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton
@onready var audio_open = $AudioStreamPlayer_Open
@onready var audio_close = $AudioStreamPlayer_Close

func _ready():
	panel.visible = false
	panel.scale = Vector2(0.9, 0.9)
	panel.modulate.a = 0.0
	close_button.pressed.connect(hide_ui)

# =========================
# TOGGLE UI (OPEN / CLOSE)
# =========================
func toggle_ui():
	if panel.visible:
		hide_ui()
	else:
		open_ui()

# =========================
# OPEN BACKPACK UI
# =========================
func open_ui():
	audio_open.play()
	panel.visible = true
	load_backpack()

	# animasi buka (halus, gak ekstrem)
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)

	panel.scale = Vector2(0.9, 0.9)
	panel.modulate.a = 0.0

	tween.tween_property(panel, "scale", Vector2(1, 1), 0.15)
	tween.parallel().tween_property(panel, "modulate:a", 1.0, 0.15)

# =========================
# CLOSE BACKPACK UI
# =========================
func hide_ui():
	audio_close.play()

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)

	tween.tween_property(panel, "scale", Vector2(0.9, 0.9), 0.12)
	tween.parallel().tween_property(panel, "modulate:a", 0.0, 0.12)

	tween.finished.connect(func():
		panel.visible = false
	)

# =========================
# LOAD ITEM BACKPACK
# =========================
func load_backpack():
	list.clear()

	for item_name in GameState.backpack:
		var data = GameState.get_item_data(item_name)
		if data and data.icon:
			list.add_item(item_name, data.icon)
		else:
			list.add_item(item_name)
