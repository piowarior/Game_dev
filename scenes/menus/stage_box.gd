extends Button

const FULL_STAR = preload("res://assets/stage/star3.png") 
const EMPTY_STAR = preload("res://assets/stage/starkosong.png") 

@onready var star_container = $VBoxContainer/StarContainer
@onready var level_image = $VBoxContainer/LevelImage
@onready var level_name = $VBoxContainer/LevelName
@onready var lock_overlay = $LockOverlay

# Variabel untuk menyimpan tujuan stage tombol ini
var target_scene_path: String = ""
var disaster_type := ""


func _ready():
	# Sambungkan sinyal klik secara otomatis saat game mulai
	pressed.connect(_on_button_pressed)

func setup_stage(data):
	level_name.text = data.name
	level_image.texture = data.image
	target_scene_path = data.path
	disaster_type = data.get("disaster", "")

	
	# --- SETUP BINTANG ---
	var stars_nodes = star_container.get_children()
	for s in stars_nodes: s.visible = false
	
	var collected_stars = data.get("stars", 0)
	for i in range(3):
		if i < stars_nodes.size():
			var star_node = stars_nodes[i]
			star_node.visible = true 
			if i < collected_stars:
				star_node.texture = FULL_STAR
			else:
				star_node.texture = EMPTY_STAR

	# --- SETUP KUNCI ---
	if data.unlocked:
		lock_overlay.visible = false
		disabled = false  # Tombol aktif
		mouse_filter = Control.MOUSE_FILTER_STOP # Pastikan bisa diklik
		star_container.modulate.a = 1.0 
	else:
		lock_overlay.visible = true
		disabled = true   # Tombol mati
		mouse_filter = Control.MOUSE_FILTER_IGNORE # Biar gak nangkep mouse
		star_container.modulate.a = 0.5 

# Fungsi ini yang jalan saat diklik
func _on_button_pressed():
	if disabled: return

	print("Stage dipilih:", disaster_type)

	# SET GAMESTATE (INI YANG SEBELUMNYA HILANG)
	if has_node("/root/GameState"):
		GameState.disaster_selected = disaster_type
		GameState.start_mission(disaster_type)
	else:
		print("ERROR: GameState belum di-autoload")

	get_tree().change_scene_to_file("res://scenes/menus/Basecamp.tscn")
