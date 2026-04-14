class_name Ball
extends RigidBody2D

const DAMAGE := 1

# Tune these in the Inspector at runtime
@export var launch_force: float = 800.0
@export var settle_threshold: float = 40.0   # px/s below which settle timer starts
@export var settle_delay: float = 0.4         # seconds to confirm settle
@export var max_flight_time: float = 6.0      # force settle after this many seconds
@export var settled_damp: float = 1.0         # linear_damp after settling

var is_launched: bool = false
var is_settled: bool = false
var _settle_timer: float = 0.0
var _flight_timer: float = 0.0
var _drag_start: Vector2 = Vector2.ZERO
var _is_dragging: bool = false

signal settled

@onready var trajectory: Line2D = $Trajectory

func _ready() -> void:
	freeze = true
	contact_monitor = true
	max_contacts_reported = 8
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body is Monster:
		body.take_damage(1)

func _input(event: InputEvent) -> void:
	if is_launched or is_settled:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_drag_start = get_global_mouse_position()
				_is_dragging = true
			elif _is_dragging:
				_launch()
				_is_dragging = false
	elif event is InputEventMouseMotion and _is_dragging:
		_draw_trajectory()

func _physics_process(delta: float) -> void:
	if not is_launched or is_settled:
		return
	_flight_timer += delta
	if _flight_timer >= max_flight_time:
		_do_settle()
		return
	if linear_velocity.length() < settle_threshold:
		_settle_timer += delta
		if _settle_timer >= settle_delay:
			_do_settle()
	else:
		_settle_timer = 0.0

func _launch() -> void:
	var mouse_pos := get_global_mouse_position()
	var dir := (_drag_start - mouse_pos).normalized()
	if dir.length() < 0.1:
		return
	trajectory.clear_points()
	freeze = false
	is_launched = true
	linear_velocity = dir * launch_force

func _draw_trajectory() -> void:
	var mouse_pos := get_global_mouse_position()
	var dir := (_drag_start - mouse_pos).normalized()
	trajectory.clear_points()
	var p := global_position
	var v := dir * launch_force
	for i in range(25):
		trajectory.add_point(to_local(p))
		p += v * 0.016

func _do_settle() -> void:
	is_settled = true
	linear_damp = settled_damp
	linear_velocity = Vector2.ZERO
	trajectory.clear_points()
	settled.emit()
