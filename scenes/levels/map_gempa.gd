extends Node2D

@export var victim_pile_scene: PackedScene

func _ready():
	restore_spawned_victims()

func restore_spawned_victims():
	for victim_id in GameState.spawned_victims.keys():

		if GameState.rescued_victims.has(victim_id):
			continue

		var data = GameState.spawned_victims[victim_id]

		if not data.has("scene"):
			push_error("Victim %s tidak punya scene!" % victim_id)
			continue

		var scene: PackedScene = load(data.scene)
		if scene == null:
			push_error("Gagal load scene: " + data.scene)
			continue

		var victim = scene.instantiate()
		victim.global_position = data.position
		victim.victim_id = victim_id
		add_child(victim)
