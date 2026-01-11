extends Node2D

@export var victim_pile_scene: PackedScene
@onready var bgm_player = $AudioStreamPlayer # Pastikan ada node AudioStreamPlayer di scene ini

func _ready():
	# 1. Jalankan Fade-In Musik saat map dimuat
	_play_bgm_fade_in()
	
	# 2. Kembalikan data korban yang sudah ada
	restore_spawned_victims()

# ===============================
# LOGIKA AUDIO FADE-IN
# ===============================
func _play_bgm_fade_in():
	if is_instance_valid(bgm_player):
		# Mulai dari sunyi (-80 dB)
		bgm_player.volume_db = -80
		bgm_player.play()
		
		# Buat transisi ke volume normal (0 dB) dalam 3 detik
		var tween = create_tween()
		tween.tween_property(bgm_player, "volume_db", 0.0, 3.0).set_trans(Tween.TRANS_SINE)
	else:
		push_warning("Peringatan: Node AudioStreamPlayer tidak ditemukan di Map Gempa!")

# ===============================
# LOGIKA RESTORE VICTIMS
# ===============================
func restore_spawned_victims():
	for victim_id in GameState.spawned_victims.keys():
		# Jika korban sudah diselamatkan, jangan dimunculkan lagi
		if GameState.rescued_victims.has(victim_id):
			continue

		var data = GameState.spawned_victims[victim_id]

		if not data.has("scene"):
			push_error("Victim %s tidak punya scene!" % victim_id)
			continue

		var scene: PackedScene = load(data.scene)
		if scene == null:
			push_error("Gagal load scene: " + data.scene)
			continue

		var victim = scene.instantiate()
		victim.global_position = data.position
		victim.victim_id = victim_id
		add_child(victim)
