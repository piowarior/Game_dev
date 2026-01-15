extends Node2D

# =====================================================================
# SAR RESCUE - BASECAMP SYSTEM (NARRATIVE VERSION)
# =====================================================================

# --- SETTING FONT (Bisa diatur dari Inspector) ---
@export_group("Font Settings")
@export var guide_font_size: int = 25    # Ukuran font untuk Buku Panduan
@export var dialog_font_size: int = 22   # Ukuran font untuk Narasi Dialog
@export_file("*.ttf") var custom_font_path: String = "res://assets/font/Axolotl.ttf"

# --- REFERENSI NODE ---
@onready var camera = $Camera2D 
@onready var player = find_child("CharacterBody2D") 

# UI Narasi
@onready var narrative_ui = get_node_or_null("NarrativeUI")
@onready var dialog_text = get_node_or_null("NarrativeUI/DialogBox/DialogText")

# UI Panduan
@onready var guide_ui = find_child("GuideUI") 
@onready var btn_guide = find_child("BtnGuide") 
@onready var close_guide_btn = find_child("CloseGuideButton") 
@onready var guide_label = find_child("GuideText") 
@onready var guide_box = find_child("GuideBox")

@onready var sfx_shake = get_node_or_null("AudioStreamPlayerShake")

# --- KONTEN TEKS PANDUAN ---
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

# --- DATA TEKS NARASI (MONOLOG KARAKTER UTAMA) ---
var dialog_list: Array = [
    "Guncangan itu... sangat kuat.",
    "Aku baru saja mendapat kabar melalui radio bahwa gempa ini menghancurkan sebagian besar pemukiman.",
    "Banyak warga yang dilaporkan masih terjebak di bawah reruntuhan bangunan.",
    "Aku tidak bisa tinggal diam. Ini adalah tugas yang harus aku selesaikan",
    "Aku harus segera menuju ke lokasi kejadian sebelum gempa susulan merobohkan sisa bangunan yang ada.",
    "Waktu terus berjalan. Setiap detik sangat berharga untuk menyelamatkan nyawa mereka.",
	"MARI BERGERAK!"
]

var current_dialog_index: int = 0
var is_dialog_active: bool = false
var is_guide_open: bool = false
var shake_duration: float = 0.0 

func _ready():
    # 1. Inisialisasi UI
    if narrative_ui: narrative_ui.visible = false
    if guide_ui: guide_ui.visible = false
    
    # 2. Setup Font, Size, & Teks
    _setup_ui_visuals()
    
    # 3. Paksa Mouse Filter via Kode agar Tombol X berfungsi
    if guide_label: guide_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    if guide_box: guide_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    if close_guide_btn: close_guide_btn.mouse_filter = Control.MOUSE_FILTER_STOP
    
    # 4. Hubungkan Sinyal Tombol
    if btn_guide:
        if not btn_guide.pressed.is_connected(_on_open_guide):
            btn_guide.pressed.connect(_on_open_guide)
    if close_guide_btn:
        if not close_guide_btn.pressed.is_connected(_on_close_guide):
            close_guide_btn.pressed.connect(_on_close_guide)

    # 5. Efek Gempa
    if not GameState.has_shaken_in_basecamp:
        GameState.has_shaken_in_basecamp = true
        await get_tree().create_timer(2.0).timeout
        _start_shake(3.0)

func _setup_ui_visuals():
    var dynamic_font = load(custom_font_path)
    
    # Atur Guide Text
    if guide_label and dynamic_font:
        guide_label.add_theme_font_override("normal_font", dynamic_font)
        guide_label.add_theme_font_override("bold_font", dynamic_font)
        guide_label.add_theme_font_size_override("normal_font_size", guide_font_size)
        guide_label.add_theme_font_size_override("bold_font_size", guide_font_size)
        guide_label.bbcode_enabled = true
        guide_label.text = manual_text

    # Atur Dialog Text
    if dialog_text and dynamic_font:
        dialog_text.add_theme_font_override("font", dynamic_font)
        dialog_text.add_theme_font_size_override("font_size", dialog_font_size)

# --- FUNGSI GUIDE ---
func _on_open_guide():
    if guide_ui:
        is_guide_open = true
        guide_ui.visible = true
        _set_player_freeze(true)

func _on_close_guide():
    if guide_ui:
        is_guide_open = false
        guide_ui.visible = false
        if not is_dialog_active:
            _set_player_freeze(false)

# --- FUNGSI GEMPA & NARASI ---
func _start_shake(duration: float):
    shake_duration = duration
    if sfx_shake: sfx_shake.play()

func _process(delta):
    if shake_duration > 0:
        camera.offset = Vector2(randf_range(-6, 6), randf_range(-6, 6))
        shake_duration -= delta
        if shake_duration <= 0:
            camera.offset = Vector2.ZERO
            _start_narrative()

func _start_narrative():
    is_dialog_active = true
    _set_player_freeze(true)
    if narrative_ui: narrative_ui.visible = true
    _update_dialog_text()

func _update_dialog_text():
    if dialog_text: 
        dialog_text.text = dialog_list[current_dialog_index]

func _input(event):
    # Klik kiri mouse untuk lanjut narasi
    if is_dialog_active and event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
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
        # Menonaktifkan proses karakter saat narasi/buka buku
        player.process_mode = Node.PROCESS_MODE_DISABLED if freeze else Node.PROCESS_MODE_INHERIT
