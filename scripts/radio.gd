extends Sprite2D

@onready var radio_sprite: Sprite2D = $RadioSprite
@onready var area: Area2D = $Area2D
@onready var audio: AudioStreamPlayer2D = $AudioStreamPlayer2D

# Audio fade
var target_volume = 0.0
var fade_speed = 2.0

# Shake / animasi
var shake_intensity = 2.0   # pixel
var shake_speed = 5.0      # frekuensi shake
var glow_timer = 0.0

# Posisi awal
var radio_initial_pos := Vector2.ZERO

func _ready():
	radio_initial_pos = radio_sprite.position
	
	# Audio
	audio.finished.connect(_on_audio_finished)
	audio.play()
	audio.volume_db = linear_to_db(0.0)
	target_volume = 0.0
	
	# Area detection
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _process(delta):
	# Audio fade
	var current_vol = db_to_linear(audio.volume_db)
	var new_vol = lerp(current_vol, target_volume, fade_speed * delta)
	audio.volume_db = linear_to_db(new_vol)
	
	# Radio animasi
	if target_volume > 0.0:
		# Shake halus
		var offset = Vector2(randf_range(-shake_intensity, shake_intensity),
							 randf_range(-shake_intensity, shake_intensity))
		radio_sprite.position = radio_initial_pos + offset
		
		# Glow LED (pulsing warna)
		glow_timer += delta * 3.0  # kecepatan pulse
		var glow = 0.5 + 0.5 * sin(glow_timer)
		radio_sprite.modulate = Color(1, 1, 1, 1) * (0.8 + 0.2 * glow)
	else:
		# Reset posisi & warna
		radio_sprite.position = radio_initial_pos
		radio_sprite.modulate = Color(1, 1, 1, 1)

func _on_audio_finished():
	audio.play()

func _on_body_entered(body):
	if body is CharacterBody2D:
		target_volume = 1.0

func _on_body_exited(body):
	if body is CharacterBody2D:
		target_volume = 0.0
