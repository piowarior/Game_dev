extends CanvasLayer

# =========================
# EXPORT
# =========================
@export var hold_time := 1.5

# =========================
# NODE REFERENCE
# =========================
@onready var layer_sprite: Sprite2D = $PanelMain/VictimContainer/LayerSprite
@onready var tool_cursor: Sprite2D = $PanelMain/VictimContainer/ToolCursor

@onready var progress_ui: Control = $PanelMain/ProgressUI
@onready var progress_bar: ProgressBar = $PanelMain/ProgressUI/ProgressBar
@onready var label_progress: Label = $PanelMain/ProgressUI/LabelProgress

@onready var hint_label: Label = $PanelMain/HintLabel
@onready var btn_exit: Button = $BtnExit
@onready var sfx: AudioStreamPlayer = $SFXPlayer

@onready var hotbar: HBoxContainer = $Hotbar/Bar

# =========================
# STATE
# =========================
signal rescue_finished

var evac_layers: Array = []
var layer_index := 0

var holding := false
var hold_progress := 0.0
var current_tool := ""

var stage := "EVAC" # atau "MEDIC"
var medic_layers: Array = []


# =========================
# READY
# =========================
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	progress_ui.visible = false
	hint_label.visible = true
	tool_cursor.visible = false

	btn_exit.pressed.connect(close)

	if hotbar and hotbar.has_signal("item_changed"):
		hotbar.item_changed.connect(_on_tool_changed)

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# =========================
# PROFILE
# =========================
func set_profile(profile: Dictionary):
	evac_layers = profile.get("evac_layers", [])
	medic_layers = profile.get("medic_layers", [])

	if evac_layers.is_empty():
		stage = "MEDIC"
	else:
		stage = "EVAC"


# =========================
# OPEN / CLOSE
# =========================
func open():
	visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	layer_index = 0
	hold_progress = 0
	progress_bar.value = 0

	load_layer()


func close():
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	emit_signal("rescue_finished")
	queue_free()

# =========================
# HOTBAR
# =========================
func _on_tool_changed(item_name: String):
	current_tool = item_name

	if item_name == "":
		tool_cursor.visible = false
		hint_label.text = "Pilih alat"
		return

	var item_data = GameState.get_item_data(item_name)
	if item_data:
		tool_cursor.texture = item_data.icon
		tool_cursor.visible = true
		hint_label.text = "Klik & tahan"

# =========================
# INPUT
# =========================
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			start_hold()
		else:
			stop_hold()

# =========================
# HOLD LOGIC
# =========================
func start_hold():
	if holding:
		return

	if current_tool == "":
		hint_label.text = "Pilih alat dulu!"
		return

	if not can_use_tool():
		return

	holding = true
	hold_progress = 0

	progress_ui.visible = true
	hint_label.visible = false
	label_progress.text = "Bekerja..."

	if sfx:
		sfx.play()

func stop_hold():
	if not holding:
		return

	holding = false
	hold_progress = 0
	progress_bar.value = 0

	progress_ui.visible = false
	hint_label.visible = true

	if sfx:
		sfx.stop()

# =========================
# PROCESS
# =========================
func _process(delta):
	tool_cursor.global_position = get_viewport().get_mouse_position()

	if not holding:
		return

	tool_cursor.rotation += delta * 5
	hold_progress += delta
	progress_bar.value = (hold_progress / hold_time) * 100
	shake()

	if hold_progress >= hold_time:
		stop_hold()
		next_layer()

# =========================
# LAYER
# =========================
func load_layer():
	var layer

	if stage == "EVAC":
		layer = evac_layers[layer_index]
	elif stage == "MEDIC":
		layer = medic_layers[layer_index]

	layer_sprite.texture = layer.texture
	hint_label.text = layer.label



func next_layer():
	layer_index += 1

	if stage == "EVAC" and layer_index >= evac_layers.size():
		if medic_layers.is_empty():
			close()
		else:
			stage = "MEDIC"
			layer_index = 0
			load_layer()
		return

	if stage == "MEDIC" and layer_index >= medic_layers.size():
		close()
		return

	load_layer()


func can_use_tool() -> bool:
	var layer

	if stage == "EVAC":
		layer = evac_layers[layer_index]
	else:
		layer = medic_layers[layer_index]

	if current_tool != layer.tool:
		hint_label.text = "Alat salah! Gunakan: " + layer.tool
		return false

	return true


# =========================
# EFFECT
# =========================
func shake():
	var origin := layer_sprite.position
	layer_sprite.position = origin + Vector2(
		randf_range(-2, 2),
		randf_range(-2, 2)
	)
	await get_tree().create_timer(0.03).timeout
	layer_sprite.position = origin
