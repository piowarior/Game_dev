extends CharacterBody2D

@onready var sprite = $AnimatedSprite2D
@onready var area = $Area2D

@export var npc_name := "Korban"
@export var is_trapped := true

var player_near := false

func _ready():
	if is_trapped and sprite.sprite_frames.has_animation("Trapped"):
		sprite.play("Trapped")
	else:
		sprite.play("Idle")

	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)


func _on_body_entered(body):
	if body.name == "Player":
		player_near = true

func _on_body_exited(body):
	if body.name == "Player":
		player_near = false
