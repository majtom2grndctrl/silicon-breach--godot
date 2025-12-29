extends Node
class_name PlayerController

@export var walk_speed: float = 4.5
@export var sprint_speed: float = 7.0
@export var acceleration: float = 12.0
@export var deceleration: float = 18.0
@export var mouse_sensitivity: float = 0.0025
@export var min_pitch_deg: float = -35.0
@export var max_pitch_deg: float = 55.0
@export var capture_mouse: bool = true

@onready var body: CharacterBody3D = get_parent() as CharacterBody3D
@onready var camera_pivot: Node3D = body.get_node("CameraPivot") as Node3D

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _pitch_rad: float = 0.0

func _ready() -> void:
	if capture_mouse:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if body:
		body.floor_snap_length = 0.4
		body.floor_max_angle = deg_to_rad(45.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and body and camera_pivot:
		body.rotate_y(-event.relative.x * mouse_sensitivity)
		_pitch_rad = clamp(
			_pitch_rad - event.relative.y * mouse_sensitivity,
			deg_to_rad(min_pitch_deg),
			deg_to_rad(max_pitch_deg)
		)
		camera_pivot.rotation.x = _pitch_rad

func _physics_process(delta: float) -> void:
	if body == null:
		return
	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Vector3(input_vector.x, 0.0, input_vector.y)
	if direction.length_squared() > 0.0:
		direction = (body.global_transform.basis * direction).normalized()
	var target_speed := walk_speed
	if Input.is_action_pressed("sprint"):
		target_speed = sprint_speed
	var target_velocity := direction * target_speed
	var current_velocity := body.velocity
	var accel := acceleration if direction.length_squared() > 0.0 else deceleration
	current_velocity.x = move_toward(current_velocity.x, target_velocity.x, accel * delta)
	current_velocity.z = move_toward(current_velocity.z, target_velocity.z, accel * delta)
	if not body.is_on_floor():
		current_velocity.y -= _gravity * delta
	else:
		current_velocity.y = 0.0
	body.velocity = current_velocity
	body.move_and_slide()
