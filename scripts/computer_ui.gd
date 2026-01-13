extends CanvasLayer

@onready var panel = $Panel
@onready var label_mission = $Panel/ScrollContainer/LabelMission
@onready var close_btn = $Panel/CloseButton
@onready var typing_sound = $TypingSound
@onready var audio_open = $AudioOpen   # efek buka UI
@onready var audio_close = $AudioClose # efek tutup UI

var typing_speed := 0.02
var show_cursor := true
var is_typing := false
var cancel_typing := false
var is_open := false

func _ready():
	panel.visible = false
	label_mission.text = ""
	close_btn.pressed.connect(_on_close_pressed)

# ===============================
# PUBLIC: buka UI
# ===============================
func open_ui():
	if is_typing or is_open:
		return  # cegah double open

	is_open = true
	panel.visible = true
	panel.modulate.a = 0
	panel.scale = Vector2(0.95, 0.95)

	# Tween muncul panel
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 1, 0.2)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.2)

	# Mainkan efek buka
	if audio_open:
		audio_open.play()

	label_mission.text = ""
	cancel_typing = false
	show_cursor = true

	await _type_text(_build_mission_text())

# ===============================
# TYPEWRITER EFFECT
# ===============================
func _type_text(full_text: String) -> void:
	is_typing = true
	typing_sound.play()

	for i in full_text.length():
		if cancel_typing:
			break

		label_mission.text = full_text.substr(0, i + 1)

		if show_cursor:
			label_mission.text += "[color=lime]_[/color]"

		await get_tree().create_timer(typing_speed).timeout
		label_mission.scroll_to_line(label_mission.get_line_count())

	typing_sound.stop()
	show_cursor = false
	is_typing = false

# ===============================
# BUILD TEXT
# ===============================
func _build_mission_text() -> String:
	var mission = GameState.current_mission
	if mission.is_empty():
		return "[color=gray]>> SYSTEM\nTidak ada data transmisi.[/color]"

	var text := ""
	text += "[center][b][color=lime]--- DATA TRANSMISI RESCUE ---[/color][/b][/center]\n"
	
	# Bagian Korban
	text += "\n[color=cyan][b]Daftar Korban Terdeteksi:[/b][/color]\n"
	for k in mission.korban:
		var status_color = "orange"
		if "tidak diketahui" in k.status: status_color = "red"
		
		text += "• [b]%s[/b]\n" % k.type.to_upper()
		text += "  [color=gray]Status:[/color] [color=%s]%s[/color]\n" % [status_color, k.status]
		text += "  [color=yellow]Tindakan:[/color] [i]%s[/i]\n" % k.task
		text += "[color=#333333]-----------------------------[/color]\n"

	# Bagian Waktu (Konversi ke Menit)
	var minutes = int(mission.time_limit / 60)
	var seconds = int(mission.time_limit) % 60
	text += "\n[color=cyan][b]Estimasi Waktu Aman:[/b][/color]\n"
	text += "- [color=yellow]%d Menit %d Detik[/color]\n" % [minutes, seconds]

	# Bagian Poin
	text += "\n[color=cyan][b]Decision Points:[/b][/color] [color=white]%d[/color]\n" % mission.decision_points
	text += "[i][color=red]*Kesalahan prosedur akan memotong poin ini.[/color][/i]\n"

	return text

# ===============================
# CLOSE UI
# ===============================
func close_ui():
	if not is_open:
		return

	is_open = false
	cancel_typing = true
	is_typing = false
	typing_sound.stop()
	label_mission.text = ""
	panel.visible = false

	# Mainkan efek tutup
	if audio_close:
		audio_close.play()

# ===============================
# CLOSE BUTTON
# ===============================
func _on_close_pressed():
	close_ui()
