extends Area2D

@onready var interaction = $InteractionArea
@onready var press_label = $PressLabel

var player_in_area = false

func _ready():
	press_label.visible = false
	interaction.body_entered.connect(_on_body_entered)
	interaction.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body is CharacterBody2D:
		player_in_area = true
		press_label.visible = true

func _on_body_exited(body):
	if body is CharacterBody2D:
		player_in_area = false
		press_label.visible = false

func _process(delta):
	if player_in_area and Input.is_action_just_pressed("interact"): # F
		press_label.visible = false
		open_computer_ui()

func open_computer_ui():
	var ui = get_tree().root.get_node("Basecamp/ComputerUI")
	if ui:
		ui.open_ui()
	else:
		push_error("ComputerUI tidak ditemukan!")
	
