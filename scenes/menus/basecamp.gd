extends Node2D

@onready var camera = $Camera2D 

# MENCARI KARAKTER: Berdasarkan gambar kamu, namanya adalah CharacterBody2D
# Kode ini akan mencari node tersebut secara otomatis
@onready var player = find_child("CharacterBody2D") 

@onready var bgm_player = get_node_or_null("AudioStreamPlayer")
@onready var sfx_shake = get_node_or_null("AudioStreamPlayerShake")

@onready var narrative_ui = get_node_or_null("NarrativeUI")
@onready var dialog_box = get_node_or_null("NarrativeUI/DialogBox")
@onready var dialog_text = get_node_or_null("NarrativeUI/DialogBox/DialogText")

var dialog_list: Array = [
    "Guncangan yang sangat hebat... apa semua orang baik-baik saja?",
    "Laporan masuk, banyak bangunan di sektor selatan runtuh total.",
    "Kita tidak punya banyak waktu, tim penyelamat harus segera dikerahkan!",
    "Aku harus memastikan peralatan SAR sudah siap di tas punggungku.",
	"Ayo bergerak! Setiap detik sangat berharga untuk menyelamatkan korban."
]
var current_dialog_index: int = 0
var is_dialog_active: bool = false
var shake_intensity: float = 7.0 
var shake_duration: float = 0.0 

func _ready():
    if camera: camera.offset = Vector2.ZERO	
    if narrative_ui: narrative_ui.visible = false
    
    _play_bgm_fade_in()
    
    if not GameState.has_shaken_in_basecamp:
        GameState.has_shaken_in_basecamp = true
        await get_tree().create_timer(3.0).timeout
        start_basecamp_shake(3.0)

func start_basecamp_shake(duration: float):
    shake_duration = duration
    if sfx_shake:
        sfx_shake.volume_db = 10.0
        sfx_shake.play()

func _process(delta):
    if shake_duration > 0:
        if GameState.screen_shake_enabled:
            camera.offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
        shake_duration -= delta
        if shake_duration <= 0:
            _finish_shake_and_narrate()
    else:
        if camera and camera.offset != Vector2.ZERO:
            camera.offset = Vector2.ZERO

func _input(event):
    # Mendeteksi klik untuk lanjut dialog
    if is_dialog_active and event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            _show_next_dialog()

func _finish_shake_and_narrate():
    if sfx_shake and sfx_shake.playing:
        var tween = create_tween()
        tween.tween_property(sfx_shake, "volume_db", -80.0, 1.5)
        await tween.finished
        sfx_shake.stop()
    _start_dialog_sequence()

func _start_dialog_sequence():
    if narrative_ui and dialog_box:
        is_dialog_active = true
        current_dialog_index = 0
        
        # --- PROSES FREEZE ---
        if player:
            # Mematikan proses agar karakter tidak bisa input/gerak
            player.process_mode = Node.PROCESS_MODE_DISABLED 
            print("Karakter Berhasil di-Freeze!")
        else:
            push_warning("Node CharacterBody2D tidak ditemukan!")
        
        narrative_ui.visible = true
        _update_dialog_text()
        
        dialog_box.modulate.a = 0
        create_tween().tween_property(dialog_box, "modulate:a", 1.0, 0.4)

func _update_dialog_text():
    if dialog_text:
        dialog_text.text = dialog_list[current_dialog_index]

func _show_next_dialog():
    current_dialog_index += 1
    if current_dialog_index < dialog_list.size():
        _update_dialog_text()
    else:
        _end_dialog_sequence()

func _end_dialog_sequence():
    is_dialog_active = false
    narrative_ui.visible = false
    
    # --- PROSES UNFREEZE ---
    if player: 
        player.process_mode = Node.PROCESS_MODE_INHERIT
    
    print("Dialog selesai, karakter kembali bebas.")

func _play_bgm_fade_in():
    if bgm_player:
        bgm_player.volume_db = -80
        bgm_player.play()
        create_tween().tween_property(bgm_player, "volume_db", 0.0, 3.0)
