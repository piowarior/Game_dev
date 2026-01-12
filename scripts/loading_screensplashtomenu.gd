extends Control

# =====================
# CONFIG
# =====================
@export var loading_time := 5.0
@export_file("*.tscn") var target_scene := "res://scenes/menus/main_menu.tscn"

# =====================
# NODE
# =====================
@onready var bg: Sprite2D = $BackgroundLayer/Background
@onready var tip: Label = $UI/TipLabel
@onready var bar: ProgressBar = $UI/LoadingBar
@onready var spinner: TextureRect = $UI/Spinner
@onready var timer_bg: Timer = $ChangeTimer

# =====================
# DATA
# =====================
var bg_textures := [
	preload("res://assets/loading/loading 1.png"),
	preload("res://assets/loading/loading 2.png"),
	preload("res://assets/loading/loading 3.png"),
	preload("res://assets/loading/loading 4.png"),
	preload("res://assets/loading/loading 5.png"),
	preload("res://assets/loading/loading 6.png"),
	preload("res://assets/loading/loading 7.png"),
	preload("res://assets/loading/loading 8.png"),
	preload("res://assets/loading/loading 9.png"),
	preload("res://assets/loading/loading 10.png"),
	preload("res://assets/loading/loading 11.png"),
]

var tips := [
	"Setiap detik bisa menentukan hidup atau mati.",
	"Jangan asal bergerak. Amati situasi sebelum mengambil keputusan.",
	"Koordinasi tim bukan pilihan, tapi kebutuhan utama.",
	"Keselamatan lebih penting daripada kecepatan.",
	"Satu nyawa lebih berharga dari misi sempurna."
]

# =====================
# STATE
# =====================
var elapsed := 0.0

# =====================
# READY
# =====================

func _reset_ui_font_scale():
	var theme := get_theme()
	if theme == null:
		return

	# reset font size override global
	for type in ["Label", "Button", "RichTextLabel"]:
		if theme.has_font_size(type, "font_size"):
			theme.set_font_size(type, "font_size", 16)


func _ready():
	# 🔒 FIX FINAL FONT GEDE DARI SPLASH
	get_window().content_scale_factor = 1.0
	scale = Vector2.ONE
	position = Vector2.ZERO

	set_anchors_preset(Control.PRESET_FULL_RECT)
	size = get_viewport_rect().size

	get_viewport().canvas_transform = Transform2D.IDENTITY
	get_window().content_scale_factor = 1.0

	# 🔥 RESET THEME FONT (INI YANG NGENAHIN LABEL)
	_reset_ui_font_scale()

	randomize()
	_set_random_content()
	timer_bg.timeout.connect(_change_background)
	bar.value = 0




# =====================
# PROCESS
# =====================
func _process(delta):
	elapsed += delta
	bar.value = (elapsed / loading_time) * 100.0

	if spinner:
		spinner.rotation += delta * 3.0

	if elapsed >= loading_time:
		_finish_loading()

# =====================
# BACKGROUND
# =====================
func _change_background():
	_set_random_content()

func _set_random_content():
	bg.texture = bg_textures.pick_random()
	tip.text = tips.pick_random()
	_fit_background()

# =====================
# AUTO FIT BACKGROUND
# =====================
func _fit_background():
	if bg.texture == null:
		return

	var screen_size = size
	var tex_size = bg.texture.get_size()

	var scale_factor = max(
		screen_size.x / tex_size.x,
		screen_size.y / tex_size.y
	)

	bg.scale = Vector2.ONE * scale_factor
	bg.position = screen_size / 2

# =====================
# FINISH (KHUSUS SPLASH)
# =====================
func _finish_loading():
	get_tree().change_scene_to_file(target_scene)
