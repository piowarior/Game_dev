extends Control

func _on_gempa_button_pressed():
	GameState.disaster_selected = "gempa"
	GameState.start_mission("gempa") # ← INI YANG KURANG
	get_tree().change_scene_to_file("res://scenes/menus/Basecamp.tscn")

func _on_banjir_button_pressed():
	GameState.disaster_selected = "banjir"
	GameState.start_mission("banjir")
	get_tree().change_scene_to_file("res://scenes/menus/Basecamp.tscn")

func _on_kebakaran_button_pressed():
	GameState.disaster_selected = "kebakaran"
	GameState.start_mission("kebakaran")
	get_tree().change_scene_to_file("res://scenes/menus/Basecamp.tscn")
