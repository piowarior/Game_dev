extends Node2D

@export_enum("tanah", "beton") var material_type := "tanah"

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

	var tool := str(current_player.get_current_item())

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
	print("HAS VICTIM:", has_victim)
	print("VICTIM SCENE:", victim_pile_scene)

	if has_victim and victim_pile_scene:
		print("SPAWN VICTIM")
		var victim = victim_pile_scene.instantiate()
		victim.global_position = global_position
		get_tree().current_scene.add_child(victim)

	queue_free()


# ------------------------------------------------
func _on_body_entered(body):
	if body.has_method("get_current_item"):
		player_in_range = true
		current_player = body

func _on_body_exited(body):
	if body == current_player:
		player_in_range = false
		current_player = null
		dig_progress = 0
