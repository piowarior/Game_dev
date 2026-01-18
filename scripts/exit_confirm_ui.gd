extends CanvasLayer

@onready var panel = $Panel
@onready var btn_berangkat = $Panel/BtnBerangkat
@onready var btn_close = $Panel/BtnClose

func _ready():
	visible = false
	btn_berangkat.pressed.connect(_on_berangkat)
	btn_close.pressed.connect(_on_close)

func _on_berangkat():
	# ambil stage yang benar-benar dipilih player
	var stage_id: String = GameState.disaster_selected

	if stage_id == "":
		push_error("Stage belum dipilih!")
		return

	# ambil scene berdasarkan stage yang aktif
	for stage in GameState.stage_data:
		if stage.id == stage_id:
			GameState.next_scene_path = stage.scene
			get_tree().change_scene_to_file("res://scenes/menus/LoadingScreen.tscn")
			return

	push_error("Scene stage tidak ditemukan untuk: " + stage_id)

func _on_close():
	visible = false
