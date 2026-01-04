extends Node2D

@onready var area = $Area2D
@onready var label = $Label

@export var confirm_ui_scene: PackedScene
@export var dps_penalty := 15
@export var time_penalty := 20
@export var dps_reward_per_npc := 10

var player_inside := false
var can_interact := false
var ui_opened := false



func _ready():
	label.visible = false
	can_interact = false

	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

	# ⏳ delay kecil supaya gak auto aktif
	await get_tree().create_timer(0.3).timeout
	can_interact = true


func _process(delta):
	if not can_interact:
		return

	if player_inside and Input.is_action_just_pressed("interact"):
		_show_confirm_ui()


func _on_body_entered(body):
	if body is CharacterBody2D:
		player_inside = true
		label.visible = true
		label.text = "Press F"

func _on_body_exited(body):
	if body is CharacterBody2D:
		player_inside = false
		label.visible = false

# =========================
# UI KONFIRMASI
# =========================
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
	_apply_penalty()
	_save_npc_if_any()
	get_tree().change_scene_to_file("res://Scenes/Basecamp.tscn")

func _on_cancelled():
	ui_opened = false
	print("Batal balik ke markas")


# =========================
# LOGIC MARKAS
# =========================
func _apply_penalty():
	GameState.dps = max(0, GameState.dps - dps_penalty)
	GameState.time_left = max(0, GameState.time_left - time_penalty)

	print("Penalty → DPS:", GameState.dps, " Time:", GameState.time_left)

func _save_npc_if_any():
	if GameState.following_npc <= 0:
		return

	var count = GameState.following_npc

	GameState.saved_npc += count
	GameState.dps += count * dps_reward_per_npc
	GameState.following_npc = 0

	print("NPC diselamatkan:", GameState.saved_npc)
