extends Node

enum {
	IDLE,
	WARNING,
	QUAKE_ACTIVE,
	FINISHED
}

var state = IDLE

@export var warning_duration := 2.0
@export var quake_duration := 10.0
@export var penalty_interval := 3.0
@export var dps_penalty := 2

@export var bar_target_offset := 120.0 # seberapa nyepit

var quake_timer := 0.0
var penalty_timer := 0.0

@onready var top_bar: ColorRect = $"../ScreenOverlay/TopBar"
@onready var bottom_bar: ColorRect = $"../ScreenOverlay/BottomBar"
@onready var warning_audio := $"../Audio_Warning"
@onready var quake_audio := $"../Audio_Quake"

var event_time := 0
var event_triggered := false
var mission_total_time := 0

var top_start_y := 0.0
var bottom_start_y := 0.0

func _ready():
	# === AMAN DARI NULL ===
	if not top_bar or not bottom_bar:
		push_error("TopBar / BottomBar tidak ditemukan!")
		return

	top_start_y = top_bar.position.y
	bottom_start_y = bottom_bar.position.y

	mission_total_time = GameState.time_left
	if mission_total_time <= 0:
		push_warning("Mission belum dimulai")
		return

	_schedule_event()

func _process(delta):
	if GameState.time_left <= 0:
		return

	_check_event_trigger()

	match state:
		WARNING:
			_update_warning(delta)
		QUAKE_ACTIVE:
			_update_quake(delta)

# =========================
# EVENT SCHEDULING
# =========================
func _schedule_event():
	var min_time = int(mission_total_time * 0.3)
	var max_time = int(mission_total_time * 0.6)
	event_time = randi_range(min_time, max_time)

func _check_event_trigger():
	if event_triggered:
		return

	var elapsed = mission_total_time - GameState.time_left
	if elapsed >= event_time:
		_start_warning()
		event_triggered = true

# =========================
# WARNING
# =========================
func _start_warning():
	state = WARNING
	quake_timer = 0.0

	if warning_audio:
		warning_audio.play()

func _update_warning(delta):
	quake_timer += delta
	var t = quake_timer / warning_duration

	top_bar.position.y = lerp(
		top_start_y,
		top_start_y + bar_target_offset,
		t
	)

	bottom_bar.position.y = lerp(
		bottom_start_y,
		bottom_start_y - bar_target_offset,
		t
	)

	if quake_timer >= warning_duration:
		_start_quake()

# =========================
# QUAKE
# =========================
func _start_quake():
	state = QUAKE_ACTIVE
	quake_timer = 0.0
	penalty_timer = 0.0

	if quake_audio:
		quake_audio.play()

func _update_quake(delta):
	quake_timer += delta
	penalty_timer += delta

	if penalty_timer >= penalty_interval:
		penalty_timer = 0.0
		_apply_penalty_if_needed()

	if quake_timer >= quake_duration:
		_end_quake()

# =========================
# PENALTY
# =========================
func _apply_penalty_if_needed():
	GameState.decision_points -= dps_penalty
	GameState.decision_points = max(GameState.decision_points, 0)

# =========================
# END
# =========================
func _end_quake():
	state = FINISHED

	if quake_audio:
		quake_audio.stop()

	top_bar.position.y = top_start_y
	bottom_bar.position.y = bottom_start_y
