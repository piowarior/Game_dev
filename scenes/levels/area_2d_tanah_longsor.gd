extends Area2D

@export var push_force := 180.0
@export var dps := 3
@export var dps_interval := 2.0

var dps_timer := 0.0
var player_inside := false
var player_ref

func _physics_process(delta):
	if not player_inside: return
	
	# SERET PLAYER KE KIRI
	player_ref.velocity.x = -push_force
	
	dps_timer += delta
	if dps_timer >= dps_interval:
		dps_timer = 0.0
		GameState.decision_points = max(
			GameState.decision_points - dps,
			0
		)

# di Area2D/LandslideArea.gd
func _on_body_entered(body):
	if body.is_in_group("player"):
		body.velocity.x = -180  # keseret ke kiri
		GameState.decision_points = max(GameState.decision_points - 3, 0)

func _on_body_exited(body):
	# stop seret player
	pass
