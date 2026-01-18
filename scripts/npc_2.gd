extends CharacterBody2D

@export var portrait_npc: Texture2D
@export var portrait_player: Texture2D

var dialog_list := []

@onready var area: Area2D = $Area2D
@onready var hint_label: Label = $InteractionLabel

var player_near := false
var dialog_index := 0
var dialog_active := false


func _ready():
	hint_label.visible = false
	area.body_entered.connect(_on_enter)
	area.body_exited.connect(_on_exit)

	_set_dialog_by_map() # 🔥 INI KUNCINYA


# =====================================================
# PILIH DIALOG BERDASARKAN MAP
# =====================================================
func _set_dialog_by_map():
	var map_name := get_tree().current_scene.name

	if map_name == "MapGempa":
		dialog_list = [
			{ "speaker": "npc", "text": "Saya menemukan satu orang yang terjebak di area runtuhan bangunan ini." },
			{ "speaker": "npc", "text": "Kondisinya masih tertimpa reruntuhan dan belum bisa bergerak sendiri." },
			{ "speaker": "npc", "text": "Dia masih sadar, tapi terlihat sangat kelelahan dan ketakutan." },
			{ "speaker": "player", "text": "Apakah ada luka serius?" },
			{ "speaker": "npc", "text": "Saya tidak melihat luka berat, tapi jelas butuh pertolongan segera." },
			{ "speaker": "npc", "text": "Korban perlu dievakuasi dan dibawa ke pos atau markas evakuasi terdekat." }
		]

	elif map_name == "MapTanahLongsor":
		dialog_list = [
			{ "speaker": "npc", "text": "Saya melihat seorang remaja perempuan tertimbun longsor di area ini." },
			{ "speaker": "npc", "text": "Tubuhnya tertutup tanah dan bebatuan." },
			{ "speaker": "npc", "text": "Korban pingsan dan tidak sadarkan diri." },
			{ "speaker": "player", "text": "Masih hidup?" },
			{ "speaker": "npc", "text": "Masih, tapi kondisinya lemah." },
			{ "speaker": "npc", "text": "Korban harus segera dievakuasi dan dibawa ke pos evakuasi." }
		]

	else:
		dialog_list = [
			{ "speaker": "npc", "text": "Saya tidak memiliki informasi korban di area ini." }
		]


# =====================================================
# AREA
# =====================================================
func _on_enter(body):
	if body.is_in_group("player"):
		player_near = true
		hint_label.text = "Tekan [F]"
		hint_label.visible = true


func _on_exit(body):
	if body.is_in_group("player"):
		player_near = false
		hint_label.visible = false


# =====================================================
# INPUT
# =====================================================
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and dialog_active:
			_advance_dialog()
		return

	if event is InputEventKey and event.pressed and event.keycode == KEY_F:
		if player_near and not dialog_active:
			_start_dialog()
		elif dialog_active:
			_advance_dialog()


# =====================================================
# DIALOG
# =====================================================
func _start_dialog():
	dialog_active = true
	dialog_index = 0

	var ui := get_tree().current_scene.get_node("NarrativeUI")
	ui.visible = true

	_update_dialog(ui)


func _update_dialog(ui: CanvasLayer):
	var dialog_text := ui.get_node("DialogBox/DialogText") as RichTextLabel
	var portrait := ui.get_node("DialogBox/Portrait") as TextureRect

	var data = dialog_list[dialog_index]
	dialog_text.text = data["text"]
	portrait.texture = portrait_npc if data["speaker"] == "npc" else portrait_player
	portrait.visible = true


func _advance_dialog():
	dialog_index += 1
	var ui := get_tree().current_scene.get_node("NarrativeUI")

	if dialog_index < dialog_list.size():
		_update_dialog(ui)
	else:
		ui.visible = false
		dialog_active = false
		hint_label.visible = false
		_reveal_victim_info()


# =====================================================
# MISSION UPDATE
# =====================================================
func _reveal_victim_info():
	if not GameState.current_mission.has("korban"):
		return

	for korban in GameState.current_mission["korban"]:
		if korban["task"] == "SEARCH INFO":
			korban["task"] = "EVAC + FOLLOW"
