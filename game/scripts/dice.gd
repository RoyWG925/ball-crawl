class_name Dice
extends RefCounted

static func roll() -> Array[int]:
    return [randi_range(1, 6), randi_range(1, 6)]

static func combined(rolls: Array[int]) -> int:
    return rolls[0] + rolls[1]

static func split(rolls: Array[int]) -> Array[int]:
    return [rolls[0], rolls[1]]
