extends CanvasLayer

# ===============================
# HUD LABELS
# ===============================
@onready var label_timer  = $HUD/TopBarRoot/TimerBox/LabelTimer
@onready var label_victim = $HUD/TopBarRoot/VictimBox/LabelVictim
@onready var label_dps    = $HUD/TopBarRoot/DPSBox/LabelDPS

# ===============================
# BUTTONS
# ===============================
# Baris BtnPause dihapus karena nodenya sudah tidak ada di scene
@onready var btn_mission = $HUD/TopBarRoot/BtnMission

# ===============================
# PANELS (SUDAH ADA DI TREE)
# ===============================
@onready var mission_panel: CanvasLayer = $ComputerUI
@onready var pause_panel: CanvasLayer   = $PauseMenu

var _timer_accum := 0.0

# ===============================
# READY
# ===============================
func _ready():
	# UI awal mati
	mission_panel.visible = false
	pause_panel.visible = false

	# Koneksi sinyal BtnPause dihapus agar tidak Error
	btn_mission.pressed.connect(_on_mission_pressed)

	_update_hud()

# ===============================
# ESC HANDLER (PAUSE VIA KEYBOARD)
# ===============================
func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"): # Tombol ESC
		if pause_panel.visible or mission_panel.visible:
			_close_all_ui()
		else:
			_open_pause_menu()

# ===============================
# TIMER
# ===============================
func _process(delta):
	if get_tree().paused:
		return

	if GameState.time_left <= 0:
		return

	_timer_accum += delta
	if _timer_accum >= 1.0:
		_timer_accum = 0.0
		GameState.time_left -= 1
		_update_hud()

# ===============================
# HUD UPDATE
# ===============================
func _update_hud():
	label_timer.text = _format_time(GameState.time_left)

	if GameState.current_mission.has("total_victim"):
		label_victim.text = "%d / %d" % [
			GameState.victim_saved,
			GameState.current_mission.total_victim
		]
	else:
		label_victim.text = "0 / 0"

	label_dps.text = str(GameState.decision_points)

# ===============================
# PAUSE / MISSION LOGIC
# ===============================
func _open_pause_menu():
	get_tree().paused = true
	pause_panel.visible = true
	mission_panel.visible = false

func _open_mission():
	get_tree().paused = true
	mission_panel.visible = true
	pause_panel.visible = false

func _close_all_ui():
	get_tree().paused = false
	pause_panel.visible = false
	mission_panel.visible = false

# ===============================
# BUTTON ACTIONS
# ===============================
# Fungsi ini tetap dibiarkan agar jika suatu saat kamu 
# ingin memanggil pause dari kode lain, fungsinya masih ada.
func _on_pause_pressed():
	_open_pause_menu()

func _on_mission_pressed():
	_open_mission()

# ===============================
# UTIL
# ===============================
func _format_time(sec: int) -> String:
	var m := sec / 60
	var s := sec % 60
	return "%02d:%02d" % [m, s]
