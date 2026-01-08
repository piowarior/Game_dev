extends TextureButton

func _ready():
	# Menghubungkan klik tombol ke fungsi di bawah (Perbaikan Typo)
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)

func _on_pressed():
	# Mencari node PauseMenu di scene aktif (MapGempa atau Basecamp)
	var menu = get_tree().current_scene.find_child("PauseMenu", true, false)
	
	if menu:
		menu.toggle_pause()
		print("PauseMenu ditemukan di scene aktif.")
	else:
		# Pencarian cadangan jika hirarki sangat dalam
		var menu_root = get_tree().root.find_child("PauseMenu", true, false)
		if menu_root:
			menu_root.toggle_pause()
		else:
			print("Error: Node PauseMenu tidak ditemukan!")
