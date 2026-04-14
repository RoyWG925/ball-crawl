extends GutTest

func test_monster_hp_initialized_to_max() -> void:
    var m := Monster.new()
    m.max_hp = 3
    m.hp = m.max_hp
    assert_eq(m.hp, 3)

func test_take_damage_reduces_hp() -> void:
    var m := Monster.new()
    m.max_hp = 3
    m.hp = 3
    m.take_damage(1)
    assert_eq(m.hp, 2)

func test_take_damage_clamps_at_zero() -> void:
    var m := Monster.new()
    m.max_hp = 3
    m.hp = 3
    m.take_damage(10)
    assert_eq(m.hp, 0)

func test_is_dead_returns_true_at_zero_hp() -> void:
    var m := Monster.new()
    m.max_hp = 3
    m.hp = 0
    assert_true(m.is_dead())

func test_is_dead_returns_false_above_zero() -> void:
    var m := Monster.new()
    m.max_hp = 3
    m.hp = 1
    assert_false(m.is_dead())
