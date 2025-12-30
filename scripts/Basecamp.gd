extends Control

func _on_mulai_button_pressed():
	match GameState.disaster_selected:
		"gempa":
			get_tree().change_scene_to_file("res://scenes/levels/Gempa/Map_Gempa.tscn")
		"banjir":
			get_tree().change_scene_to_file("res://scenes/levels/Banjir/Map_Banjir.tscn")
		"kebakaran":
			get_tree().change_scene_to_file("res://scenes/levels/Kebakaran/Map_Kebakaran.tscn")
