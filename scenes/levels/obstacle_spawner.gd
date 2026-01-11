
extends Node2D

@export var stage_id := "gempa"

@onready var spawn_area: CollisionShape2D = $SpawnArea/CollisionShape2D
@onready var forbidden_areas := $ForbiddenAreas.get_children()
@export var min_distance := 48            # anti nimpa (semua diggable)
@export var victim_min_distance := 120    # khusus diggable yg ada victim

var used_positions: Array[Vector2] = []
var victim_positions: Array[Vector2] = []


@onready var obstacles := get_children().filter(func(c):
	return "obstacle_id" in c
)

func _is_in_forbidden_area(pos: Vector2) -> bool:
	for area in forbidden_areas:
		var cs: CollisionShape2D = area.get_node("CollisionShape2D")
		if cs == null:
			continue

		var rect_shape := cs.shape as RectangleShape2D
		if rect_shape == null:
			continue

		var size: Vector2 = rect_shape.extents * 2.0
		var rect := Rect2(
			cs.global_position - rect_shape.extents,
			size
		)

		if rect.has_point(pos):
			return true

	return false



func _ready():
	randomize_positions()

func randomize_positions():
	if GameState.obstacle_positions.has(stage_id):
		for obs in obstacles:
			if GameState.obstacle_positions[stage_id].has(obs.obstacle_id):
				obs.global_position = GameState.obstacle_positions[stage_id][obs.obstacle_id]
		return

	var data := {}
	used_positions.clear()
	victim_positions.clear()

	for obs in obstacles:
		var pos = _get_random_position(obs)
		obs.global_position = pos
		data[obs.obstacle_id] = pos

	GameState.obstacle_positions[stage_id] = data

func _get_random_position(obs) -> Vector2:
	var rect = spawn_area.shape.get_rect()

	for i in range(100):
		var pos = spawn_area.global_position + Vector2(
			randf_range(rect.position.x, rect.position.x + rect.size.x),
			randf_range(rect.position.y, rect.position.y + rect.size.y)
		)

		# 🚫 forbidden area
		if _is_in_forbidden_area(pos):
			continue

		var valid := true

		# ❌ semua diggable → gak boleh nimpa
		for p in used_positions:
			if p.distance_to(pos) < min_distance:
				valid = false
				break

		if not valid:
			continue

		# ❗ KHUSUS has_victim → harus berjauhan
		if obs.has_victim:
			for vp in victim_positions:
				if vp.distance_to(pos) < victim_min_distance:
					valid = false
					break

		if not valid:
			continue

		# ✅ POSISI VALID
		used_positions.append(pos)
		if obs.has_victim:
			victim_positions.append(pos)

		return pos

	push_warning("Gagal cari posisi valid untuk obstacle: %s" % obs.obstacle_id)
	return spawn_area.global_position





func start_new_mission():
	GameState.obstacle_positions.erase(stage_id)
	GameState.destroyed_obstacles.clear()
