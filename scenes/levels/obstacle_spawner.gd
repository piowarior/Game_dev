
extends Node2D

@export var stage_id := "gempa"

@onready var spawn_area: CollisionShape2D = $SpawnArea/CollisionShape2D
@onready var forbidden_areas := $ForbiddenAreas.get_children()

@onready var obstacles := get_children().filter(func(c):
	return "obstacle_id" in c
)

func _is_in_forbidden_area(pos: Vector2) -> bool:
	for area in forbidden_areas:
		var shape = area.get_node("CollisionShape2D").shape
		var rect = shape.get_rect()
		var global_rect = Rect2(
			area.global_position + rect.position,
			rect.size
		)
		if global_rect.has_point(pos):
			return true
	return false


func _ready():
	randomize_positions()

func randomize_positions():
	# 🔁 kalau sudah pernah random → pakai posisi lama
	if GameState.obstacle_positions.has(stage_id):
		for obs in obstacles:
			if GameState.obstacle_positions[stage_id].has(obs.obstacle_id):
				obs.global_position = GameState.obstacle_positions[stage_id][obs.obstacle_id]
		return

	# 🎲 random pertama kali
	var data := {}

	for obs in obstacles:
		var pos = _get_random_position()
		obs.global_position = pos
		data[obs.obstacle_id] = pos

	# 💾 simpan
	GameState.obstacle_positions[stage_id] = data


func _get_random_position() -> Vector2:
	var rect = spawn_area.shape.get_rect()
	
	for i in range(30): # 🔁 max attempt
		var x = randf_range(rect.position.x, rect.position.x + rect.size.x)
		var y = randf_range(rect.position.y, rect.position.y + rect.size.y)
		var pos = spawn_area.global_position + Vector2(x, y)

		if not _is_in_forbidden_area(pos):
			return pos

	# fallback (kalau terlalu penuh)
	return spawn_area.global_position



func start_new_mission():
	GameState.obstacle_positions.erase(stage_id)
	GameState.destroyed_obstacles.clear()
