extends CanvasLayer

@onready var panel = $Panel
@onready var btn_berangkat = $Panel/BtnBerangkat
@onready var btn_close = $Panel/BtnClose

func _ready():
	visible = false
	btn_berangkat.pressed.connect(_on_berangkat)
	btn_close.pressed.connect(_on_close)

func _on_berangkat():
	get_tree().change_scene_to_file("res://scenes/levels/Map_Gempa.tscn")

func _on_close():
	visible = false
