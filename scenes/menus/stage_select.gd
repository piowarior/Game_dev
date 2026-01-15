extends Control

# Memastikan scene box level sudah ter-preload
const STAGE_BOX_SCENE = preload("res://scenes/menus/stage_box.tscn")

# Referensi node menggunakan % (Unique Name) atau path lengkap
@onready var stage_container = %StageContainer
@onready var back_button = find_child("BackButton")

func _ready():
    # Inisialisasi menu saat scene siap
    initialize_menu()
    
    # Hubungkan sinyal tombol back
    if back_button:
        if not back_button.pressed.is_connected(_on_back_button_pressed):
            back_button.pressed.connect(_on_back_button_pressed)

func initialize_menu():
    # 1. Bersihkan sisa-sisa stage lama di container
    for child in stage_container.get_children():
        child.queue_free()

    # 2. Atur jarak antar kartu stage agar rapi saat di-scroll (Horizontal)
    if stage_container is HBoxContainer:
        stage_container.add_theme_constant_override("separation", 35)

    # 3. Loop data stage dari GameState
    for stage in GameState.stage_data:
        var box = STAGE_BOX_SCENE.instantiate()
        stage_container.add_child(box)
        
        # Logika penentuan gambar berdasarkan tipe bencana di ID
        var img_path = "res://assets/stage/stage1image.png" # Default gempa
        
        if "banjir" in stage.id:
            img_path = "res://assets/stage/stage2image.png"
        elif "kebakaran" in stage.id:
            img_path = "res://assets/stage/stage3image.png"
        elif "gempa" in stage.id:
            img_path = "res://assets/stage/stage1image.png"

        # Setup data ke dalam box
        box.setup_stage({
            "id": stage.id,
            "name": stage.name,
            "disaster": stage.id,
            "stars": stage.stars,
            "unlocked": stage.unlocked,
            "image": load(img_path),
            "path": stage.scene
        })

func _on_back_button_pressed():
    # Logika kembali ke menu utama
    var main_menu = get_parent()
    
    # Cek apakah node menu_container tersedia di parent
    if main_menu.has_node("menu_container"):
        main_menu.get_node("menu_container").visible = true
    elif "menu_container" in main_menu:
        main_menu.menu_container.visible = true
    else:
        # Fallback jika parent tidak punya menu_container, muat ulang scene menu utama
        # get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
        push_warning("menu_container tidak ditemukan di parent!")

    # Hapus menu select stage dari memory
    queue_free()
