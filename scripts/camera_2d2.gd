extends Camera2D

@export var target_path : NodePath
@export var map_type := "basecamp"
@export var follow_speed := 5.0

# --- PENYESUAIAN KAMERA UNTUK FOKUS KE ATAS DAN KANAN ---
# Nilai ini menentukan seberapa jauh kamera bergeser dari TARGET.
# Untuk menempatkan TARGET di pojok kiri bawah, kamera harus bergeser ke KANAN dan ATAS.
# Vector2(X, Y): X positif = Geser KANAN, Y negatif = Geser ATAS.
# Nilai yang lebih besar (misalnya 300, -200) akan membuat efek lebih dramatis.
@export var camera_offset := Vector2(250, -150) 

var target : Node2D

func _ready():
	target = get_node(target_path)
	enabled = true

	if target:
		global_position = target.global_position + camera_offset

	var map_name := get_tree().current_scene.name

	if map_name == "MapGempa":
		limit_left = -300
		limit_right = 4400
		limit_top = 0
		limit_bottom = 1050

	elif map_name == "MapTanahLongsor":
		limit_left = 0
		limit_right = 2750   # 👈 LEBIH KECIL
		limit_top = 0
		limit_bottom = 900

	else:
		limit_left = 0
		limit_right = 2000
		limit_top = 0
		limit_bottom = 1000


func _process(delta):
	if not target:
		return

	# 1. Hitung Posisi Target yang sudah diberi Offset
	# Ini adalah titik yang selalu ingin dicapai kamera.
	var target_position = target.global_position + camera_offset

	# 2. FOLLOW HALUS ke Posisi Target yang sudah bergeser
	# Karena kamera mengikuti target_position, target (player) akan selalu
	# berada di posisi layar relatif yang sama (yaitu: pojok kiri bawah).
	global_position = global_position.lerp(
		target_position,
		follow_speed * delta
	)
