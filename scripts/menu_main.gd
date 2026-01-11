extends Control

func _ready():
	# Sembunyikan tombol pause saat berada di menu utama
	if has_node("/root/PauseButton"):
		get_node("/root/PauseButton").hide()

func _on_play_button_pressed():
	# Pindah ke menu pemilihan level
	get_tree().change_scene_to_file("res://scenes/menus/LevelSelect.tscn")
