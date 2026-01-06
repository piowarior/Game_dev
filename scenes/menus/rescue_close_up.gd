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

signal rescue_aborted(stage, layer_index)

var anim_time := 0.0
var base_tool_scale := Vector2.ONE
var base_tool_color := Color.WHITE


var evac_layers: Array = []
var layer_index := 0
var aborted := false
var victim_id := ""


var holding := false
var hold_progress := 0.0
var current_tool := ""

var stage := "EVAC" # atau "MEDIC"
var medic_layers: Array = []


# =========================
# READY
# =========================
func _ready():
	
	base_tool_scale = tool_cursor.scale
	base_tool_color = tool_cursor.modulate

	
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	progress_ui.visible = false
	hint_label.visible = true
	tool_cursor.visible = false

	btn_exit.pressed.connect(_on_exit_pressed)

	if hotbar and hotbar.has_signal("item_changed"):
		hotbar.item_changed.connect(_on_tool_changed)

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_exit_pressed():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.input_locked = false
	aborted = true   # 🔑 PENTING

	if victim_id != "":
		GameState.victim_rescue_state[victim_id] = {
			"stage": stage,
			"layer": layer_index
		}

	emit_signal("rescue_aborted", stage, layer_index)

	#get_tree().paused = false
	visible = false
	queue_free()



func _exit_tree():
	# Kalau close-up mati karena change scene / force close
	if not aborted:
		emit_signal("rescue_aborted", stage, layer_index)


func set_resume_state(_stage, _layer_index):
	stage = _stage
	layer_index = _layer_index
	aborted = true


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

func set_victim_id(id: String):
	victim_id = id


# =========================
# OPEN / CLOSE
# =========================
func open():
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.input_locked = true

	if not aborted:
		layer_index = 0
		stage = "EVAC"

	hold_progress = 0
	progress_bar.value = 0
	load_layer()




func close():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.input_locked = false

	if victim_id != "":
		GameState.victim_rescue_state.erase(victim_id)

	#get_tree().paused = false
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

	# =========================
	# 🔊 PLAY TOOL SFX
	# =========================
	var item_data = GameState.get_item_data(current_tool)
	if item_data and item_data.has("sfx"):
		sfx.stream = item_data.sfx
		sfx.play()

func stop_hold():
	if not holding:
		return

	holding = false
	hold_progress = 0
	progress_bar.value = 0

	progress_ui.visible = false
	hint_label.visible = true

	if sfx and sfx.playing:
		sfx.stop()

# =========================
# PROCESS
# =========================
func _process(delta):
	tool_cursor.global_position = get_viewport().get_mouse_position()

	if not holding:
		anim_time = 0.0
		return

	anim_time += delta

	# =========================
	# ANIMASI ∞ (figure eight)
	# =========================
	var offset_x = sin(anim_time * 6.0) * 12
	var offset_y = sin(anim_time * 12.0) * 6
	tool_cursor.position += Vector2(offset_x, offset_y)

	# =========================
	# AYUNAN KECIL KIRI-KANAN
	# =========================
	tool_cursor.rotation = sin(anim_time * 6.0) * 0.25

	# =========================
	# EFEK MENDEP
	# =========================
	tool_cursor.scale = base_tool_scale * Vector2(0.92, 0.92)

	# =========================
	# EFEK GELAP
	# =========================
	tool_cursor.modulate = Color(0.85, 0.85, 0.85, 1)

	# =========================
	# PROGRESS
	# =========================
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
	else:
		layer = medic_layers[layer_index]

	# 1. Pasang Tekstur
	layer_sprite.texture = layer.texture
	hint_label.text = layer.label

	# 2. Paksa perhitungan skala di frame berikutnya agar size container sudah stabil
	fit_sprite_to_container.call_deferred()

func fit_sprite_to_container():
	if not layer_sprite.texture:
		return

	var container := $PanelMain/VictimContainer
	var tex_size = layer_sprite.texture.get_size()
	
	# Ambil size container (kotak UI tempat gambar muncul)
	var container_size = container.size

	# 🚩 CEK: Jika container_size masih (0,0) atau terlalu kecil karena mengikuti gambar
	# Kita harus pastikan VictimContainer punya 'Min Size' di Inspector.
	if container_size.x < 10 or container_size.y < 10:
		return 

	# Rumus Skala: Pilih yang paling kecil agar seluruh gambar masuk (Fit)
	var scale_factor = min(
		container_size.x / tex_size.x,
		container_size.y / tex_size.y
	)

	# Terapkan skala
	layer_sprite.scale = Vector2(scale_factor, scale_factor)
	
	# Posisikan di tengah container
	layer_sprite.position = container_size / 2


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
		aborted = false
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
