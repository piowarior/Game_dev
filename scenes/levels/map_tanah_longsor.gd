extends Node2D

# =====================================================================
# SAR RESCUE - INTEGRATED MISSION LOGIC (MAP TANAH LONGSOR)
# =====================================================================

@export var victim_pile_scene: PackedScene
@export var next_scene_path: String = "res://scenes/menus/stage_select.tscn"
@export var main_menu_path: String = "res://scenes/menus/main_menu.tscn"

# ===============================
# NODE REFERENCES (SUDAH ADA)
# ===============================
@onready var bgm_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var camera: Camera2D = $Camera2D

@onready var top_bar: ColorRect = $ScreenOverlay/TopBar
@onready var bottom_bar: ColorRect = $ScreenOverlay/BottomBar
@onready var warning_logo: TextureRect = $ScreenOverlay/WarningLogo
@onready var info_label: Label = $ScreenOverlay/InfoLabel

@onready var sfx_warning: AudioStreamPlayer = $Audio_Warning
@onready var sfx_landslide: AudioStreamPlayer = $Audio_Landslide

# VISUAL TANAH LONGSOR (SPRITE / TEXTURE RECT)
@onready var landslide_sprite: Node2D = $LandslideVisual

# ===============================
# SETTING EVENT
# ===============================
@export var warning_duration := 4.0

@export var landslide_total_duration := 300.0 # 5 menit
@export var landslide_active_duration := 150.0 # 2:30 menit (bergerak sampai tengah)

@export var dps_penalty := 1
@export var dps_interval := 5.0

@export var shake_intensity := 4.0
@export var bgm_disaster_volume := -18.0
@export var bgm_normal_volume := 0.0

# POSISI MAP TANAH LONGSOR
@export var landslide_start_x := 2750.0
@export var landslide_end_x := 1375.0 # pertengahan map

# ===============================
# LANDSLIDE ANIMATION CEPAT SAAT WARNING
@export var landslide_intro_duration := 3.0 # durasi muncul dari ujung ke posisi kamera
var landslide_intro_timer := 0.0
var landslide_intro_active := false

# CAMERA LIMITS UNTUK LANDSLIDE
var camera_limit_start: float = 2750.0
var camera_limit_end: float = 1375.0


# ===============================
# STATE
# ===============================
var state := "idle" # idle | warning | landslide | finish

var timer := 0.0
var dps_timer := 0.0
var landslide_timer := 0.0

var base_camera_offset := Vector2.ZERO

var warning_blink_tween: Tween
var is_mission_complete := false

# ===============================
# READY
# ===============================
func _ready():
	# Memulai musik dan restore data
	_play_bgm_fade_in()
	restore_spawned_victims()
	base_camera_offset = camera.offset
	
	# INIT OVERLAY - Menyembunyikan UI di awal
	top_bar.visible = false
	bottom_bar.visible = false
	top_bar.color.a = 0.0
	bottom_bar.color.a = 0.0
	warning_logo.visible = false
	info_label.visible = false
	
	# INIT LANDSLIDE - Posisi awal landslide
	if is_instance_valid(landslide_sprite):
		landslide_sprite.visible = false
		landslide_sprite.global_position = Vector2(3118, 128)
	else:
		push_error("Node LandslideVisual TIDAK DITEMUKAN!")
	
	# Trigger warning otomatis berdasarkan sisa waktu di GameState
	await get_tree().create_timer(GameState.time_left * 0.4).timeout
	
	# Jalankan warning jika misi belum selesai
	if not is_mission_complete:
		_start_warning()


# ===============================
# PROCESS
# ===============================
func _process(delta):
	match state:
		"warning":
			_update_warning(delta)
		"landslide":
			_update_landslide(delta)

# =====================================================================
# WARNING SYSTEM
# =====================================================================
func _start_warning():
	state = "warning"
	timer = 0.0

	top_bar.visible = true
	bottom_bar.visible = true

	show_info("PERINGATAN!\nTANAH LONGSOR AKAN TERJADI")

	if sfx_warning:
		sfx_warning.play()

	# Panggil fungsi init warning + landslide
	_init_warning_and_landslide()

	
func _update_warning(delta: float) -> void:
	timer += delta
	var t: float = clamp(timer / warning_duration, 0.0, 1.0)

	top_bar.color.a = t
	bottom_bar.color.a = t

	# CAMERA SHAKE HALUS
	camera.offset = base_camera_offset + Vector2(
		randf_range(-1.5, 1.5),
		randf_range(-1.5, 1.5)
	)

	if timer >= warning_duration:
		_start_landslide()



# =====================================================================
# LANDSLIDE SYSTEM
# =====================================================================
func _start_landslide():
	state = "landslide"
	timer = landslide_total_duration
	dps_timer = 0.0
	landslide_timer = 0.0

	hide_warning_ui()  # UI overlay top/bottom bar fade out

	if is_instance_valid(landslide_sprite):
		landslide_sprite.visible = true
		var sprite = landslide_sprite.get_node_or_null("LandslideSprite") as Sprite2D
		if sprite:
			sprite.visible = true
			sprite.position = Vector2(0, 0)
			sprite.scale = Vector2(1.798, 1.875)
		# posisi sudah di (3118,108), tidak diubah
	else:
		push_error("Node LandslideVisual TIDAK DITEMUKAN!")
		return

	landslide_intro_active = false
	landslide_timer = 0.0

	camera.limit_right = camera_limit_start

	show_info("TANAH LONGSOR!\nSEGERA SELAMATKAN KORBAN")

	if sfx_landslide:
		sfx_landslide.play()

	if bgm_player:
		var tween = create_tween()
		tween.tween_property(
			bgm_player,
			"volume_db",
			bgm_disaster_volume,
			0.6
		)


func _update_landslide(delta: float) -> void:
	timer -= delta
	dps_timer += delta

	# Pastikan landslide_sprite ada sebelum diakses
	if is_instance_valid(landslide_sprite):
		# GERAK TANAH LONGSOR NORMAL
		landslide_timer += delta
		var t: float = clamp(landslide_timer / landslide_active_duration, 0.0, 1.0)
		landslide_sprite.global_position.x = lerp(3118.0, float(camera_limit_end), t)

		# shake sedikit pada sprite
		landslide_sprite.rotation = randf_range(-0.01, 0.01)
		
		# Update limit kamera mengikuti pergerakan longsor
		camera.limit_right = lerp(float(camera_limit_start), float(camera_limit_end), t)

	# camera shake (selalu jalan selama state landslide)
	camera.offset = base_camera_offset + Vector2(
		randf_range(-shake_intensity, shake_intensity),
		randf_range(-shake_intensity, shake_intensity)
	)

	# DPS system - Pengurangan poin berkala
	if dps_timer >= dps_interval:
		dps_timer = 0.0
		GameState.decision_points = max(GameState.decision_points - dps_penalty, 0)

	# Cek durasi selesai
	if timer <= 0:
		_end_landslide()



func _end_landslide():
	state = "idle"
	camera.offset = base_camera_offset

	if sfx_landslide:
		sfx_landslide.stop()

	if bgm_player:
		create_tween().tween_property(
			bgm_player,
			"volume_db",
			bgm_normal_volume,
			1.0
		)

	hide_info()

# =====================================================================
# UI HELPERS
# =====================================================================
func show_info(text: String):
	info_label.text = text
	info_label.visible = true
	info_label.modulate.a = 1.0

func hide_info():
	if not info_label.visible:
		return
	create_tween().tween_property(info_label, "modulate:a", 0.0, 0.3)\
		.finished.connect(func(): info_label.visible = false)

func hide_warning_ui():
	var tween = create_tween()
	tween.tween_property(top_bar, "color:a", 0.0, 0.4)
	tween.tween_property(bottom_bar, "color:a", 0.0, 0.4)
	# warning_logo tetap terlihat dan blink terus, jadi jangan sembunyikan di sini


# =====================================================================
# INIT WARNING & LANDSLIDE SETUP
# =====================================================================
func _init_warning_and_landslide():
	# -------------------------------
	# 1️⃣ Setup logo warning
	# -------------------------------
	warning_logo.visible = true
	warning_logo.scale = Vector2.ZERO
	warning_logo.modulate.a = 0.0

	var logo_tween = create_tween()
	logo_tween.tween_property(warning_logo, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	logo_tween.parallel().tween_property(warning_logo, "modulate:a", 1.0, 0.4)

	logo_tween.finished.connect(func():
		# WARNING BLINK LOOP TERUS (tidak berhenti sampai akhir event)
		if warning_blink_tween:
			warning_blink_tween.kill()
		warning_blink_tween = create_tween().set_loops()
		warning_blink_tween.tween_property(warning_logo, "modulate:a", 0.3, 0.4)
		warning_blink_tween.tween_property(warning_logo, "modulate:a", 1.0, 0.4
		)
	)

	# -------------------------------
	# 2️⃣ Setup landslide posisi awal saat warning
	# -------------------------------
	if is_instance_valid(landslide_sprite):
		landslide_sprite.visible = true
		var start_x = 3523.0  # posisi kanan luar layar
		var target_x = 3308.0
		var target_y = 108.0
		landslide_sprite.global_position = Vector2(start_x, target_y)

		# pastikan child sprite ikut posisi y
		var sprite = landslide_sprite.get_node_or_null("LandslideSprite") as Sprite2D
		if sprite:
			sprite.position.y = 0  # relatif ke parent
			sprite.visible = true

		var landslide_tween = create_tween()
		landslide_tween.tween_property(landslide_sprite, "global_position:x", target_x, warning_duration)
		landslide_tween.tween_property(landslide_sprite, "global_position:y", target_y, warning_duration)
		landslide_tween.tween_property(landslide_sprite, "rotation", randf_range(-0.03, 0.03), warning_duration)



# =====================================================================
# BGM & RESTORE
# =====================================================================
func _play_bgm_fade_in():
	if bgm_player:
		bgm_player.volume_db = -80
		bgm_player.play()
		create_tween().tween_property(
			bgm_player,
			"volume_db",
			0.0,
			3.0
		)

func restore_spawned_victims():
	for victim_id in GameState.spawned_victims.keys():
		if GameState.rescued_victims.has(victim_id):
			continue

		var data = GameState.spawned_victims[victim_id]
		if not data.has("scene"):
			continue

		var scene = load(data["scene"])
		if scene:
			var victim = scene.instantiate()
			# PENTING: ambil posisi dari dictionary, bukan properti
			if data.has("global_position"):
				victim.global_position = data["global_position"]
			# assign ID
			if victim.has_method("set_victim_id"): # kalau ada setter
				victim.set_victim_id(victim_id)
			else:
				victim.victim_id = victim_id
			add_child(victim)
