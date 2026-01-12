extends Control

# --- Load Resource (Ganti path sesuai lokasi scene Anda) ---
const OPTIONS_PANEL_SCENE = preload("res://scenes/menus/option_panel.tscn") 
const STAGE_SELECT_SCENE = preload("res://scenes/menus/stage_select.tscn") 

# --- DATA STAGE (Progress Pemain) ---
# Data: {"id": ID, "name": Nama, "unlocked": Status Kunci, "stars": Bintang Didapat, "path": Scene Level}
var STAGE_DATA = [
	{"id": 1, "name": "Stage 1: Gempa Bumi", "unlocked": true, "stars": 3, "path": "res://scenes/stage_1.tscn"},
	{"id": 2, "name": "Stage 2", "unlocked": false, "stars": 0, "path": "res://scenes/stage_2.tscn"},
	{"id": 3, "name": "Stage 3", "unlocked": false, "stars": 0, "path": "res://scenes/stage_3.tscn"}
]
# --------------------

# Referensi node (Asumsi nama node di main_menu.tscn adalah ini)
@onready var loading_panel = $LoadingPanel
@onready var loading_bar = $LoadingPanel/LoadingBar
@onready var loading_label = $LoadingPanel/LoadingLabel
@onready var menu_container = $MenuContainer
@onready var menu_background = $MenuBackground 
@onready var loading_timer = $LoadingTimer
# --- INTEGRASI AUDIO SFX ---
@onready var background_music_player = $BackgroundMusicPlayer
@onready var click_sfx_player = $ClickSFX
# ---------------------------

var loading_dots := 0


# --- FUNGSI GLOBAL SFX ---
func play_click_sfx():
	if is_instance_valid(click_sfx_player):
		click_sfx_player.stop()
		click_sfx_player.play()
# -------------------------


var loading_progress := 0
var loading_speed := 1 # per tick (1%)

func _ready():
	menu_container.visible = false
	if menu_background:
		menu_background.visible = false

	loading_panel.visible = true
	loading_bar.value = 0
	loading_label.text = "Loading"

	loading_timer.wait_time = 0.04
	loading_timer.timeout.connect(_on_loading_tick)
	loading_timer.start()

func _on_loading_tick():
	# animasi titik
	loading_dots = (loading_dots + 1) % 4
	loading_label.text = "Loading" + ".".repeat(loading_dots)

	# progress bar tetap jalan tapi TIDAK ditampilkan di label
	loading_progress += loading_speed
	loading_progress = min(loading_progress, 100)
	loading_bar.value = loading_progress

	if loading_progress >= 100:
		loading_timer.stop()
		_on_loading_finished()


# --- FUNGSI TRANSISI ANIMASI ---

func _on_loading_finished():
	
	menu_container.visible = true
	menu_container.modulate = Color(1, 1, 1, 0) 
	
	if menu_background:
		menu_background.visible = true
		menu_background.modulate = Color(1, 1, 1, 0)
	
	var transition_tween = create_tween()
	var duration = 0.5 

	transition_tween.parallel()
	transition_tween.tween_property(menu_container, "modulate", Color(1, 1, 1, 1), duration)
	
	if menu_background:
		transition_tween.parallel()
		transition_tween.tween_property(menu_background, "modulate", Color(1, 1, 1, 1), duration)

	transition_tween.parallel()
	transition_tween.tween_property(loading_panel, "modulate", Color(1, 1, 1, 0), duration)
	
	transition_tween.finished.connect(_on_transition_tween_finished)


func _on_transition_tween_finished():
	loading_panel.visible = false
	loading_panel.modulate = Color(1, 1, 1, 1)


# --- Sinyal Tombol ---

func _on_start_button_pressed():
	play_click_sfx()

	var stage_select_instance = STAGE_SELECT_SCENE.instantiate()
	add_child(stage_select_instance)
	menu_container.visible = false

	if stage_select_instance.has_method("initialize_stages"):
		stage_select_instance.initialize_stages(GameState.stage_data)


func _on_option_button_pressed():
	play_click_sfx() 
	var options_panel_instance = OPTIONS_PANEL_SCENE.instantiate()
	add_child(options_panel_instance)
	menu_container.visible = false 

func _on_exit_button_pressed():
	play_click_sfx() 
	get_tree().quit()
