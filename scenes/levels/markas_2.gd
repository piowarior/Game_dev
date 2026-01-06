extends Node2D

signal confirmed
signal cancelled

@onready var area = $Area2D
@onready var label = $Label
@onready var sfx_player = $SFXPlayer # Tambahkan AudioStreamPlayer

@export var confirm_ui_scene: PackedScene
@export var dps_penalty := 2
@export var time_penalty := 30
@export var dps_reward_per_npc := 2

# Export untuk Icon (Masukkan texture di Inspector)
@export var icon_victim: Texture2D
@export var icon_dps: Texture2D

var player_inside := false
var ui_opened := false
var input_locked := true
var npc_delivered := 0


func _ready():
	label.visible = false
	input_locked = true
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

	await get_tree().process_frame
	await get_tree().process_frame
	input_locked = false

# =======================
# INPUT & AREA
# =======================
func _process(_delta):
	if input_locked or not player_inside: return
	if Input.is_action_just_pressed("interact"):
		_show_confirm_ui()

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_inside = true
		label.visible = true
		label.text = "Press F"
		npc_delivered = 0   # 🔑 RESET

	if body.is_in_group("npc"):
		npc_delivered += 1
		_save_npc(body)


func _on_body_exited(body):
	if body.is_in_group("player"):
		player_inside = false
		label.visible = false

# =======================
# ANIMASI FLOATING TEXT (SISTEM BARU)
# =======================
# =======================
# ANIMASI POP-UP "TUINGGG"
# =======================
func spawn_floating_text(value: String, icon: Texture2D, color: Color, side_direction: float):
	# 1. Buat Container
	var container = HBoxContainer.new()
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.set_as_top_level(true) # Agar tidak terpengaruh scale markas
	add_child(container)
	
	# 2. Tambahkan Logo
	if icon:
		var rect = TextureRect.new()
		rect.texture = icon
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.custom_minimum_size = Vector2(25, 25)
		container.add_child(rect)
	
	# 3. Tambahkan Teks
	var lbl = Label.new()
	lbl.text = value
	lbl.modulate = color
	lbl.add_theme_font_size_override("font_size", 18) # Buat agak besar agar jelas
	container.add_child(lbl)

	# 4. Atur Posisi Awal (Tepat di tengah markas)
	container.global_position = global_position + Vector2(-20, -10)
	container.pivot_offset = container.size / 2 # Pivot di tengah agar scale bagus
	
	# 5. LOGIKA ANIMASI "TUINGGG" (TWEEN)
	var tween = create_tween().set_parallel(true)
	
	# --- Animasi Skala (Mengecil lalu membesar tiba-tiba / Pegas) ---
	container.scale = Vector2.ZERO
	tween.tween_property(container, "scale", Vector2(1.2, 1.2), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# --- Animasi Posisi (Terlempar ke samping dan ke atas) ---
	var jump_height := -80.0
	var jump_side := side_direction * 40.0 # side_direction: -1 untuk kiri, 1 untuk kanan
	
	tween.tween_property(container, "global_position:y", container.global_position.y + jump_height, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(container, "global_position:x", container.global_position.x + jump_side, 0.6).set_trans(Tween.TRANS_LINEAR)

	# --- Animasi Menghilang (Fade Out cepat di akhir) ---
	tween.tween_property(container, "modulate:a", 0.0, 0.3).set_delay(0.7)
	
	# Hapus node setelah selesai
	tween.chain().tween_callback(container.queue_free)

# =======================
# SELAMATKAN NPC (DENGAN ARAH TERLEMPAR)
# =======================
func _save_npc(npc):
	if npc == null: return

	var v_point = npc.rescue_point if npc.has_method("rescue_point") else 1
	var d_point = npc.dps if npc.has_method("dps") else dps_reward_per_npc

	GameState.victim_saved += v_point
	GameState.decision_points += d_point

	# Efek "Tuinggg" ke kiri untuk Korban, ke kanan untuk DPS
	spawn_floating_text("+" + str(v_point) + " Korban", icon_victim, Color.WHITE, -1.0) # Terlempar ke kiri
	spawn_floating_text("+" + str(d_point) + " DPS", icon_dps, Color.YELLOW, 1.0)    # Terlempar ke kanan

	if sfx_player:
		sfx_player.play()

	npc.queue_free()
# =======================
# UI & NAVIGATION
# =======================
func _show_confirm_ui():
	if ui_opened or confirm_ui_scene == null: return
	ui_opened = true
	var ui = confirm_ui_scene.instantiate()
	get_tree().root.add_child(ui)
	ui.confirmed.connect(_on_confirmed)
	ui.cancelled.connect(_on_cancelled)

func _on_confirmed():
	# ❌ JANGAN save lagi
	# _save_all_npc_in_area()

	if npc_delivered == 0:
		_apply_penalty()

	emit_signal("confirmed")
	GameState.next_scene_path = "res://Scenes/menus/Basecamp.tscn"
	get_tree().change_scene_to_file("res://Scenes/menus/LoadingScreen.tscn")


func _on_cancelled():
	ui_opened = false

func _save_all_npc_in_area():
	var npcs = get_tree().get_nodes_in_group("npc")
	for npc in npcs:
		_save_npc(npc)

func _apply_penalty():
	GameState.decision_points = max(
		0,
		GameState.decision_points - dps_penalty
	)

	# ⏱️ penalti waktu 2x
	GameState.time_left = max(
		0,
		GameState.time_left - (time_penalty * 2)
	)
