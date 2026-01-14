extends Control

@onready var bar: ProgressBar = $ProgressBar

var active := false
var decay_speed := 20.0
var recover_speed := 15.0

func start():
	active = true
	visible = true
	bar.value = 50

func stop():
	active = false
	visible = false

func _process(delta):
	if not active:
		return

	bar.value -= decay_speed * delta

	if Input.is_action_pressed("ui_accept"):
		bar.value += recover_speed * delta

	bar.value = clamp(bar.value, 0, 100)

	if bar.value <= 0:
		GameState.decision_points = max(
			GameState.decision_points - 5,
			0
		)
		bar.value = 30
