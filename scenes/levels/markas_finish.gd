extends Node2D

@export var countdown_time := 5

@onready var finish_area: Area2D = $FinishArea
@onready var label: Label = $CanvasLayer/CountdownLabel
@onready var timer: Timer = $FinishTimer
@onready var sfx: AudioStreamPlayer = $AudioStreamPlayer

var countdown := 0
var player_inside := false

func _ready():
    label.visible = false
    timer.wait_time = 1.0
    timer.one_shot = false

    timer.timeout.connect(_on_timer_timeout)
    finish_area.body_entered.connect(_on_body_entered)
    finish_area.body_exited.connect(_on_body_exited)

# ------------------------------------------------
func _on_body_entered(body):
    if not body is CharacterBody2D:
        return

    player_inside = true
    countdown = countdown_time

    label.visible = true
    label.text = str(countdown)

    # 🔊 SOUND DIPUTAR SEKALI SAJA
    if sfx and not sfx.playing:
        sfx.play()

    timer.start()

# ------------------------------------------------
func _on_body_exited(body):
    if not body is CharacterBody2D:
        return

    player_inside = false
    timer.stop()
    label.visible = false

    # 🔥 STOP SOUND SAAT KELUAR AREA
    if sfx and sfx.playing:
        sfx.stop()

# ------------------------------------------------
func _on_timer_timeout():
    if not player_inside:
        return

    countdown -= 1

    if countdown > 0:
        label.text = str(countdown)
    else:
        timer.stop()
        label.text = "FINISH"
        _on_finish()

# ------------------------------------------------
func _on_finish():
    print("MISSION SELESAI")

    # Mengambil data bencana yang sedang dimainkan secara dinamis
    var current_disaster = GameState.disaster_selected
    var stars: int = GameState.finish_mission(current_disaster)

    # Simpan data untuk ditampilkan di ScoreScreen
    GameState.last_mission_stars = stars
    GameState.next_scene_path = "res://scenes/menus/ScoreScreen.tscn"

    # Pindah ke Loading Screen terlebih dahulu
    get_tree().change_scene_to_file("res://scenes/menus/LoadingScreen.tscn")
