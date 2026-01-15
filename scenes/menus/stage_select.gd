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
		
		# Logika penentuan gambar berdasarkan ID/Tipe (Versi Update)
		var img_path = "res://assets/stage/stage1image.png" # Default gempa
		
		if "banjir" in stage.id:
			img_path = "res://assets/stage/stage2image.png"
		elif "kebakaran" in stage.id:
			img_path = "res://assets/stage/stage3image.png"
		elif "gempa" in stage.id:
			img_path = "res://assets/stage/stage1image.png"

		box.setup_stage({
			"id": stage.id,
			"name": stage.name,
			"disaster": stage.id,
			"stars": stage.stars,
			"unlocked": stage.unlocked,
			"image": load(img_path), # Menggunakan load agar dinamis mengikuti folder assets
			"path": stage.scene
		})

func _ready():
	initialize_menu()
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)


func _on_back_button_pressed():
	# Mencari node menu utama (Versi Update: Lebih aman dari crash)
	var main_menu = get_parent()
	
	if main_menu.has_node("menu_container"): # Cek jika node ada
		main_menu.get_node("menu_container").visible = true
	else:
		# Jika menu_container adalah variabel di dalam script parent
		if "menu_container" in main_menu:
			main_menu.menu_container.visible = true

	# hapus StageSelect dari scene
	queue_free()
