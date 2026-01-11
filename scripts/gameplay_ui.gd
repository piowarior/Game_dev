extends CanvasLayer

# ===============================
# HUD LABELS
# ===============================
@onready var label_timer  = $HUD/TopBarRoot/TimerBox/LabelTimer
@onready var label_victim = $HUD/TopBarRoot/VictimBox/LabelVictim
@onready var label_dps    = $HUD/TopBarRoot/DPSBox/LabelDPS

# ===============================
# BUTTONS & INTERACTABLES
# ===============================
@onready var btn_mission = $HUD/TopBarRoot/BtnMission
@onready var backpack_box = $HUD/TopBarRoot/Backpack

# ===============================
# PANELS
# ===============================
@onready var mission_panel: CanvasLayer = $ComputerUI
@onready var pause_panel: CanvasLayer   = $PauseMenu

var _timer_accum := 0.0

# ===============================
# READY
# ===============================
func _ready():
	# Agar UI tetap jalan saat game di-pause (Update dari Lokal)
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# UI awal mati (Update dari GitHub)
	mission_panel.visible = false
	pause_panel.visible = false

	# --- LOGIKA KLIK BACKPACK (Fitur Baru) ---
	if is_instance_valid(backpack_box):
		# Paksa box utama agar menangkap klik (Stop agar tidak tembus ke player)
		backpack_box.mouse_filter = Control.MOUSE_FILTER_STOP
		
		# Otomatis set semua anak agar mengabaikan klik supaya induknya yang menerima
		for child in backpack_box.get_children():
			if child is Control:
				child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Hubungkan sinyal klik backpack
		if not backpack_box.gui_input.is_connected(_on_backpack_gui_input):
			backpack_box.gui_input.connect(_on_backpack_gui_input)
	
	# Hubungkan tombol Misi (Perbaikan koneksi dari GitHub)
	if is_instance_valid(btn_mission):
		if not btn_mission.pressed.is_connected(_on_mission_pressed):
			btn_mission.pressed.connect(_on_mission_pressed)

	_update_hud()

# ===============================
# INPUT HANDLER (TAB & ESC)
# ===============================
func _unhandled_input(event):
	# Handle Tombol TAB (Buka Backpack)
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		get_viewport().set_input_as_handled()
		_toggle_backpack_ui()
	
	# Handle Tombol ESC (Pause/Close)
	if event.is_action_pressed("ui_cancel"): 
		if pause_panel.visible or mission_panel.visible:
			_close_all_ui()
		else:
			_open_pause_menu()

# ===============================
# BACKPACK CLICK LOGIC
# ===============================
func _on_backpack_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			print("DEBUG: Tombol Backpack diklik!") 
			backpack_box.accept_event() 
			_toggle_backpack_ui()

# ===============================
# CORE TOGGLE LOGIC
# ===============================
func _toggle_backpack_ui():
	var backpack_ui = get_parent().get_node_or_null("BackpackUI")
	
	if backpack_ui:
		if pause_panel.visible or mission_panel.visible:
			_close_all_ui()
		
		if backpack_ui.has_method("toggle_backpack"):
			backpack_ui.toggle_backpack()
		else:
			backpack_ui.visible = !backpack_ui.visible
	else:
		push_warning("BackpackUI tidak ditemukan di samping GameplayUi!")

# ===============================
# FUNGSI LAIN (TIMER, HUD, DLL)
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
func _on_pause_pressed():
	_open_pause_menu()

func _on_mission_pressed():
	_open_mission()

func _format_time(sec: int) -> String:
	var m := sec / 60
	var s := sec % 60
	return "%02d:%02d" % [m, s]
