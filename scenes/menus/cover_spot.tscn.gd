extends Node2D

@export var hide_offset := Vector2.ZERO

@onready var sprite_empty: Sprite2D = $Sprite_Empty
@onready var sprite_hidden: Sprite2D = $Sprite_Hidden
@onready var area: Area2D = $Area2D_Detect
@onready var label_press: Label = $Label_PressF

var player: Node2D
var player_inside := false
var occupied := false

func _ready():
	sprite_hidden.visible = false
	label_press.visible = false

	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _process(_delta):
	if not player:
		return

	if player_inside and Input.is_action_just_pressed("interact"):
		if occupied:
			_exit_cover()
		else:
			_enter_cover()


func _on_body_entered(body):
	if body.is_in_group("player"):
		player = body
		player_inside = true
		label_press.visible = true
		_update_label()

func _on_body_exited(body):
	if body == player and not occupied:
		player_inside = false
		label_press.visible = false


func _enter_cover():
	occupied = true

	sprite_empty.visible = false
	sprite_hidden.visible = true

	player.visible = false
	player.set_physics_process(false)

	if player.has_node("CollisionShape2D"):
		player.get_node("CollisionShape2D").disabled = true

	GameState.player_in_cover = true
	_update_label()

func _exit_cover():
	occupied = false

	sprite_empty.visible = true
	sprite_hidden.visible = false

	player.visible = true
	player.set_physics_process(true)

	if player.has_node("CollisionShape2D"):
		player.get_node("CollisionShape2D").disabled = false

	GameState.player_in_cover = false
	_update_label()

func _update_label():
	if not player_inside:
		label_press.visible = false
		return

	label_press.visible = true

	if occupied:
		label_press.text = "Press F to Exit"
	else:
		label_press.text = "Press F to Hide"
