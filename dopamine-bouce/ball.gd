extends CharacterBody3D

@export var bounce_velocity: float = 15.0
@export var gravity: float = 25.0
@export var move_speed: float = 6.0

@export var lanes: Array[float] = [-7.0, 0.0, 7.0]
@export var switch_speed: float = 15.0
@onready var spawner = $"../TileSpawning"


var current_lane: int = 1 # 0 = Left, 1 = Center, 2 = Right



func _ready() -> void:
	add_to_group("player")
	print("added to player group")


func _physics_process(delta: float) -> void:

	velocity.y -= gravity * delta
	rotation.x += 12.0 * delta


	global_position.x = lerpf(global_position.x, lanes[current_lane], switch_speed * delta)


	move_and_slide()

	# 4 Bounce on collision
	if is_on_floor():
		velocity.y = bounce_velocity
		if not spawner.started:
			spawner.started = true


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
