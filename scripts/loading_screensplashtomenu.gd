extends Control

# =====================
# CONFIG
# =====================
@export var loading_time := 8.0

# =====================
# NODE
# =====================
@onready var bg: Sprite2D = $BackgroundLayer/Background
@onready var tip: Label = $UI/TipLabel
@onready var bar: ProgressBar = $UI/LoadingBar
@onready var spinner: TextureRect = $UI/Spinner
@onready var timer_bg: Timer = $ChangeTimer

# =====================
# DATA
# =====================
var bg_textures := [
	preload("res://assets/loading/loading 1.png"),
	preload("res://assets/loading/loading 2.png"),
	preload("res://assets/loading/loading 3.png"),
	preload("res://assets/loading/loading 4.png"),
	preload("res://assets/loading/loading 5.png"),
	preload("res://assets/loading/loading 6.png"),
	preload("res://assets/loading/loading 7.png"),
	preload("res://assets/loading/loading 8.png"),
	preload("res://assets/loading/loading 9.png"),
	preload("res://assets/loading/loading 10.png"),
	preload("res://assets/loading/loading 11.png"),
]

var tips := [
	"Setiap detik bisa menentukan hidup atau mati.",
	"Jangan asal bergerak. Amati situasi sebelum mengambil keputusan.",
	"Alat yang tepat di waktu yang tepat bisa menyelamatkan lebih banyak korban.",
	"Terkadang mundur satu langkah jauh lebih baik daripada memaksa maju.",
	"Koordinasi tim bukan pilihan, tapi kebutuhan utama di lapangan.",
	"Kesalahan kecil di awal misi dapat berdampak besar di akhir.",
	"Jika kondisi terlalu berbahaya, evakuasi adalah keputusan paling bijak.",
	"Jangan abaikan lingkungan sekitar, bahaya sering datang dari arah tak terduga.",
	"Manajemen waktu yang buruk bisa membuat misi gagal meski strategi sudah benar.",
	"Tenang di situasi genting adalah keahlian paling sulit, tapi paling penting.",
	"Tidak semua misi harus diselesaikan dengan cepat — keselamatan tetap nomor satu.",
	"Setiap area memiliki risiko berbeda, pelajari sebelum bertindak.",
	"Keputusan cepat tanpa perhitungan sering berakhir dengan penyesalan.",
	"Pemimpin yang baik tahu kapan harus maju, dan kapan harus menarik tim.",
	"Satu nyawa yang diselamatkan lebih berharga daripada misi yang sempurna."
]

# =====================
# STATE
# =====================
var elapsed := 0.0

# =====================
# READY
# =====================
func _ready():
	GameState.next_scene_path = "res://scenes/menus/main_menu.tscn"

	randomize()
	_set_random_content()
	timer_bg.timeout.connect(_change_background)
	bar.value = 0

# =====================
# PROCESS
# =====================
func _process(delta):
	elapsed += delta
	bar.value = (elapsed / loading_time) * 100

	if spinner:
		spinner.rotation += delta * 3.0

	if elapsed >= loading_time:
		_finish_loading()

# =====================
# BACKGROUND
# =====================
func _change_background():
	_set_random_content()

func _set_random_content():
	bg.texture = bg_textures.pick_random()
	tip.text = tips.pick_random()
	_fit_background()

# =====================
# AUTO FIT BACKGROUND
# =====================
func _fit_background():
	if bg.texture == null:
		return

	# ukuran REAL dari Control, bukan viewport mentah
	var screen_size = size
	var tex_size = bg.texture.get_size()

	var scale_factor = max(
		screen_size.x / tex_size.x,
		screen_size.y / tex_size.y
	)

	bg.scale = Vector2.ONE * scale_factor
	bg.position = screen_size / 2


# =====================
# FINISH
# =====================
func _finish_loading():
	if has_node("/root/GameState") and GameState.next_scene_path != "":
		get_tree().change_scene_to_file(GameState.next_scene_path)  # .tscn
	else:
		print("ERROR: next_scene_path belum diset")
