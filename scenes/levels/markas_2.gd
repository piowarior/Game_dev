extends Node2D

signal confirmed
signal cancelled

@onready var area = $Area2D
@onready var label = $Label

@export var confirm_ui_scene: PackedScene
@export var dps_penalty := 3          # Penalty DPS jika tidak ada NPC
@export var time_penalty := 30        # Penalty waktu jika tidak ada NPC
@export var dps_reward_per_npc := 10  # Reward per NPC diselamatkan

var player_inside := false
var ui_opened := false

# 🔒 INPUT LOCK
var input_locked := true

func _ready():
	label.visible = false
	player_inside = false
	ui_opened = false
	input_locked = true

	# Connect signals Area
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

	# Buang input frame sisa dari scene sebelumnya
	await get_tree().process_frame
	await get_tree().process_frame
	input_locked = false

# =======================
# INPUT
# =======================
func _process(delta):
	if input_locked:
		return
	if not player_inside:
		return
	if Input.is_action_just_pressed("interact"):
		_show_confirm_ui()

# =======================
# AREA
# =======================
func _on_body_entered(body):
	# Player masuk
	if body.is_in_group("player"):
		player_inside = true
		label.visible = true
		label.text = "Press F"

	# NPC masuk → langsung selamatkan
	if body.is_in_group("npc"):
		_save_npc(body)

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_inside = false
		label.visible = false

# =======================
# UI
# =======================
func _show_confirm_ui():
	if ui_opened:
		return
	if confirm_ui_scene == null:
		push_error("Confirm UI belum di set!")
		return

	ui_opened = true
	var ui = confirm_ui_scene.instantiate()
	get_tree().root.add_child(ui)

	ui.confirmed.connect(_on_confirmed)
	ui.cancelled.connect(_on_cancelled)

func _on_confirmed():
# Selamatkan semua NPC di area, jika ada
	_save_all_npc_in_area()

	# Kalau tidak ada NPC yang diselamatkan → beri penalti
	if GameState.victim_saved == 0:
		_apply_penalty()

	emit_signal("confirmed")

	# SET TUJUAN SCENE → Basecamp
	GameState.next_scene_path = "res://Scenes/menus/Basecamp.tscn"

	# PINDAH VIA LOADING SCREEN
	get_tree().change_scene_to_file("res://Scenes/menus/LoadingScreen.tscn")

	

func _on_cancelled():
	ui_opened = false

# =======================
# LOGIC MARKAS
# =======================
func _apply_penalty():
	GameState.decision_points = max(0, GameState.decision_points - dps_penalty)
	GameState.time_left = max(0, GameState.time_left - time_penalty)

	print(
		"Penalty → Decision:", GameState.decision_points,
		" Time:", GameState.time_left
	)

# =======================
# SELAMATKAN NPC
# =======================
func _save_npc(npc):
	if npc == null:
		return

	# Tambah korban sesuai rescue_point NPC (default 1)
	if npc.has_method("rescue_point"):
		GameState.victim_saved += npc.rescue_point
	else:
		GameState.victim_saved += 1

	# Tambah DPS sesuai NPC (default dps_reward_per_npc)
	if npc.has_method("dps"):
		GameState.decision_points += npc.dps
	else:
		GameState.decision_points += dps_reward_per_npc

	print("NPC diselamatkan | Victim:", GameState.victim_saved,
		  "| DPS:", GameState.decision_points)

	npc.queue_free() # NPC hilang dari scene

func _save_all_npc_in_area():
	# Ambil semua NPC yang masih di group
	var npcs = get_tree().get_nodes_in_group("npc")
	for npc in npcs:
		_save_npc(npc)
