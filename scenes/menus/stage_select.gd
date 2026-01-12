extends Control

const STAGE_BOX_SCENE = preload("res://scenes/menus/stage_box.tscn")
@onready var stage_container = %StageContainer
@onready var back_button = $CenterContainer/VBoxContainer_Outer/BackButton

# DATA STAGE: Set stars ke 0 biar kosong pas awal
func initialize_menu():
	for child in stage_container.get_children():
		child.queue_free()

	for stage in GameState.stage_data:
		var box = STAGE_BOX_SCENE.instantiate()
		stage_container.add_child(box)

		box.setup_stage({
			"id": stage.id,
			"name": stage.name,
			"disaster": stage.id,
			"stars": stage.stars,
			"unlocked": stage.unlocked,
			"image": preload("res://assets/stage/stage1image.png"),
			"path": stage.scene
		})



func _ready():
	initialize_menu()
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)


func _on_back_button_pressed():
	# tampilkan menu utama lagi
	get_parent().menu_container.visible = true

	# hapus StageSelect dari scene
	queue_free()
