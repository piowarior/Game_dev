extends Control

@onready var bar: ProgressBar = $ProgressBar
var fill_style: StyleBoxFlat
var tap_boost := 1.0
var tap_window := 0.15
var tap_timer := 0.0



var active := false
var is_running := false

var decay_speed := 18.0
var recover_speed := 25.0

var dps_timer := 0.0
var dps_interval := 4.0   # tiap 4 detik

func _ready():
	visible = false
	bar.show_percentage = false
	bar.min_value = 0
	bar.max_value = 100

	fill_style = bar.get_theme_stylebox("fill").duplicate()
	bar.add_theme_stylebox_override("fill", fill_style)


func start():
	active = true
	is_running = true
	visible = true
	bar.value = 50
	dps_timer = 0.0

func stop():
	active = false
	is_running = false
	visible = false

func _process(delta):
	if not active:
		return

	tap_timer += delta

	# tekan spasi (HARUS CEPET)
	if Input.is_action_just_pressed("stabilize"):
		bar.value += tap_boost
		tap_timer = 0.0

	# kalau telat nekan → turun cepat
	if tap_timer > tap_window:
		bar.value -= decay_speed * delta * 1.6

	bar.value = clamp(bar.value, 0, 100)

	
	if bar.value < 30:
		fill_style.bg_color = Color(0.9, 0.2, 0.2) # merah
	elif bar.value < 60:
		fill_style.bg_color = Color(1.0, 0.8, 0.2) # kuning
	else:
		fill_style.bg_color = Color(0.3, 0.8, 0.3) # hijau


	# === DPS SAAT BAR HABIS ===
	if bar.value <= 0:
		dps_timer += delta
		if dps_timer >= dps_interval:
			dps_timer = 0.0
			GameState.decision_points = max(
				GameState.decision_points - 1,
				0
			)
	else:
		dps_timer = 0.0
