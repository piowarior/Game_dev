extends Area2D

@onready var interaction = $InteractionArea
@onready var label_f = $PressFLabel

var player_in_area = false

func _ready():
	label_f.visible = false
	interaction.body_entered.connect(_on_body_entered)
	interaction.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body is CharacterBody2D:
		player_in_area = true
		label_f.visible = true

func _on_body_exited(body):
	if body is CharacterBody2D:
		player_in_area = false
		label_f.visible = false

func _process(delta):
	if player_in_area and Input.is_action_just_pressed("interact"):
		label_f.visible = false
		open_equipment_menu()

func open_equipment_menu():
	var ui = get_tree().root.get_node("Basecamp/EquipmentUI")
	ui.open_equipment_menu()
