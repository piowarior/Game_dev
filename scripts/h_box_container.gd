extends HBoxContainer

@onready var slots := get_children()
var current_selected_slot: int = -1

signal item_changed(item_name: String)

var selected_tool := ""

func select_tool(tool_name: String):
	selected_tool = tool_name
	emit_signal("item_changed", tool_name)

func _ready():
	slots = get_children()

	for i in range(slots.size()):
		var slot = slots[i]

		if slot is Control:
			slot.gui_input.connect(_on_slot_gui_input.bind(i))

			# ⬇️ PAKSA ICON ABAIKAN MOUSE
			if slot.has_node("Icon"):
				slot.get_node("Icon").mouse_filter = Control.MOUSE_FILTER_IGNORE

	GameState.backpack_changed.connect(refresh_hotbar)
	refresh_hotbar()


func _on_slot_gui_input(event: InputEvent, index: int):
	if event is InputEventMouseButton \
	and event.pressed \
	and event.button_index == MOUSE_BUTTON_LEFT:

		slot_clicked(index)

		# ⛔ HENTIKAN EVENT DI SINI
		accept_event()


# =========================
# SLOT DIKLIK KANAN (BATALKAN PILIHAN)
# =========================
func slot_unselected(index: int):
	# Jika item yang diklik kanan saat ini adalah item yang sedang dipilih,
	# kita batalkan pilihan tersebut (mengosongkan tangan).
	
	if current_selected_slot == index:
		# 1. Reset current_selected_slot ke -1
		current_selected_slot = -1
		
		# 2. Kosongkan item di GameState
		GameState.current_item = "" # Asumsikan string kosong menandakan tidak ada item
		emit_signal("item_changed", "")
		
		# 3. Hapus highlight
		_highlight_selected()
		
		print("Hotbar batalkan pilihan di slot:", index)
	else:
		# Opsional: Anda bisa memilih untuk mengosongkan tangan meskipun
		# slot yang diklik kanan bukan slot yang sedang terpilih.
		# Namun, berdasarkan permintaan, ini akan membatalkan *pilihan* jika *slot* saat ini yang diklik kanan.
		# Jika yang diklik kanan bukan slot yang dipilih, kita bisa biarkan saja.
		pass


# =========================
# UPDATE ICON HOTBAR
# =========================
func refresh_hotbar():
	var items = GameState.backpack

	for i in range(slots.size()):
		var slot = slots[i]
		var icon: TextureRect = slot.get_node("Icon")

		if i < items.size():
			var item_name: String = items[i]
			var item_data = GameState.get_item_data(item_name)

			if item_data:
				icon.texture = item_data.icon
				icon.expand = true
				icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		else:
			icon.texture = null

# =========================
# SLOT DIKLIK
# =========================
func slot_clicked(index: int):
	var items = GameState.backpack

	if index >= items.size():
		return

	current_selected_slot = index
	var item_name: String = items[index]

	GameState.current_item = item_name
	emit_signal("item_changed", item_name)

	_highlight_selected()

	print("Hotbar pilih:", item_name)

# =========================
# HIGHLIGHT SLOT TERPILIH
# =========================
func _highlight_selected():
	for i in range(slots.size()):
		var slot = slots[i]
		if i == current_selected_slot:
			slot.modulate = Color(1, 1, 1) # NORMAL
			slot.self_modulate = Color(0.5, 1, 0.5) # HIJAU
		else:
			slot.self_modulate = Color(1, 1, 1)
