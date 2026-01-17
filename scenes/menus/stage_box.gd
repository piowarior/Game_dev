extends Button

const FULL_STAR = preload("res://assets/stage/star1.png") 
const EMPTY_STAR = preload("res://assets/stage/starkosong1.PNG") 

@onready var star_container = $VBoxContainer/StarContainer
@onready var level_image = $VBoxContainer/LevelImage
@onready var level_name = $VBoxContainer/LevelName
@onready var lock_overlay = $LockOverlay
@export var star_full: Texture2D
@export var star_empty: Texture2D


# Variabel untuk menyimpan tujuan stage tombol ini
var target_scene_path: String = ""
var disaster_type := ""


func _ready():
	# Sambungkan sinyal klik secara otomatis saat game mulai
	pressed.connect(_on_button_pressed)

func setup_stage(data: Dictionary):
	level_name.text = data.name
	level_image.texture = data.image

	set_stars(data.stars) # 🔥 INI YANG HILANG

	lock_overlay.visible = not data.unlocked
	disabled = not data.unlocked

	$VBoxContainer/LevelName.text = data.name
	$VBoxContainer/LevelImage.texture = data.image


	$LockOverlay.visible = not data.unlocked
	level_name.text = data.name
	level_image.texture = data.image
	target_scene_path = data.path
	disaster_type = data.get("disaster", "")

	
	# --- SETUP BINTANG ---


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

func set_stars(count: int):
	var stars = star_container.get_children()

	for i in range(stars.size()):
		if i < count:
			stars[i].texture = FULL_STAR
			stars[i].visible = true
		else:
			stars[i].texture = EMPTY_STAR
			stars[i].visible = true



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

	GameState.next_scene_path = "res://scenes/menus/Basecamp.tscn"
	get_tree().change_scene_to_file("res://scenes/menus/LoadingScreen.tscn")
