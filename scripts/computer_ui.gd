extends CanvasLayer

# ===============================
# Nodes
# ===============================
@onready var panel = $Panel
@onready var label_mission = $Panel/ScrollContainer/LabelMission
@onready var close_btn = $Panel/CloseButton


# ===============================
# Godot lifecycle
# ===============================
func _ready():
	panel.visible = false

	if close_btn:
		close_btn.pressed.connect(_on_close_pressed)
	else:
		push_error("CloseButton tidak ditemukan di Computer UI")


# ===============================
# PUBLIC: buka UI misi
# ===============================
func open_ui():
	panel.visible = true
	_update_mission_text()


# ===============================
# Update isi misi (AMBIL DARI GAMESTATE)
# ===============================
func _update_mission_text():
	var mission = GameState.current_mission

	if mission.is_empty():
		label_mission.text = "Belum ada misi aktif."
		return

	var text := ""

	# ---------- JUDUL ----------
	text += "TARGET MISI\n"
	text += "-------------------------\n"

	# ---------- KORBAN ----------
	text += "Korban yang harus dievakuasi:\n"
	for k in mission.korban:
		text += "- %d %s (%s)\n" % [
			k.count,
			k.type.capitalize(),
			k.status
		]

	# ---------- WAKTU ----------
	text += "\nBatas Waktu:\n"
	text += "- %d detik\n" % mission.time_limit

	# ---------- DPS ----------
	text += "\nDecision Points (DPS):\n"
	text += "- Awal: %d poin\n" % mission.decision_points
	text += "- Salah tindakan akan mengurangi poin\n"

	label_mission.text = text


# ===============================
# Tutup UI
# ===============================
func _on_close_pressed():
	panel.visible = false
