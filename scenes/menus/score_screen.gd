extends Control

@onready var label_stars  = $Panel/LabelStars
@onready var label_score  = $Panel/LabelScore
@onready var label_detail = $Panel/LabelDetail
@onready var label_quote  = $Panel/LabelQuote
@onready var btn_continue = $Panel/ButtonContinue


var _score_target := 0


func _ready():
	_reset_ui()
	_prepare_data()
	_play_entry_animation()
	btn_continue.pressed.connect(_on_continue)


# ===============================
# DATA
# ===============================
func _prepare_data():
	var korban := GameState.victim_saved
	var dps := GameState.decision_points
	var time_left := GameState.time_left

	_score_target = (korban * 100) + (dps * 10) + int(time_left / 5)

	label_detail.text = \
		"Korban Diselamatkan: %d\n" % korban + \
		"DPS Tersisa: %d\n" % dps + \
		"Sisa Waktu: %ds" % time_left

	match GameState.last_mission_stars:
		3:
			label_quote.text = "Kepemimpinanmu menyelamatkan banyak nyawa."
			label_score.modulate = Color(0.4, 1, 0.4)
		2:
			label_quote.text = "Misi berhasil, namun efisiensi masih bisa ditingkatkan."
			label_score.modulate = Color(1, 0.9, 0.4)
		_:
			label_quote.text = "Setiap korban berarti. Terus asah keputusanmu."
			label_score.modulate = Color(1, 0.5, 0.5)


# ===============================
# ENTRY ANIMATION
# ===============================
func _play_entry_animation():
	await _animate_stars(GameState.last_mission_stars)
	await _animate_score()
	_animate_detail()
	await get_tree().create_timer(0.3).timeout
	_animate_quote()


# ===============================
# STAR ANIMATION (BENAR-BENAR SATU-SATU)
# ===============================
func _animate_stars(stars: int) -> void:
	label_stars.text = "☆☆☆"
	label_stars.scale = Vector2.ONE
	label_stars.rotation = 0

	for i in range(stars):
		await get_tree().create_timer(0.25).timeout

		var text := ""
		for j in range(3):
			text += "★" if j <= i else "☆"
		label_stars.text = text

		label_stars.scale = Vector2(1.6, 1.6)
		label_stars.rotation = deg_to_rad(-90)

		var tween := create_tween()
		tween.tween_property(label_stars, "scale", Vector2.ONE, 0.25)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(label_stars, "rotation", 0.0, 0.25)

		await tween.finished


# ===============================
# SCORE COUNT-UP (HALUS & POSISI AMAN)
# ===============================
func _animate_score():
	label_score.text = "Total Skor: 0"
	label_score.modulate.a = 0

	var tween := create_tween()
	tween.tween_property(label_score, "modulate:a", 1.0, 0.3)

	tween.tween_method(
		func(v):
			label_score.text = "Total Skor: %d" % int(v),
		0,
		_score_target,
		0.9
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	await tween.finished


# ===============================
# DETAIL SLIDE-IN
# ===============================
func _animate_detail():
	var tween := create_tween()
	tween.tween_property(label_detail, "modulate:a", 1.0, 0.3)

	tween.tween_property(
		label_detail,
		"position:x",
		label_detail.position.x + 160,
		0.4
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


# ===============================
# QUOTE POP
# ===============================
func _animate_quote():
	label_quote.scale = Vector2(0.85, 0.85)
	label_quote.modulate.a = 0

	var tween := create_tween()
	tween.tween_property(label_quote, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(
		label_quote,
		"scale",
		Vector2.ONE,
		0.4
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ===============================
# RESET
# ===============================
func _reset_ui():
	label_stars.text = "☆☆☆"

	label_score.modulate.a = 0
	label_detail.modulate.a = 0
	label_quote.modulate.a = 0

	label_detail.position.x -= 160


func _on_continue():
	get_tree().change_scene_to_file(
		"res://scenes/menus/main_menu.tscn"
	)
