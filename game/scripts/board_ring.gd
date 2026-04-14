class_name BoardRing
extends RefCounted

var player_position: int = 0
var completed_lap: bool = false
var _tiles: Array[Tile] = []

func setup(count: int) -> void:
    _tiles.clear()
    completed_lap = false
    player_position = 0
    for i in range(count):
        var type := Tile.Type.NORMAL
        if i == 0:
            type = Tile.Type.START
        elif i % 7 == 0:
            type = Tile.Type.EVENT
        elif i % 11 == 0:
            type = Tile.Type.SURGE
        _tiles.append(Tile.new(i, type))

func tile_count() -> int:
    return _tiles.size()

func get_tile(index: int) -> Tile:
    return _tiles[index % _tiles.size()]

func move(steps: int) -> Array[int]:
    completed_lap = false
    var visited: Array[int] = []
    for i in range(steps):
        player_position = (player_position + 1) % _tiles.size()
        if player_position == 0:
            completed_lap = true
        visited.append(player_position)
    return visited

func split_move(first: int, second: int) -> Array[int]:
    completed_lap = false
    move(first)
    var stop_one := player_position
    move(second)
    var stop_two := player_position
    return [stop_one, stop_two]
