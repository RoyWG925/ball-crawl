class_name BoardRingNode
extends Node2D

const TILE_COUNT := 24
const FIELD_W := 600.0
const FIELD_H := 500.0
const TILE_SIZE := 24.0
const OFFSET := 28.0  # gap between field edge and ring inner edge

const TILE_COLORS := {
    Tile.Type.NORMAL: Color("#1f2937"),
    Tile.Type.SURGE:  Color("#6366f1"),
    Tile.Type.EVENT:  Color("#a855f7"),
    Tile.Type.START:  Color("#22c55e"),
}
const PLAYER_COLOR := Color("#fbbf24")

# Distribution: 8 top, 4 right, 8 bottom, 4 left = 24
const TOP_COUNT    := 8
const RIGHT_COUNT  := 4
const BOTTOM_COUNT := 8
const LEFT_COUNT   := 4

var logic := BoardRing.new()
var _rects: Array[Rect2] = []

signal tile_landed(tile: Tile)
signal tile_passed(tile: Tile)
signal lap_completed

func _ready() -> void:
    logic.setup(TILE_COUNT)
    _build_rects()
    queue_redraw()

func _build_rects() -> void:
    _rects.clear()
    var top_step := (FIELD_W + OFFSET * 2) / TOP_COUNT
    for i in range(TOP_COUNT):
        _rects.append(Rect2(-OFFSET + i * top_step, -OFFSET - TILE_SIZE, TILE_SIZE, TILE_SIZE))
    var right_step := (FIELD_H + OFFSET * 2) / RIGHT_COUNT
    for i in range(RIGHT_COUNT):
        _rects.append(Rect2(FIELD_W + OFFSET - TILE_SIZE, -OFFSET + i * right_step, TILE_SIZE, TILE_SIZE))
    var bot_step := (FIELD_W + OFFSET * 2) / BOTTOM_COUNT
    for i in range(BOTTOM_COUNT):
        _rects.append(Rect2(FIELD_W + OFFSET - TILE_SIZE - i * bot_step, FIELD_H + OFFSET - TILE_SIZE, TILE_SIZE, TILE_SIZE))
    var left_step := (FIELD_H + OFFSET * 2) / LEFT_COUNT
    for i in range(LEFT_COUNT):
        _rects.append(Rect2(-OFFSET - TILE_SIZE, FIELD_H + OFFSET - TILE_SIZE - i * left_step, TILE_SIZE, TILE_SIZE))

func _draw() -> void:
    for i in range(_rects.size()):
        var tile := logic.get_tile(i)
        var col: Color = TILE_COLORS.get(tile.type, TILE_COLORS[Tile.Type.NORMAL])
        draw_rect(_rects[i], col)
        draw_rect(_rects[i], Color("#374151"), false, 1.0)
    if logic.player_position < _rects.size():
        draw_rect(_rects[logic.player_position].grow(-4), PLAYER_COLOR)

func move_player(steps: int) -> void:
    var visited := logic.move(steps)
    for idx in visited:
        tile_passed.emit(logic.get_tile(idx))
    tile_landed.emit(logic.get_tile(logic.player_position))
    if logic.completed_lap:
        lap_completed.emit()
    queue_redraw()

func split_move_player(first: int, second: int) -> void:
    var visited_a := logic.move(first)
    for idx in visited_a:
        tile_passed.emit(logic.get_tile(idx))
    tile_landed.emit(logic.get_tile(logic.player_position))
    var visited_b := logic.move(second)
    for idx in visited_b:
        tile_passed.emit(logic.get_tile(idx))
    tile_landed.emit(logic.get_tile(logic.player_position))
    if logic.completed_lap:
        lap_completed.emit()
    queue_redraw()
