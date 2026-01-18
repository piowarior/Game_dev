extends CanvasLayer

@onready var panel = $Panel
@onready var btn_berangkat = $Panel/BtnBerangkat
@onready var btn_close = $Panel/BtnClose

func _ready():
    visible = false

    # koneksi tombol
    if not btn_berangkat.pressed.is_connected(_on_berangkat):
        btn_berangkat.pressed.connect(_on_berangkat)

    if not btn_close.pressed.is_connected(_on_close):
        btn_close.pressed.connect(_on_close)


func _on_berangkat():
    # 🔹 HARD SET dulu ke Map Gempa (buat pastiin bisa masuk)
    GameState.next_scene_path = "res://scenes/levels/Map_Gempa.tscn"

    print("Berangkat ke:", GameState.next_scene_path)

    # pindah ke loading screen
    get_tree().change_scene_to_file(
		"res://scenes/menus/LoadingScreen.tscn"
    )


func _on_close():
    visible = false
