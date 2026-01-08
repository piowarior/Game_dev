extends Node2D

@onready var camera = $Camera2D # Pastikan ada node Camera2D di hirarki Basecamp kamu

# Pengaturan Gempa
var shake_intensity: float = 7.0 
var shake_duration: float = 0.0 

func _ready():
    # Pastikan kamera bersih di awal
    if camera:
        camera.offset = Vector2.ZERO
    
    # --- LOGIKA "HANYA SEKALI" ---
    # Cek apakah gempa sudah pernah terjadi sebelumnya
    if not GameState.has_shaken_in_basecamp:
        # Setel menjadi true agar saat balik lagi ke sini, kode ini tidak jalan lagi
        GameState.has_shaken_in_basecamp = true
        
        # Jalankan delay 3 detik
        await get_tree().create_timer(3.0).timeout
        
        # Mulai gempa selama 3 detik
        start_basecamp_shake(3.0)
        print("Gempa pertama kali di Basecamp dimulai!")
    else:
        print("Basecamp sudah pernah gempa, tidak akan diulang.")

func _process(delta):
    # Logika shake tetap sama, hanya berjalan jika shake_duration > 0
    if shake_duration > 0:
        if GameState.screen_shake_enabled:
            camera.offset = Vector2(
                randf_range(-shake_intensity, shake_intensity),
                randf_range(-shake_intensity, shake_intensity)
            )
        else:
            camera.offset = Vector2.ZERO
        
        shake_duration -= delta
    else:
        if camera and camera.offset != Vector2.ZERO:
            camera.offset = Vector2.ZERO

func start_basecamp_shake(duration: float):
    shake_duration = duration
