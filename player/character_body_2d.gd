extends CharacterBody2D

@onready var sprite = $AnimatedSprite2D
@onready var hand_item = $HandItem
@export var map_type := "basecamp"

# --------- PARAMETER GAME ----------
var speed = 200
var last_direction = "South"

# ===== DIG STATE =====
var is_digging := false

# Ukuran layar
var screen_width  = 1280
var screen_height = 720

# Ukuran MAP
var map_width  = 5800
var map_height = 1050

# Batas gerak
var min_x = 0
var min_y = 0
var max_x = map_width  - screen_width
var max_y = map_height - screen_height

# --------- PERSPEKTIF SCALE ----------
var base_scale := Vector2.ONE

# Item
var last_item_in_hand = ""

var dig_tool := ""   # "Sekop" atau "Pickaxe"

# --------------------------------------------------------
# READY
# --------------------------------------------------------
func _ready():
	sprite.animation = "Idle_South"
	sprite.play()


	if map_type == "basecamp":
		base_scale = Vector2(4, 4)
		speed = 200
	elif map_type == "gempa":
		base_scale = Vector2(1.6, 1.6)
		speed = 120

	var hotbar = get_tree().get_first_node_in_group("Hotbar")
	if hotbar:
		hotbar.get_node("Bar").connect(
			"item_changed",
			Callable(self, "_on_hotbar_item_changed")
		)

# --------------------------------------------------------
# PROCESS
# --------------------------------------------------------
func _process(delta):
	if Input.is_action_just_pressed("ui_tab"):
		var ui = get_tree().current_scene.get_node("BackpackUI")
		ui.toggle_ui()

	_apply_perspective_scale()
	_update_hand_item()

# --------------------------------------------------------
# PHYSICS
# --------------------------------------------------------
func _physics_process(delta):
	_handle_dig()

	# ⛔ saat DIG, player berhenti total
	if is_digging:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	_move_player(delta)
	_limit_player_position()

# --------------------------------------------------------
# 🪓 DIG SYSTEM (BARU)
# --------------------------------------------------------
func _handle_dig():
	var current_item = GameState.current_item

	# ❌ kalau tidak pegang sekop / pickaxe → tidak bisa dig
	if current_item != "Sekop" and current_item != "Pickaxe":
		if is_digging:
			is_digging = false
			sprite.animation = "Idle_%s" % last_direction
			sprite.play()
		return

	# Simpan alat yang dipakai
	dig_tool = current_item

	# 🟢 HOLD E → DIG
	if Input.is_action_pressed("dig"):
		if not is_digging:
			is_digging = true
			velocity = Vector2.ZERO

			var dig_anim = "Dig_%s" % last_direction
			if sprite.animation != dig_anim:
				sprite.animation = dig_anim
				sprite.play()
	else:
		# 🔴 LEPAS E → STOP DIG
		if is_digging:
			is_digging = false
			sprite.animation = "Idle_%s" % last_direction
			sprite.play()




# --------------------------------------------------------
# 🎮 GERAK PLAYER (ASLI, TIDAK DIHILANGKAN)
# --------------------------------------------------------
func _move_player(delta):
	var input_vector = Vector2.ZERO
	var target_animation = ""

	var vertical_speed_factor = 1.0
	if map_type == "gempa":
		vertical_speed_factor = 0.5

	if Input.is_action_pressed("ui_right"):
		input_vector.x += 1
		last_direction = "East"
		target_animation = "Run_East"
	elif Input.is_action_pressed("ui_left"):
		input_vector.x -= 1
		last_direction = "West"
		target_animation = "Run_West"

	if Input.is_action_pressed("ui_down"):
		input_vector.y += 1 * vertical_speed_factor
		last_direction = "South"
		target_animation = "Run_South"
	elif Input.is_action_pressed("ui_up"):
		input_vector.y -= 1 * vertical_speed_factor
		last_direction = "North"
		target_animation = "Run_North"

	if input_vector == Vector2.ZERO:
		target_animation = "Idle_%s" % last_direction

	if sprite.animation != target_animation:
		sprite.animation = target_animation
		sprite.play()

	if input_vector != Vector2.ZERO:
		input_vector = input_vector.normalized()

	velocity = input_vector * speed
	move_and_slide()

# --------------------------------------------------------
# 🔹 ITEM DI TANGAN (ASLI)
# --------------------------------------------------------
func _update_hand_item():
	var current = GameState.current_item

	if current == null or current == "":
		if hand_item.texture != null:
			hand_item.texture = null
			last_item_in_hand = ""
		return

	if current == last_item_in_hand:
		return

	last_item_in_hand = current
	var data = GameState.get_item_data(current)

	if data != null:
		hand_item.texture = data.icon
		hand_item.scale = Vector2(0.05, 0.05)
		hand_item.centered = true
	else:
		hand_item.texture = null

func get_current_item():
	return GameState.current_item

func _on_hotbar_item_changed(item_name):
	if item_name == last_item_in_hand:
		return

	last_item_in_hand = item_name
	var data = GameState.get_item_data(item_name)
	if data != null:
		hand_item.texture = data.icon
		hand_item.scale = Vector2(0.05, 0.05)
		hand_item.centered = true
	else:
		hand_item.texture = null

# --------------------------------------------------------
# ⛔ BATAS MAP
# --------------------------------------------------------
func _limit_player_position():
	global_position.x = clamp(global_position.x, min_x, max_x)
	global_position.y = clamp(global_position.y, min_y, max_y)

# --------------------------------------------------------
# 🎯 PERSPEKTIF SCALE (ASLI)
# --------------------------------------------------------
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

	var min_scale = 0.65
	var max_scale = 1.2

	var y = global_position.y
	var top_limit = 130
	var bottom_limit = 280

	var t = clamp((y - top_limit) / float(bottom_limit - top_limit), 0.0, 1.0)
	var scale_factor = lerp(min_scale, max_scale, t)

	scale = base_scale * scale_factor
