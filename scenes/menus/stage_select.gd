extends Control

const STAGE_BOX_SCENE = preload("res://scenes/menus/stage_box.tscn")
@onready var stage_container = %StageContainer
@onready var back_button = $CenterContainer/VBoxContainer_Outer/BackButton

# DATA STAGE: Set stars ke 0 biar kosong pas awal
var stages_data = [
	{
		"id": 1,
		"name": "GEMPA BUMI",
		"disaster": "gempa",
		"stars": 0,
		"unlocked": true,
		"image": preload("res://assets/stage/stage1image.png"),
		"path": "res://scenes/main.tscn"
	},
	{
		"id": 2,
		"name": "BANJIR",
		"disaster": "banjir",
		"stars": 0,
		"unlocked": false,
		"image": preload("res://assets/stage/stage2image.png"),
		"path": "res://scenes/stage_2.tscn"
	}
]


func _ready():
	initialize_menu()
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)

func initialize_menu():
	# Bersihkan container biar nggak numpuk pas di-load ulang
	for child in stage_container.get_children():
		child.queue_free()
	
	for data in stages_data:
		var box = STAGE_BOX_SCENE.instantiate()
		stage_container.add_child(box)
		box.setup_stage(data)

func _on_back_button_pressed():
	# Langsung pindah ke Main Menu
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
