extends Node2D

@export var rescue_closeup_scene: PackedScene
@export var rescue_profile: Dictionary


@onready var label: Label = $Label
@onready var area: Area2D = $Area2D

var player_in_range := false
var opened := false
var can_interact := false

func _ready():
	label.visible = false

	area.body_entered.connect(_on_enter)
	area.body_exited.connect(_on_exit)

	# Delay kecil supaya tidak auto kebuka
	await get_tree().create_timer(0.2).timeout
	can_interact = true


func _process(_delta):
	if opened or not can_interact:
		return

	if player_in_range and Input.is_action_just_pressed("interact"):
		print("Kunci F ditekan!")
		open_rescue()


func open_rescue():
	if rescue_closeup_scene == null:
		push_error("WAJIB: Masukkan scene RescueCloseUp di Inspector!")
		return

	opened = true

	var closeup = rescue_closeup_scene.instantiate()
	get_tree().root.add_child(closeup)

	# 🔑 INI KUNCI UTAMANYA
	if closeup.has_method("set_profile"):
		closeup.set_profile(rescue_profile)
	else:
		push_error("RescueCloseUp belum punya set_profile()")
		return

	if closeup.has_signal("rescue_finished"):
		closeup.rescue_finished.connect(_on_rescue_finished)

	if closeup.has_method("open"):
		closeup.open()

	label.visible = false



func _on_rescue_finished():
	print("Rescue selesai → VictimPile dihapus")
	queue_free()


func _on_enter(body):
	if body is CharacterBody2D:
		player_in_range = true
		if not opened:
			label.visible = true
			print("Player mendekat")


func _on_exit(body):
	if body is CharacterBody2D:
		player_in_range = false
		label.visible = false
		print("Player menjauh")
