extends Node2D

@onready var camera = $Camera2D 

# Referensi node audio
@onready var bgm_player = get_node_or_null("AudioStreamPlayer")
@onready var sfx_shake = get_node_or_null("AudioStreamPlayerShake")

# Pengaturan Gempa
var shake_intensity: float = 7.0 
var shake_duration: float = 0.0 

func _ready():
    if camera:
        camera.offset = Vector2.ZERO
    
    # 1. Jalankan Efek Fade-In Musik Basecamp
    _play_bgm_fade_in()
    
    # 2. Logika Gempa (Hanya sekali)
    if not GameState.has_shaken_in_basecamp:
        GameState.has_shaken_in_basecamp = true
        
        # Tunggu 3 detik sebelum gempa dimulai
        await get_tree().create_timer(3.0).timeout
        
        # Mulai gempa selama 3 detik
        start_basecamp_shake(3.0)
    else:
        print("Basecamp sudah pernah gempa.")

func _play_bgm_fade_in():
    if bgm_player:
        bgm_player.volume_db = -80
        bgm_player.play()
        var tween = create_tween()
        tween.tween_property(bgm_player, "volume_db", 0.0, 3.0).set_trans(Tween.TRANS_SINE)

func start_basecamp_shake(duration: float):
    shake_duration = duration
    if sfx_shake:
        sfx_shake.volume_db = 24.0 # Pastikan volume normal saat mulai
        sfx_shake.play()

func _process(delta):
    if shake_duration > 0:
        if GameState.screen_shake_enabled:
            camera.offset = Vector2(
                randf_range(-shake_intensity, shake_intensity),
                randf_range(-shake_intensity, shake_intensity)
            )
        
        shake_duration -= delta
        
        # --- MODIFIKASI: Pemicu Fade Out ---
        # Ketika durasi gempa habis (mencapai detik ke-3)
        if shake_duration <= 0:
            _fade_out_shake_sfx()
    else:
        if camera and camera.offset != Vector2.ZERO:
            camera.offset = Vector2.ZERO

# ===============================
# LOGIKA AUDIO FADE-OUT
# ===============================
func _fade_out_shake_sfx():
    if sfx_shake and sfx_shake.playing:
        print("Memulai Fade Out SFX Gempa...")
        var tween = create_tween()
        
        # Menurunkan volume ke -80 (sunyi) dalam waktu 2 detik (bisa diatur)
        tween.tween_property(sfx_shake, "volume_db", -80.0, 2.0).set_trans(Tween.TRANS_SINE)
        
        # Setelah fade out selesai, stop audionya secara total
        await tween.finished
        sfx_shake.stop()
        sfx_shake.volume_db = 0.0 # Reset volume ke standar untuk penggunaan berikutnya
