extends CharacterBody2D

# =========================
# EXPORT
# =========================
@export var speed := 110
@export var rescue_point := 1
@export var dps := 5
@export var map_type := "gempa"   # gempa / basecamp

# =========================
# NODE
# =========================
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_markas: Area2D = $Area2D

# =========================
# STATE
# =========================
var target: Node2D
var victim_id := ""
var last_direction := "South"
var player_last_direction := "South"
var player: Node

# perspektif
var base_scale := Vector2.ONE

# =========================
# READY
# =========================
func _ready():
	player = get_tree().current_scene.get_node("CharacterBody2D")
	area_markas.body_entered.connect(_on_body_entered)

	if map_type == "basecamp":
		base_scale = Vector2(4, 4)
		speed = 200
	else:
		base_scale = Vector2(1.6, 1.6)
		speed = 120

	sprite.animation = "Idle_South"
	sprite.play()


# =========================
# PROCESS
# =========================
func _process(_delta):
	_apply_perspective_scale()

# =========================
# FOLLOW LOGIC
# =========================
func _physics_process(delta):
	if not target or not player:
		return

	# CEK PLAYER LAGI GERAK ATAU IDLE
	var player_anim: String = player.sprite.animation
	var player_is_idle := player_anim.begins_with("Idle")

	var dir := target.global_position - global_position
	var distance := dir.length()

	# 🟢 PLAYER IDLE → NPC IKUT IDLE
	if player_is_idle:
		velocity = Vector2.ZERO
		_play_idle()
		move_and_slide()
		return

	# 🔵 PLAYER GERAK → NPC FOLLOW
	if distance < 18:
		velocity = Vector2.ZERO
		_play_idle()
		move_and_slide()
		return

	dir = dir.normalized()
	velocity = dir * speed
	move_and_slide()

	_update_animation()



# =========================
# ANIMATION
# =========================
func _update_animation():
	if not player:
		return

	# AMBIL ARAH PLAYER
	last_direction = player.last_direction

	var anim = "Run_%s" % last_direction
	if sprite.animation != anim:
		sprite.animation = anim
		sprite.play()


func _play_idle():
	var anim = "Idle_%s" % last_direction
	if sprite.animation != anim:
		sprite.animation = anim
		sprite.play()

# =========================
# BASECAMP
# =========================
func _on_body_entered(body):
	if body.name == "markas2":
		_arrived_at_basecamp()



func _arrived_at_basecamp():
	# Tambah korban
	GameState.victim_saved += rescue_point

	# Tambah DPS
	GameState.decision_points += dps

	print(
		"NPC sampai markas | Victim:",
		GameState.victim_saved,
		"| DPS:",
		GameState.decision_points
	)

	queue_free() # 🔥 NPC HILANG

# =========================
# PERSPEKTIF SCALE (SAMA DENGAN PLAYER)
# =========================
func _apply_perspective_scale():
	if map_type != "gempa":
		var min_scale = 0.75
		var max_scale = 1.15

		var y = global_position.y
		var top_limit = 30
		var bottom_limit = 180

		var t = clamp((y - top_limit) / float(bottom_limit - top_limit), 0.0, 1.0)
		var scale_factor = lerp(min_scale, max_scale, t)

		scale = base_scale * scale_factor
		return

	# MAP GEMPA
	var min_scale = 0.65
	var max_scale = 1.2

	var y = global_position.y
	var top_limit = 130
	var bottom_limit = 280

	var t = clamp((y - top_limit) / float(bottom_limit - top_limit), 0.0, 1.0)
	var scale_factor = lerp(min_scale, max_scale, t)

	scale = base_scale * scale_factor
