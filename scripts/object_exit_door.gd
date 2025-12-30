extends Node2D

@onready var interaction_area = $ExitArea/InteractionArea
@onready var press_label = $ExitArea/PressLabel
@onready var ui_confirm = $"../ExitConfirmUI"

var player_in_area = false

func _ready():
	press_label.visible = false
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.name == "CharacterBody2D":
		player_in_area = true
		press_label.visible = true

func _on_body_exited(body):
	if body.name == "CharacterBody2D":
		player_in_area = false
		press_label.visible = false

func _process(delta):
	if player_in_area and Input.is_action_just_pressed("interact"):
		ui_confirm.visible = true
		press_label.visible = false
