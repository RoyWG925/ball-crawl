class_name BallField
extends Node2D

const FIELD_WIDTH := 600.0
const FIELD_HEIGHT := 500.0
const MAX_MONSTERS := 10
const SPAWN_POSITIONS: Array[Vector2] = [
	Vector2(100, 100), Vector2(300, 80),  Vector2(500, 100),
	Vector2(150, 220), Vector2(450, 220), Vector2(300, 180),
]

var monsters: Array[Monster] = []
var balls: Array[Ball] = []

signal all_monsters_dead
signal ball_settled(ball: Ball)

@export var monster_scene: PackedScene
@export var ball_scene: PackedScene

func spawn_monsters(count: int) -> void:
	var to_spawn := min(count, SPAWN_POSITIONS.size())
	for i in range(to_spawn):
		var m: Monster = monster_scene.instantiate()
		m.position = SPAWN_POSITIONS[i]
		m.died.connect(_on_monster_died.bind(m))
		add_child(m)
		monsters.append(m)

func monster_count() -> int:
	return monsters.size()

func is_overflowed() -> bool:
	return monsters.size() >= MAX_MONSTERS

func spawn_ball_at_launcher() -> Ball:
	var b: Ball = ball_scene.instantiate()
	b.position = Vector2(FIELD_WIDTH / 2.0, FIELD_HEIGHT - 50.0)
	b.settled.connect(_on_ball_settled.bind(b))
	add_child(b)
	balls.append(b)
	return b

func _on_monster_died(m: Monster) -> void:
	monsters.erase(m)
	if monsters.is_empty():
		all_monsters_dead.emit()

func _on_ball_settled(b: Ball) -> void:
	ball_settled.emit(b)
