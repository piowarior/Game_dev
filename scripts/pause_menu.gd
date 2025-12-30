extends CanvasLayer

@onready var panel = $Panel
@onready var btn_resume = $Panel/BtnResume
@onready var btn_quit = $Panel/BtnQuit

var is_paused = false

func _ready():
	# Sembunyikan panel saat awal
	panel.visible = false
	
	# Connect tombol HANYA lewat script
	btn_resume.pressed.connect(_on_btn_resume_pressed)
	btn_quit.pressed.connect(_on_btn_quit_pressed)

func toggle_pause():
	is_paused = !is_paused
	panel.visible = is_paused
	get_tree().paused = is_paused

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_pause()

func _on_btn_resume_pressed() -> void:
	# Lanjutkan game
	toggle_pause()

func _on_btn_quit_pressed() -> void:
	# Keluar game
	get_tree().quit()
