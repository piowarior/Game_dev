extends CanvasLayer

@onready var panel = $Panel
@onready var btn_resume = $Panel/BtnResume
@onready var btn_option = $Panel/BtnOption
@onready var btn_quit = $Panel/BtnQuit

@export var options_panel_scene: PackedScene

var is_paused := false
var options_instance: Control = null

func _ready():
	get_tree().paused = false
	is_paused = false
	panel.visible = false

	btn_resume.pressed.connect(_on_btn_resume_pressed)
	btn_option.pressed.connect(_on_btn_option_pressed)
	btn_quit.pressed.connect(_on_btn_quit_pressed)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	is_paused = !is_paused
	panel.visible = is_paused
	get_tree().paused = is_paused

func _on_btn_resume_pressed():
	toggle_pause()

func _on_btn_option_pressed():
	if not is_paused:
		return

	panel.visible = false

	if options_panel_scene and options_instance == null:
		options_instance = options_panel_scene.instantiate()
		add_child(options_instance)
		options_instance.tree_exited.connect(_on_options_closed)

func _on_options_closed():
	options_instance = null
	panel.visible = true

func _on_btn_quit_pressed():
	get_tree().quit()
