extends CanvasLayer

@onready var panel = $Panel
@onready var list = $Panel/ItemList
@onready var info = $Panel/InfoLabel
@onready var take_button = $Panel/TakeButton
@onready var close_button = $Panel/CloseButton

const MAX_TAKE: int = 5

var selected_items: Array[String] = []

# =========================
# URUTAN KATEGORI & LABEL
# =========================
const CATEGORY_ORDER: Array = [
	"LIGHT",
	"EVAC",
	"MEDIC",
	"COMM",
	"SAFETY"
]

const CATEGORY_LABEL: Dictionary = {
	"LIGHT": "🔦 PENERANGAN",
	"EVAC": "🧰 EVAKUASI",
	"MEDIC": "🩺 MEDIS",
	"COMM": "📣 KOMUNIKASI",
	"SAFETY": "🛡️ KEAMANAN"
}

# =========================
# READY
# =========================
func _ready() -> void:
	panel.visible = false

	list.item_clicked.connect(_on_item_clicked)
	take_button.pressed.connect(_on_take_pressed)
	close_button.pressed.connect(hide_menu)

	_setup_itemlist()
	load_items()

# =========================
# ITEMLIST SETUP
# =========================
func _setup_itemlist() -> void:
	list.fixed_icon_size = Vector2(64, 64)
	list.same_column_width = true
	list.icon_mode = ItemList.ICON_MODE_TOP
	list.max_columns = 5
	list.select_mode = ItemList.SELECT_SINGLE

# =========================
# LOAD + SORT ITEM
# =========================
func load_items() -> void:
	list.clear()

	for category in CATEGORY_ORDER:
		# HEADER
		list.add_item(CATEGORY_LABEL[category])
		var header_index: int = list.item_count - 1
		list.set_item_selectable(header_index, false)
		list.set_item_disabled(header_index, true)
		list.set_item_custom_fg_color(header_index, Color.YELLOW)

		# ITEM DALAM KATEGORI
		for name_key in GameState.item_database.keys():
			var data = GameState.get_item_data(name_key)
			if data.category != category:
				continue

			list.add_item(name_key, data.icon)
			var item_index: int = list.item_count - 1
			list.set_item_custom_fg_color(item_index, Color.WHITE)
			list.set_item_icon_modulate(item_index, Color(1,1,1,1)) # putih normal

# =========================
# OPEN MENU
# =========================
func open_equipment_menu() -> void:
	panel.visible = true

	selected_items = GameState.backpack.duplicate()

	# RESET WARNA ITEM
	for i in range(list.item_count):
		if list.is_item_selectable(i):
			list.set_item_custom_fg_color(i, Color.WHITE)
			list.set_item_icon_modulate(i, Color(1,1,1,1))

	# TANDA ITEM LAMA
	for i in range(list.item_count):
		if not list.is_item_selectable(i):
			continue

		var item_name: String = list.get_item_text(i)
		if selected_items.has(item_name):
			list.set_item_custom_fg_color(i, Color.GREEN)
			list.set_item_icon_modulate(i, Color(0,1,0,1)) # hijau icon

	info.text = "Pilih tepat %d alat. Klik kanan untuk melepas." % MAX_TAKE

# =========================
# ITEM CLICK
# =========================
func _on_item_clicked(index: int, _pos: Vector2, button: int) -> void:
	if not list.is_item_selectable(index):
		return

	var name: String = list.get_item_text(index)
	show_item_info(name)

	if button == MOUSE_BUTTON_LEFT:
		if selected_items.has(name):
			return

		if selected_items.size() >= MAX_TAKE:
			info.text = "Backpack penuh. Lepas alat lama dulu ⚠️"
			return

		selected_items.append(name)
		list.set_item_custom_fg_color(index, Color.GREEN)
		list.set_item_icon_modulate(index, Color(0,1,0,1)) # hijau icon

	elif button == MOUSE_BUTTON_RIGHT:
		if selected_items.has(name):
			selected_items.erase(name)
			list.set_item_custom_fg_color(index, Color.WHITE)
			list.set_item_icon_modulate(index, Color(1,1,1,1)) # reset icon

# =========================
# INFO LABEL
# =========================
func show_item_info(name: String) -> void:
	var data = GameState.get_item_data(name)
	if data == null:
		return

	var text: String = "[b]%s[/b]\n" % name
	text += "%s\n\n" % data.description
	text += "Kategori: %s\n" % data.category
	text += "Digunakan: %s\n" % ", ".join(data.usage_context)

	info.text = text

# =========================
# HIDE MENU
# =========================
func hide_menu() -> void:
	panel.visible = false

# =========================
# TAKE BUTTON
# =========================
func _on_take_pressed() -> void:
	if selected_items.size() < MAX_TAKE:
		info.text = "⚠️ Harus memilih %d alat (%d dipilih)." % [MAX_TAKE, selected_items.size()]
		return

	GameState.reset_backpack()
	for item in selected_items:
		GameState.add_item(item)
		
	GameState.emit_signal("backpack_changed")

	print("Backpack final:", GameState.backpack)
	hide_menu()
