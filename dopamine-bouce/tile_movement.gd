extends Node3D

@export var speed := 8.0

func _process(delta):
	position.z += speed * delta

	if position.z > 10.0:
		queue_free()
