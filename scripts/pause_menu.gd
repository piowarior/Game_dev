extends CanvasLayer

@onready var panel = $Panel
@onready var btn_resume = $Panel/BtnResume
@onready var btn_option = $Panel/BtnOption
@onready var btn_quit = $Panel/BtnQuit

@export var options_panel_scene: PackedScene 

var is_paused := false
var options_instance: Control = null

func _ready():
	# Inisialisasi awal
	self.hide()
	panel.hide()
	get_tree().paused = false
	is_paused = false

	# Hubungkan sinyal tombol (aman dari double-connect)
	if not btn_resume.pressed.is_connected(_on_btn_resume_pressed):
		btn_resume.pressed.connect(_on_btn_resume_pressed)
	if not btn_option.pressed.is_connected(_on_btn_option_pressed):
		btn_option.pressed.connect(_on_btn_option_pressed)
	if not btn_quit.pressed.is_connected(_on_btn_quit_pressed):
		btn_quit.pressed.connect(_on_btn_quit_pressed)

func _input(event):
	# Deteksi tombol ESC
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
		# PENTING: Menandai input sudah ditangani agar tidak "menembus" ke menu lain
		get_viewport().set_input_as_handled()

func toggle_pause():
	is_paused = !is_paused
	get_tree().paused = is_paused
	
	if is_paused:
		self.show()
		panel.show()
	else:
		self.hide()
		panel.hide()
		# Tutup menu option jika sedang terbuka saat unpause
		if options_instance:
			options_instance.queue_free()
			options_instance = null

func _on_btn_resume_pressed():
	toggle_pause()

func _on_btn_option_pressed():
	if options_panel_scene == null:
		return

	panel.hide()
	if options_instance == null:
		options_instance = options_panel_scene.instantiate()
		add_child(options_instance)
		options_instance.tree_exited.connect(_on_options_closed)

func _on_options_closed():
	options_instance = null
	if is_paused:
		panel.show()

func _on_btn_quit_pressed():
	get_tree().quit()
