extends Node2D

@export var rescue_closeup_scene: PackedScene
@export var rescue_profile: Dictionary
@export var victim_id: String
@export_enum("SADAR", "PINGSAN") var condition := "SADAR"

@export var follow_npc_scene: PackedScene
@onready var label: Label = $Label
@onready var area: Area2D = $Area2D

var saved_layer_index := 0
var saved_stage := "EVAC"


var player_in_range := false
var opened := false
var can_interact := false

func _ready():
	if victim_id == "":
		push_error("Victim WAJIB punya victim_id!")
		return

	# Kalau sudah diselamatkan → hapus
	if GameState.rescued_victims.has(victim_id):
		queue_free()
		return

	label.visible = false
	area.body_entered.connect(_on_enter)
	area.body_exited.connect(_on_exit)

	# Restore rescue state
	if GameState.victim_rescue_state.has(victim_id):
		var data = GameState.victim_rescue_state[victim_id]
		saved_stage = data.stage
		saved_layer_index = data.layer

	await get_tree().create_timer(0.2).timeout
	can_interact = true
	
	await get_tree().process_frame
	restore_visual_state()




func _process(_delta):
	if opened or not can_interact:
		return

	if player_in_range and Input.is_action_just_pressed("interact"):
		open_rescue()



func open_rescue():
	if rescue_closeup_scene == null:
		push_error("WAJIB: Masukkan scene RescueCloseUp di Inspector!")
		return

	opened = true   # 🔑 KUNCI: tandai sedang dibuka

	var closeup = rescue_closeup_scene.instantiate()
	get_tree().root.add_child(closeup)

	# Kirim data layer
	if closeup.has_method("set_profile"):
		closeup.set_profile(rescue_profile)

	# Jika rescue selesai total → hapus victim
	if closeup.has_signal("rescue_finished"):
		closeup.rescue_finished.connect(_on_rescue_finished)

	# Jika rescue dibatalkan (EXIT) → bisa lanjut lagi
	if closeup.has_signal("rescue_aborted"):
		closeup.rescue_aborted.connect(_on_rescue_aborted)
		
	if closeup.has_method("set_resume_state"):
		closeup.set_resume_state(saved_stage, saved_layer_index)
		
	if closeup.has_method("set_victim_id"):
		closeup.set_victim_id(victim_id)


	if closeup.has_method("open"):
		closeup.open()

	label.visible = false


func _on_rescue_aborted(stage, layer_index):
	saved_stage = stage
	saved_layer_index = layer_index

	GameState.victim_rescue_state[victim_id] = {
		"stage": stage,
		"layer": layer_index
	}

	opened = false
	restore_visual_state()

	# 🔥 INI YANG HILANG
	if player_in_range:
		label.visible = true

func restore_visual_state():
	if not GameState.victim_rescue_state.has(victim_id):
		return

	var data = GameState.victim_rescue_state[victim_id]
	saved_stage = data.stage
	saved_layer_index = data.layer

	# 🔥 tampilkan kembali visual korban tertimbun
	if has_node("Sprite2D"):
		$Sprite2D.visible = true

	if has_node("Label"):
		label.visible = player_in_range

func give_instant_reward():
	var victim_point := 1
	var dps_point := 3

	GameState.victim_saved += victim_point
	GameState.decision_points += dps_point

	# 🔊 SOUND REWARD
	if has_node("SFXPlayer"):
		$SFXPlayer.play()

	# 🎉 ANIMASI DARI SPAWNPOIN
	spawn_local_floating_text(
		"+" + str(victim_point) + " Korban",
		Color.WHITE,
		-1.0
	)

	spawn_local_floating_text(
		"+" + str(dps_point) + " DPS",
		Color.YELLOW,
		1.0
	)



func _on_rescue_finished():
	GameState.rescued_victims[victim_id] = true
	GameState.victim_rescue_state.erase(victim_id)
	GameState.spawned_victims.erase(victim_id)

	if condition == "SADAR":
		# 🔹 SADAR → NPC FOLLOW → REWARD DI MARKAS
		spawn_follow_npc()
	else:
		# 🔥 PINGSAN → REWARD LANGSUNG
		give_instant_reward()

	queue_free()


func spawn_follow_npc():
	if follow_npc_scene == null:
		push_error("Follow NPC scene belum diisi!")
		return

	var npc = follow_npc_scene.instantiate()
	npc.global_position = global_position
	npc.victim_id = victim_id

	# 🔥 INI WAJIB
	npc.target = get_tree().current_scene.get_node("CharacterBody2D")

	get_tree().current_scene.add_child(npc)
	

func spawn_local_floating_text(text: String, color: Color, side: float):
	var lbl = Label.new()
	lbl.text = text
	lbl.modulate = color
	lbl.set_as_top_level(true)
	get_tree().current_scene.add_child(lbl)

	var start_pos = global_position
	if has_node("SpawnPoin"):
		start_pos = $SpawnPoin.global_position

	lbl.global_position = start_pos
	lbl.scale = Vector2.ZERO

	var tween = create_tween().set_parallel(true)

	tween.tween_property(lbl, "scale", Vector2(1.2, 1.2), 0.2)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.tween_property(lbl, "global_position:y", start_pos.y - 80, 0.6)
	tween.tween_property(lbl, "global_position:x", start_pos.x + (side * 40), 0.6)

	tween.tween_property(lbl, "modulate:a", 0.0, 0.3).set_delay(0.6)
	tween.chain().tween_callback(lbl.queue_free)




func _on_enter(body):
	if body is CharacterBody2D:
		player_in_range = true
		if not opened and can_interact:
			restore_visual_state()


func _on_exit(body):
	if body is CharacterBody2D:
		player_in_range = false
		label.visible = false
