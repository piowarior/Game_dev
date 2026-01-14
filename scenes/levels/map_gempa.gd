extends Node2D

@export var victim_pile_scene: PackedScene

@onready var bgm_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var camera: Camera2D = $Camera2D

@onready var top_bar: ColorRect = $ScreenOverlay/TopBar
@onready var bottom_bar: ColorRect = $ScreenOverlay/BottomBar

@onready var sfx_warning: AudioStreamPlayer = $Audio_Warning
@onready var sfx_quake: AudioStreamPlayer = $Audio_Quake
@onready var warning_logo: TextureRect = $ScreenOverlay/WarningLogo
@onready var info_label: Label = $ScreenOverlay/InfoLabel
@onready var stability_ui = $ScreenOverlay/StabilityUI




# ===============================
# SETTING EVENT
# ===============================
@export var warning_duration := 4.0
@export var quake_duration := 15.0
@export var shake_intensity := 6.0
@export var dps_penalty := 2
@export var penalty_interval := 2.5

@export var quake_volume := 6.0
@export var bgm_quake_volume := -18.0
@export var bgm_normal_volume := 0.0


@export var warning_zoom := Vector2(1.08, 1.08)


# ===============================
# STATE
# ===============================
var warning_blink_tween: Tween
var state := "idle"
var timer := 0.0
var penalty_timer := 0.0

# posisi overlay
var top_hidden_y := -750.0
var top_visible_y := -650.0
var bottom_hidden_y := 750.0
var bottom_visible_y := 700.0

var base_camera_offset := Vector2.ZERO
var base_camera_zoom := Vector2.ONE

# ===============================
# READY
# ===============================
func _ready():
	_play_bgm_fade_in()
	restore_spawned_victims()

	# Overlay init
	top_bar.visible = false
	bottom_bar.visible = false

	top_bar.position.y = top_hidden_y
	bottom_bar.position.y = bottom_hidden_y

	top_bar.color.a = 0.0
	bottom_bar.color.a = 0.0

	base_camera_offset = camera.offset
	base_camera_zoom = camera.zoom

	# tunggu pertengahan game
	await get_tree().create_timer(GameState.time_left * 0.4).timeout
	_start_warning()

func _process(delta):
	match state:
		"warning":
			_update_warning(delta)
		"quake":
			_update_quake(delta)

# ===============================
# WARNING
# ===============================
func _start_warning():
	state = "warning"
	timer = 0.0

	top_bar.visible = true
	bottom_bar.visible = true

	top_bar.position.y = top_hidden_y
	bottom_bar.position.y = bottom_hidden_y
	top_bar.color.a = 0.0
	bottom_bar.color.a = 0.0

	# === FIX ZOOM GLITCH ===
	camera.zoom = base_camera_zoom
	camera.set_notify_transform(false)
	
	# WARNING LOGO ANIM
	warning_logo.visible = true
	warning_logo.scale = Vector2.ZERO
	warning_logo.modulate.a = 0.0

	var logo_tween = create_tween()
	logo_tween.tween_property(
		warning_logo,
		"scale",
		Vector2.ONE,
		0.6
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	logo_tween.parallel().tween_property(
		warning_logo,
		"modulate:a",
		1.0,
		0.4
	)

	# === BLINK EFFECT (SETELAH SCALE SELESAI) ===
	logo_tween.finished.connect(func():
		if warning_blink_tween:
			warning_blink_tween.kill()

		warning_blink_tween = create_tween()
		warning_blink_tween.set_loops()
		warning_blink_tween.tween_property(
			warning_logo,
			"modulate:a",
			0.3,
			0.35
		)
		warning_blink_tween.tween_property(
			warning_logo,
			"modulate:a",
			1.0,
			0.35
		)
	)



	var zoom_tween = create_tween()
	zoom_tween.tween_property(
		camera,
		"zoom",
		warning_zoom,
		0.6
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	zoom_tween.finished.connect(func():
		camera.set_notify_transform(true)
	)

	if sfx_warning:
		sfx_warning.play()


func _update_warning(delta):
	timer += delta
	var t: float = clamp(timer / warning_duration, 0.0, 1.0)

	# overlay anim
	top_bar.position.y = lerp(top_hidden_y, top_visible_y, t)
	bottom_bar.position.y = lerp(bottom_hidden_y, bottom_visible_y, t)

	top_bar.color.a = t
	bottom_bar.color.a = t

	if timer >= warning_duration:
		_start_quake()

# ===============================
# GEMPA
# ===============================
func _start_quake():
	if GameState.player_in_cover:
		show_info("GEMPA SUSULAN!\nTEKAN SPASI UNTUK BERTAHAN")
	else:
		show_info("GEMPA SUSULAN!\nSEGERA MENUJU AREA COVER!")
		
	if GameState.player_in_cover:
		if not stability_ui.is_running:
			stability_ui.start()
	else:
		stability_ui.stop()



	
	state = "quake"
	timer = quake_duration
	penalty_timer = 0.0

	# STOP WARNING SOUND
	if sfx_warning and sfx_warning.playing:
		sfx_warning.stop()

	# BGM TURUN (ducking)
	if bgm_player:
		var bgm_down = create_tween()
		bgm_down.tween_property(
			bgm_player,
			"volume_db",
			bgm_quake_volume,
			0.6
		).set_trans(Tween.TRANS_SINE)

	# PLAY GEMPA SOUND (LOUD + LOOP)
	if sfx_quake:
		sfx_quake.volume_db = quake_volume
		sfx_quake.play()

	# ZOOM BALIK NORMAL
	var zoom_out = create_tween()
	zoom_out.tween_property(
		camera,
		"zoom",
		base_camera_zoom,
		0.4
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)



func _update_quake(delta):
	# sinkronisasi cover ↔ stability ui
	if GameState.player_in_cover:
		if not stability_ui.is_running:
			stability_ui.start()
	else:
		if stability_ui.is_running:
			stability_ui.stop()

	# camera shake
	camera.offset = base_camera_offset + Vector2(
		randf_range(-shake_intensity, shake_intensity),
		randf_range(-shake_intensity, shake_intensity)
	)

	# penalty logic tetap
	timer -= delta
	penalty_timer += delta

	if penalty_timer >= penalty_interval:
		penalty_timer = 0.0
		if not GameState.player_in_cover:
			GameState.decision_points = max(
				GameState.decision_points - dps_penalty,
				0
			)

	if timer <= 0:
		_end_quake()

		

func show_info(text: String):
	info_label.text = text
	info_label.visible = true
	info_label.modulate.a = 0.0

	var t = create_tween()
	t.tween_property(info_label, "modulate:a", 1.0, 0.3)

func hide_info():
	var t = create_tween()
	t.tween_property(info_label, "modulate:a", 0.0, 0.3)
	t.finished.connect(func():
		info_label.visible = false
	)


# ===============================
# SELESAI
# ===============================
func _end_quake():
	state = "idle"

	camera.offset = base_camera_offset

	var tween = create_tween()
	tween.tween_property(top_bar, "position:y", top_hidden_y, 0.5)
	tween.tween_property(bottom_bar, "position:y", bottom_hidden_y, 0.5)
	tween.parallel().tween_property(top_bar, "color:a", 0.0, 0.5)
	tween.parallel().tween_property(bottom_bar, "color:a", 0.0, 0.5)
	
	# STOP BLINK
	if warning_blink_tween:
		warning_blink_tween.kill()
		warning_blink_tween = null

	
	# HIDE WARNING LOGO
	if warning_logo.visible:
		var hide_logo = create_tween()
		hide_logo.tween_property(warning_logo, "scale", Vector2.ZERO, 0.4)
		hide_logo.parallel().tween_property(warning_logo, "modulate:a", 0.0, 0.3)
		hide_logo.finished.connect(func():
			warning_logo.visible = false
		)
	
	hide_info()
	stability_ui.stop()


	await tween.finished
	top_bar.visible = false
	bottom_bar.visible = false

	if sfx_quake:
		sfx_quake.stop()
		
	# BGM BALIK NORMAL
	if bgm_player:
		var bgm_up = create_tween()
		bgm_up.tween_property(
			bgm_player,
			"volume_db",
			bgm_normal_volume,
			1.0
		).set_trans(Tween.TRANS_SINE)


# ===============================
# === PUNYA KAMU (JANGAN DIUBAH)
# ===============================
func _play_bgm_fade_in():
	if is_instance_valid(bgm_player):
		bgm_player.volume_db = -80
		bgm_player.play()
		var tween = create_tween()
		tween.tween_property(
			bgm_player,
			"volume_db",
			0.0,
			3.0
		).set_trans(Tween.TRANS_SINE)

func restore_spawned_victims():
	for victim_id in GameState.spawned_victims.keys():
		if GameState.rescued_victims.has(victim_id):
			continue

		var data = GameState.spawned_victims[victim_id]
		if not data.has("scene"):
			continue

		var scene: PackedScene = load(data.scene)
		if scene == null:
			continue

		var victim = scene.instantiate()
		victim.global_position = data.position
		victim.victim_id = victim_id
		add_child(victim)
