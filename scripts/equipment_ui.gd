extends CanvasLayer

@onready var panel = $Panel
@onready var info = $Panel/InfoLabel
@onready var take_button = $Panel/TakeButton
@onready var close_button = $Panel/CloseButton
@onready var vbox = $Panel/ScrollContainer/VBoxContainer
@onready var audio_open = $AudioStreamPlayer_Open
@onready var audio_close = $AudioStreamPlayer_Close

const MAX_TAKE: int = 5
var selected_items: Array[String] = []

const CATEGORY_ORDER: Array = ["LIGHT", "EVAC", "MEDIC", "COMM", "SAFETY"]
const CATEGORY_LABEL: Dictionary = {
	"LIGHT": "🔦 PENERANGAN",
	"EVAC": "🧰 EVAKUASI",
	"MEDIC": "🩺 MEDIS",
	"COMM": "📣 KOMUNIKASI",
	"SAFETY": "🛡️ KEAMANAN"
}

func _ready() -> void:
	# awal panel hidden
	panel.visible = false
	
	# connect button dengan Godot 4.5 syntax
	take_button.pressed.connect(_on_take_pressed)
	close_button.pressed.connect(hide_menu)
	
	# ubah teks button via kode (opsional)
	take_button.text = "Ambil Alat"
	close_button.text = "Tutup"
	
# =========================
# Buka Equipment UI + sound
# =========================
func open_equipment_menu() -> void:
	audio_open.play()  # putar sound buka
	panel.visible = true
	selected_items = GameState.backpack.duplicate()
	_populate_items()

# =========================
# Atur tampilan slot alat
# =========================
func _update_slot_visual(slot_node: PanelContainer, is_selected: bool):
	var style = StyleBoxFlat.new()
	style.set_border_width_all(3)
	style.corner_radius_top_left = 10
	style.corner_radius_bottom_right = 10
	
	if is_selected:
		style.bg_color = Color(0.1, 0.6, 0.1, 0.7) # hijau
		style.border_color = Color(0.4, 1.0, 0.4, 1.0)
	else:
		style.bg_color = Color(0.1, 0.1, 0.1, 0.8) # gelap
		style.border_color = Color(0.3, 0.3, 0.3, 1.0)
		
	slot_node.add_theme_stylebox_override("panel", style)

# =========================
# Isi GridContainer dengan slot
# =========================
func _populate_items() -> void:
	for category in CATEGORY_ORDER:
		var container = vbox.find_child("CategoryContainer_" + category, true, false)
		if container == null:
			print("DEBUG: Tidak ketemu Container untuk kategori: ", category)
			continue
		
		# update label otomatis
		var index = container.get_index()
		if index > 0:
			var label_node = vbox.get_child(index - 1)
			if label_node is Label:
				label_node.text = CATEGORY_LABEL[category]
		
		# hapus slot lama
		for child in container.get_children():
			child.queue_free()
		
		# jarak antar kotak
		container.add_theme_constant_override("h_separation", 25)
		container.add_theme_constant_override("v_separation", 25)
		
		# isi slot dari database
		for name_key in GameState.item_database.keys():
			var data = GameState.item_database[name_key]
			if data.category != category:
				continue
			
			# slot kotak
			var slot = PanelContainer.new()
			slot.custom_minimum_size = Vector2(100,100)
			slot.set_meta("item_name", name_key)
			slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			
			# ikon
			var icon = TextureRect.new()
			icon.texture = data.icon
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size = Vector2(70,70)
			slot.add_child(icon)
			
			# koneksi klik (Godot 4.5)
			slot.gui_input.connect(func(event: InputEvent) -> void:
				_on_item_gui_input(event, slot)
			)
			
			_update_slot_visual(slot, selected_items.has(name_key))
			container.add_child(slot)

# =========================
# Klik kiri/kanan
# =========================
func _on_item_gui_input(event: InputEvent, slot: PanelContainer) -> void:
	if event is InputEventMouseButton and event.pressed:
		var item_name = slot.get_meta("item_name")
		if event.button_index == MOUSE_BUTTON_LEFT:
			_select_item(item_name, slot)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_deselect_item(item_name, slot)

# =========================
# Pilih / hapus alat
# =========================
func _select_item(item_name: String, slot: PanelContainer) -> void:
	if selected_items.has(item_name):
		_show_item_info(item_name)
		return
	
	if selected_items.size() >= MAX_TAKE:
		info.text = "Tas penuh! Lepas alat lain dulu ⚠️"
		return
	
	selected_items.append(item_name)
	_update_slot_visual(slot, true)
	_show_item_info(item_name)

func _deselect_item(item_name: String, slot: PanelContainer) -> void:
	if selected_items.has(item_name):
		selected_items.erase(item_name)
		_update_slot_visual(slot, false)
		_show_item_info(item_name)

# =========================
# Tampilkan info alat
# =========================
func _show_item_info(item_name: String) -> void:
	var data = GameState.get_item_data(item_name)
	if data == null: return
	info.text = "[b]%s[/b]\n%s\n\nKategori: %s" % [item_name, data.description, data.category]

# =========================
# Tutup Equipment UI + sound
# =========================
func hide_menu() -> void:
	audio_close.play()
	panel.visible = false

# =========================
# Take button
# =========================
func _on_take_pressed() -> void:
	if selected_items.size() < MAX_TAKE:
		info.text = "⚠️ Pilih minimal %d alat!" % MAX_TAKE
		return
	
	GameState.reset_backpack()
	for item in selected_items:
		GameState.add_item(item)
	if GameState.has_signal("backpack_changed"):
		GameState.emit_signal("backpack_changed")
	hide_menu()
