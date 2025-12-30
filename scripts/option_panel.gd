extends Control

# Variabel status default
var music_volume = 1.0      
var is_music_playing = true 

# --- KOREKSI: Pindah inisialisasi Bus ke dalam fungsi, agar lebih aman ---
var music_bus_index = -1 
var is_audio_initialized = false # Flag untuk memastikan inisialisasi hanya sekali
# ------------------------------------------------------------------------

# --- JALUR NODE DENGAN METODE GET_NODE (Menggunakan underscore) ---
@onready var volume_slider = get_node("Color_Rect/Panel_Container/VBoxContainer/Volume_Container/VolumeSlider")
@onready var volume_label = get_node("Color_Rect/Panel_Container/VBoxContainer/Volume_Container/VolumeLabel")
@onready var music_check = get_node("Color_Rect/Panel_Container/VBoxContainer/Music_Container/MusicCheckButton") 
@onready var back_button = get_node("Color_Rect/Panel_Container/VBoxContainer/Back_Container/BackButton")
# -----------------------------------------------------------------------------------------

# Fungsi baru untuk mencari dan menginisialisasi Bus
func _initialize_audio():
	music_bus_index = AudioServer.get_bus_index("music")
	if music_bus_index != -1:
		# PENTING: Terapkan pengaturan awal HANYA jika Bus ditemukan
		_update_audio_bus_volume(music_volume)
		_update_audio_bus_mute(is_music_playing)
		is_audio_initialized = true
		print("Audio Bus 'music' berhasil ditemukan dan diinisialisasi.")
	else:
		print("PERINGATAN: Audio Bus 'music' belum ditemukan. Mencoba lagi...")


func _ready():
	# --- Pengecekan Fungsi ---
	if not is_instance_valid(volume_slider):
		print("FATAL ERROR: JALUR NODE SALAH. Volume Slider tidak dapat diinisialisasi.")
		return 
	
	# Inisialisasi UI
	volume_slider.value = music_volume * 100
	music_check.button_pressed = is_music_playing 
	update_volume_label(music_volume * 100)
	
	# Hubungkan sinyal
	music_check.toggled.connect(_on_music_check_button_toggled)
	back_button.pressed.connect(_on_back_button_pressed)

	# --- Coba inisialisasi audio di _ready() ---
	_initialize_audio()


func _process(delta):
	# Jika inisialisasi gagal di _ready(), coba lagi setiap frame
	if not is_audio_initialized:
		_initialize_audio()


func _update_audio_bus_volume(linear_volume):
	# Pastikan Bus index valid sebelum memanggil AudioServer
	if music_bus_index != -1: 
		var db_value = linear_to_db(linear_volume)
		AudioServer.set_bus_volume_db(music_bus_index, db_value)

func _update_audio_bus_mute(is_playing):
	if music_bus_index != -1:
		AudioServer.set_bus_mute(music_bus_index, not is_playing)


func _on_volume_slider_value_changed(value):
	if not is_instance_valid(volume_label): return 
	
	music_volume = value / 100.0
	update_volume_label(value)
	
	# --- TERAPKAN PERUBAHAN VOLUME ---
	_update_audio_bus_volume(music_volume)
	# ------------------------------------


func update_volume_label(value):
	if not is_instance_valid(volume_label): return
	volume_label.text = "Music: %d%%" % int(value)


func _on_music_check_button_toggled(button_is_pressed):
	is_music_playing = button_is_pressed
	
	# --- TERAPKAN MUTE/UNMUTE ---
	_update_audio_bus_mute(is_music_playing)
	# -----------------------------------
	
	print("Music Latar status: ", "ON" if is_music_playing else "OFF")


func _on_back_button_pressed():
	var main_menu = get_parent()
	
	# --- PANGGIL SFX DARI INDUK (MainMenu) ---
	if is_instance_valid(main_menu) and main_menu.has_method("play_click_sfx"):
		main_menu.play_click_sfx()
	# -----------------------------------------
	
	if is_instance_valid(main_menu) and main_menu.has_node("MenuContainer"):
		main_menu.get_node("MenuContainer").visible = true
	
	queue_free()
	print("OptionsPanel ditutup, Menu Utama dipulihkan.")
