extends CharacterBody2D

@onready var sprite = $AnimatedSprite2D
@onready var hand_item = $HandItem
@export var map_type := "basecamp"

# -----------------
# AUDIO
# -----------------
@export var run_sound: AudioStream
@export var tool_sound: AudioStream
@onready var audio_run: AudioStreamPlayer2D = $AudioPlayer_Run
@onready var audio_tool: AudioStreamPlayer2D = $AudioPlayer_Tool

# --------- PARAMETER GAME ----------
var speed = 200
var last_direction = "South"
var is_digging := false

# Ukuran MAP (Disesuaikan otomatis di _limit)
var screen_width  = 1280
var screen_height = 720
var map_width  = 5800
var map_height = 1050

var min_x = 0
var min_y = 0
var max_x = map_width  - screen_width
var max_y = map_height - screen_height

var base_scale := Vector2.ONE
var last_item_in_hand = ""
var dig_tool := "" 
var input_locked := false

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
        # Gunakan syntax Godot 4 yang lebih modern
        hotbar.get_node("Bar").item_changed.connect(_on_hotbar_item_changed)

# --------------------------------------------------------
# PROCESS (Logic UI TAB Sudah Dihapus dari sini)
# --------------------------------------------------------
func _process(delta):
    if input_locked:
        return

    _apply_perspective_scale()
    _update_hand_item()

# --------------------------------------------------------
# PHYSICS
# --------------------------------------------------------
func _physics_process(delta):
    if input_locked:
        velocity = Vector2.ZERO
        move_and_slide()
        return
        
    _handle_dig()

    if is_digging:
        velocity = Vector2.ZERO
        move_and_slide()
        return

    _move_player(delta)
    _limit_player_position()

# --------------------------------------------------------
# Sisanya Tetap Sama (Dig System, Move Player, dll)
# --------------------------------------------------------
func _handle_dig():
    var current_item = GameState.current_item
    if current_item != "Sekop" and current_item != "Pickaxe":
        if is_digging:
            is_digging = false
            sprite.animation = "Idle_%s" % last_direction
            sprite.play()
            if audio_tool.playing: audio_tool.stop()
        return

    dig_tool = current_item

    if Input.is_action_pressed("dig"):
        if not is_digging:
            is_digging = true
            velocity = Vector2.ZERO
            var dig_anim = "Dig_%s" % last_direction
            if sprite.animation != dig_anim:
                sprite.animation = dig_anim
                sprite.play()
            if tool_sound and not audio_tool.playing:
                audio_tool.stream = tool_sound
                audio_tool.play()
    else:
        if is_digging:
            is_digging = false
            sprite.animation = "Idle_%s" % last_direction
            sprite.play()
            if audio_tool.playing: audio_tool.stop()

func _move_player(delta):
    var input_vector = Vector2.ZERO
    var target_animation = ""
    var vertical_speed_factor = 1.0
    if map_type == "gempa": vertical_speed_factor = 0.5

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
        if not audio_run.playing:
            audio_run.stream = run_sound
            audio_run.play()
    else:
        if audio_run.playing: audio_run.stop()

    velocity = input_vector * speed
    move_and_slide()

func _update_hand_item():
    var current = GameState.current_item
    if current == null or current == "" or current == last_item_in_hand:
        if current == "" and hand_item.texture != null:
            hand_item.texture = null
            last_item_in_hand = ""
        return
    last_item_in_hand = current
    var data = GameState.get_item_data(current)
    if data != null:
        hand_item.texture = data.icon
        hand_item.scale = Vector2(0.05, 0.05)
    else:
        hand_item.texture = null

func _on_hotbar_item_changed(item_name):
    last_item_in_hand = item_name
    var data = GameState.get_item_data(item_name)
    if data != null:
        hand_item.texture = data.icon
        hand_item.scale = Vector2(0.05, 0.05)
    else:
        hand_item.texture = null

func _limit_player_position():
    global_position.x = clamp(global_position.x, min_x, max_x)
    global_position.y = clamp(global_position.y, min_y, max_y)

func _apply_perspective_scale():
    var y = global_position.y
    var top_limit = 30 if map_type != "gempa" else 130
    var bottom_limit = 180 if map_type != "gempa" else 280
    var min_s = 0.75 if map_type != "gempa" else 0.65
    var max_s = 1.15 if map_type != "gempa" else 1.2
    
    var t = clamp((y - top_limit) / float(bottom_limit - top_limit), 0.0, 1.0)
    var scale_factor = lerp(min_s, max_s, t)
    scale = base_scale * scale_factor
