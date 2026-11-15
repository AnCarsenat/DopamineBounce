extends Node3D

@onready var bounceTimer = $BounceTimer

@onready var ball = $Ball
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	bounceTimer.timeout.connect(apply_rand_impulse)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func apply_rand_impulse()->void:
	var impulseVec = Vector3(randf_range(0.,20),randf_range(0.,20),randf_range(0.,20))
	print("applied")
	print(impulseVec)
	ball.apply_impulse(impulseVec)
