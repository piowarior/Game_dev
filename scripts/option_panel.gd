extends Control

# Variabel status default
var music_volume = 1.0      
var is_music_playing = true 

# Inisialisasi Audio Bus
var music_bus_index = -1 
var is_audio_initialized = false

# --- JALUR NODE ---
@onready var volume_slider = get_node("Color_Rect/Panel_Container/VBoxContainer/Volume_Container/VolumeSlider")
@onready var volume_label = get_node("Color_Rect/Panel_Container/VBoxContainer/Volume_Container/VolumeLabel")
@onready var music_check = get_node("Color_Rect/Panel_Container/VBoxContainer/Music_Container/MusicCheckButton") 
@onready var back_button = get_node("Color_Rect/Panel_Container/VBoxContainer/Back_Container/BackButton")
# Menggunakan get_node_or_null agar tidak error jika node belum ada
@onready var shake_check = get_node_or_null("Color_Rect/Panel_Container/VBoxContainer/Shake_Container/ShakeCheckButton")

func _ready():
	# --- PERBAIKAN UTAMA: Agar Panel Memenuhi Layar ---
	# Mengatur anchor dan offset agar panel ini mengisi penuh area parent-nya
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# --------------------------------------------------

	# 1. Inisialisasi UI Volume & Musik
	volume_slider.value = music_volume * 100
	music_check.button_pressed = is_music_playing 
	update_volume_label(music_volume * 100)
	
	# 2. Inisialisasi UI Screen Shake dari GameState
	if is_instance_valid(shake_check):
		# Pastikan GameState.gd sudah punya variabel 'screen_shake_enabled'
		shake_check.button_pressed = GameState.screen_shake_enabled
		shake_check.toggled.connect(_on_shake_check_toggled)

	# 3. Hubungkan Sinyal
	volume_slider.value_changed.connect(_on_volume_slider_value_changed)
	music_check.toggled.connect(_on_music_check_button_toggled)
	back_button.pressed.connect(_on_back_button_pressed)

	# 4. Inisialisasi Audio
	_initialize_audio()

func _initialize_audio():
	music_bus_index = AudioServer.get_bus_index("Master") 
	if music_bus_index != -1:
		_update_audio_bus_volume(music_volume)
		_update_audio_bus_mute(is_music_playing)
		is_audio_initialized = true
	else:
		print("Audio Bus Master tidak ditemukan.")

func _process(_delta):
	if not is_audio_initialized:
		_initialize_audio()

# --- LOGIKA SCREEN SHAKE ---
func _on_shake_check_toggled(button_is_pressed):
	GameState.screen_shake_enabled = button_is_pressed
	print("Fitur Gempa (Screen Shake) status: ", "ON" if button_is_pressed else "OFF")

# --- LOGIKA AUDIO ---
func _update_audio_bus_volume(linear_volume):
	if music_bus_index != -1: 
		var db_value = linear_to_db(linear_volume)
		AudioServer.set_bus_volume_db(music_bus_index, db_value)

func _update_audio_bus_mute(is_playing):
	if music_bus_index != -1:
		AudioServer.set_bus_mute(music_bus_index, not is_playing)

func _on_volume_slider_value_changed(value):
	music_volume = value / 100.0
	update_volume_label(value)
	_update_audio_bus_volume(music_volume)

func update_volume_label(value):
	if is_instance_valid(volume_label):
		volume_label.text = "Music: %d%%" % int(value)

func _on_music_check_button_toggled(button_is_pressed):
	is_music_playing = button_is_pressed
	_update_audio_bus_mute(is_music_playing)

# --- LOGIKA KEMBALI ---
func _on_back_button_pressed():
	var parent_node = get_parent()
	if is_instance_valid(parent_node) and parent_node.has_node("MenuContainer"):
		parent_node.get_node("MenuContainer").visible = true
	queue_free()
	print("Option Panel ditutup.")
