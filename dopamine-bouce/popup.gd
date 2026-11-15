extends Control

@onready var button = $Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	button.pressed.connect(remove_self)


func remove_self():
	self.queue_free()
