extends CharacterBody3D

@export var bounce_velocity: float = 15.0
@export var gravity: float = 25.0
@export var move_speed: float = 6.0

@export var lanes: Array[float] = [-7.0, 0.0, 7.0]
@export var switch_speed: float = 15.0
@onready var spawner = $"../TileSpawning"
@export var speed: Vector3 = Vector3(0 ,1080, 0)

@export_group("Squash")
## How flat the ball gets on impact (0 = none, 0.5 = half height).
@export_range(0.0, 0.8) var squash_amount: float = 0.7
## Spring strength pulling the ball back to round. Higher = snappier wobble.
@export var squash_stiffness: float = 250.0
## Lower = more jelly.
@export var squash_damping: float = 4.0

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var _mesh_base_y: float = mesh.position.y
@onready var _mesh_half_height: float = mesh.get_aabb().size.y * 0.5

var _squash: float = 0.0 # > 0 flattened, < 0 stretched, 0 round
var _squash_velocity: float = 0.0



var current_lane: int = 1 # 0 = Left, 1 = Center, 2 = Right



func _ready() -> void:
	add_to_group("player")
	print("added to player group")


func _physics_process(delta: float) -> void:

	velocity.y -= gravity * delta
	rotation_degrees += speed * delta


	global_position.x = lerpf(global_position.x, lanes[current_lane], switch_speed * delta)


	move_and_slide()

	# 4 Bounce on collision
	if is_on_floor():
		velocity.y = bounce_velocity
		_squash = squash_amount
		_squash_velocity = 0.0
		if not spawner.started:
			spawner.started = true

	_update_squash(delta)


func _update_squash(delta: float) -> void:
	# Damped spring back to round; the overshoot gives the stretch after the squash.
	_squash_velocity += (-squash_stiffness * _squash - squash_damping * _squash_velocity) * delta
	_squash = clampf(_squash + _squash_velocity * delta, -0.5, 0.8)

	var y_scale := 1.0 - _squash
	var xz_scale := 1.0 / sqrt(y_scale) # keep the volume constant
	mesh.scale = Vector3(xz_scale, y_scale, xz_scale)
	# Keep the bottom of the ball planted while it deforms.
	mesh.position.y = _mesh_base_y - _mesh_half_height * _squash


func _input(event: InputEvent) -> void:
	
		if event.is_action_pressed("ui_left"):
			if current_lane != 0:
				current_lane -= 1
			print("Switched to lane: ", current_lane)
		elif event.is_action_pressed("ui_right"):
			if current_lane != 2:
				current_lane += 1
	
	


func _on_death_plane_body_entered(body: Node3D) -> void:
	get_tree().reload_current_scene()
