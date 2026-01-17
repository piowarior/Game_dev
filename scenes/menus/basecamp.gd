extends Node2D

# =====================================================================
# SAR RESCUE - BASECAMP SYSTEM (CLEAN INTEGRATED VERSION)
# =====================================================================

# --- SETTING FONT ---
@export_group("Font Settings")
@export var guide_font_size: int = 25
@export var dialog_font_size: int = 22
@export_file("*.ttf") var custom_font_path: String = "res://assets/font/Axolotl.ttf"

# --- NAVIGATION PATH ---
@export_file("*.tscn") var main_menu_path: String = "res://scenes/menus/main_menu.tscn"

# --- REFERENSI NODE ---
@onready var camera = $Camera2D 
@onready var player = find_child("CharacterBody2D") 

# UI Narasi
@onready var narrative_ui = get_node_or_null("NarrativeUI")
@onready var dialog_text = get_node_or_null("NarrativeUI/DialogBox/DialogText")
@onready var dialog_box = get_node_or_null("NarrativeUI/DialogBox")

# UI Panduan
@onready var guide_ui = find_child("GuideUI") 
@onready var btn_guide = find_child("BtnGuide") 
@onready var close_guide_btn = find_child("CloseGuideButton") 
@onready var guide_label = find_child("GuideText") 
@onready var guide_box = find_child("GuideBox")

# Audio
@onready var sfx_shake = get_node_or_null("AudioStreamPlayerShake")
@onready var bgm_player = get_node_or_null("AudioStreamPlayer")

# --- DATA TEKS ---
var manual_text: String = "[center][b]GUIDE RESCUER[/b][/center]\n\n" + \
	"[b]TUJUAN UTAMA:[/b]\n" + \
	"Lakukan evakuasi warga yang terjebak di reruntuhan sektor selatan.\n\n" + \
	"[b]KONTROL:[/b]\n" + \
	"1. [b]Joystick:[/b] Gerakkan karakter ke area target.\n" + \
	"2. [b]Tombol Aksi:[/b] Interaksi dengan objek atau warga.\n" + \
	"3. [b]Log Book:[/b] Tekan ikon buku untuk membaca panduan ini.\n\n" + \
	"[b]PROSEDUR KESELAMATAN:[/b]\n" + \
	"- Waspada terhadap gempa susulan.\n" + \
	"- Jika layar berguncang, karakter akan berhenti sejenak.\n" + \
	"- Pastikan semua warga dievakuasi sebelum kembali ke Basecamp."

var dialog_list: Array = [
	"Guncangan yang sangat hebat... apa semua orang baik-baik saja?",
	"Aku baru saja mendapat kabar melalui radio bahwa gempa ini menghancurkan sebagian besar pemukiman.",
	"Banyak warga yang dilaporkan masih terjebak di bawah reruntuhan bangunan di sektor selatan.",
	"Aku tidak bisa tinggal diam. Aku harus memastikan peralatan SAR sudah siap di tas punggungku.",
	"Aku harus segera menuju ke lokasi kejadian sebelum gempa susulan merobohkan sisa bangunan yang ada.",
	"Ayo bergerak! Setiap detik sangat berharga untuk menyelamatkan mereka.",
	"MARI BERGERAK!"
]

var current_dialog_index: int = 0
var is_dialog_active: bool = false
var is_guide_open: bool = false
var shake_duration: float = 0.0 
var shake_intensity: float = 6.0

# ===============================
# READY & INITIALIZATION
# ===============================
func _ready():
	# 1. Inisialisasi UI
	if camera: camera.offset = Vector2.ZERO
	if narrative_ui: narrative_ui.visible = false
	if guide_ui: guide_ui.visible = false
	
	# 2. Setup Font & Visual
	_setup_ui_visuals()
	_play_bgm_fade_in()
	
	# 3. Mouse Filter Setup (Agar Tombol X Berfungsi)
	if guide_label: guide_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if guide_box: guide_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if close_guide_btn: close_guide_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# 4. Koneksi Sinyal
	if btn_guide and not btn_guide.pressed.is_connected(_on_open_guide):
		btn_guide.pressed.connect(_on_open_guide)
	if close_guide_btn and not close_guide_btn.pressed.is_connected(_on_close_guide):
		close_guide_btn.pressed.connect(_on_close_guide)

	# 5. Jalankan Efek Gempa (Hanya sekali per sesi Basecamp)
	if not GameState.has_shaken_in_basecamp:
		GameState.has_shaken_in_basecamp = true
		await get_tree().create_timer(2.0).timeout
		_start_shake(3.0)

# ===============================
# EXIT NAVIGATION
# ===============================
func _on_exit_button_pressed():
	get_tree().paused = false 
	if FileAccess.file_exists(main_menu_path):
		get_tree().change_scene_to_file(main_menu_path)
	else:
		push_error("Gagal kembali! File tidak ditemukan di: " + main_menu_path)

# ===============================
# FUNGSI GUIDE & VISUALS
# ===============================
func _setup_ui_visuals():
	var dynamic_font = load(custom_font_path)
	if guide_label and dynamic_font:
		guide_label.add_theme_font_override("normal_font", dynamic_font)
		guide_label.add_theme_font_override("bold_font", dynamic_font)
		guide_label.add_theme_font_size_override("normal_font_size", guide_font_size)
		guide_label.add_theme_font_size_override("bold_font_size", guide_font_size)
		guide_label.bbcode_enabled = true
		guide_label.text = manual_text

	if dialog_text and dynamic_font:
		dialog_text.add_theme_font_override("font", dynamic_font)
		dialog_text.add_theme_font_size_override("font_size", dialog_font_size)

func _on_open_guide():
	is_guide_open = true
	if guide_ui: guide_ui.visible = true
	_set_player_freeze(true)

func _on_close_guide():
	is_guide_open = false
	if guide_ui: guide_ui.visible = false
	if not is_dialog_active:
		_set_player_freeze(false)

# --- FUNGSI GEMPA & NARASI ---
func _start_shake(duration: float):
	shake_duration = duration
	if sfx_shake:
		sfx_shake.volume_db = 0.0
		sfx_shake.play()

func _process(delta):
	if shake_duration > 0:
		if GameState.screen_shake_enabled:
			camera.offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
		shake_duration -= delta
		if shake_duration <= 0:
			camera.offset = Vector2.ZERO
			_finish_shake_and_narrate()

func _finish_shake_and_narrate():
	if sfx_shake and sfx_shake.playing:
		var tween = create_tween()
		tween.tween_property(sfx_shake, "volume_db", -80.0, 1.5)
		await tween.finished
		sfx_shake.stop()
	_start_narrative()

func _start_narrative():
	is_dialog_active = true
	_set_player_freeze(true)
	if narrative_ui: 
		narrative_ui.visible = true
		if dialog_box:
			dialog_box.modulate.a = 0
			create_tween().tween_property(dialog_box, "modulate:a", 1.0, 0.4)
	_update_dialog_text()

func _update_dialog_text():
	if dialog_text: 
		dialog_text.text = dialog_list[current_dialog_index]

func _input(event):
	if is_dialog_active and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_show_next_dialog()

func _show_next_dialog():
	current_dialog_index += 1
	if current_dialog_index < dialog_list.size():
		_update_dialog_text()
	else:
		_complete_narrative()

func _complete_narrative():
	is_dialog_active = false
	if narrative_ui: narrative_ui.visible = false
	if not is_guide_open:
		_set_player_freeze(false)

func _set_player_freeze(freeze: bool):
	if player:
		player.process_mode = Node.PROCESS_MODE_DISABLED if freeze else Node.PROCESS_MODE_INHERIT

func _play_bgm_fade_in():
	if bgm_player:
		bgm_player.volume_db = -80
		bgm_player.play()
		create_tween().tween_property(bgm_player, "volume_db", 0.0, 3.0)