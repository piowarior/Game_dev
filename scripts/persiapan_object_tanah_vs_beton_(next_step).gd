extends Node2D

@export_enum("tanah", "beton") var material_type := "tanah"

@export var obstacle_id: String
@export var tanah_sprites: Array[Texture2D]
@export var beton_sprites: Array[Texture2D]

@export var dig_time := 2.0

# 🔴 PENTING
@export var has_victim := false
@export var victim_pile_scene: PackedScene

@onready var sprite = $Sprite2D
@onready var area = $Area2D



var dig_progress := 0.0
var player_in_range := false
var current_player = null

# ------------------------------------------------
func _ready():
	if obstacle_id == "":
		push_error("Obstacle WAJIB punya obstacle_id!")
		return

	# Kalau sudah dihancurkan sebelumnya → langsung hapus
	if GameState.destroyed_obstacles.has(obstacle_id):
		queue_free()
		return
		

	_randomize_sprite()
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)


# ------------------------------------------------
func _randomize_sprite():
	if material_type == "tanah" and tanah_sprites.size() > 0:
		sprite.texture = tanah_sprites.pick_random()
	elif material_type == "beton" and beton_sprites.size() > 0:
		sprite.texture = beton_sprites.pick_random()

# ------------------------------------------------
func _process(delta):
	if not player_in_range:
		return
	if not current_player:
		return
	if not current_player.is_digging:
		dig_progress = 0
		return

	var tool := GameState.current_item

	# CEK ALAT
	if material_type == "tanah" and tool != "Sekop":
		return
	if material_type == "beton" and tool != "Pickaxe":
		return

	dig_progress += delta

	if dig_progress >= dig_time:
		_on_destroyed()

# ------------------------------------------------
func _on_destroyed():
	GameState.destroyed_obstacles[obstacle_id] = true

	if has_victim and victim_pile_scene:
		# 🔴 SIMPAN DATA SPAWN
		GameState.spawned_victims[obstacle_id] = {
		"position": global_position,
		"scene": victim_pile_scene.resource_path
		}

		var victim = victim_pile_scene.instantiate()
		victim.global_position = global_position
		victim.victim_id = obstacle_id
		get_tree().current_scene.add_child(victim)

	queue_free()

# ------------------------------------------------
func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		current_player = body

func _on_body_exited(body):
	if body == current_player:
		player_in_range = false
		current_player = null
		dig_progress = 0
