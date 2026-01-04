extends TextureButton

func _ready():
    # Menghubungkan klik tombol ke fungsi di bawah
    if not pressed.is_connected(_on_tombol_diklik):
        pressed.connect(_on_tombol_diklik)

func _on_tombol_diklik():
    # Mencari node bernama "PauseMenu" di scene mana pun kamu berada
    var menu_pause = get_tree().current_scene.find_child("PauseMenu", true, false)
    
    if menu_pause:
        menu_pause.toggle_pause() # Memanggil fungsi buka menu
        print("Berhasil memanggil PauseMenu")
    else:
        print("Error: Node PauseMenu tidak ditemukan di scene ini!")
