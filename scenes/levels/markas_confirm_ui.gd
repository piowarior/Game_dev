extends CanvasLayer

signal confirmed
signal cancelled

@onready var btn_yes = $Panel/BtnYes
@onready var btn_no = $Panel/BtnNo

func _ready():
	btn_yes.pressed.connect(_on_yes)
	btn_no.pressed.connect(_on_no)

# Di ConfirmBackToBase.gd
func _on_yes():
	emit_signal("confirmed")
	get_viewport().set_input_as_handled() # <--- Tambahkan ini
	queue_free()

func _on_no():
	emit_signal("cancelled")
	queue_free()
