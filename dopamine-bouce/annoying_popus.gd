extends Control


@onready var annoyingPopupTimer = $"AnnoyingPopupTimer"
@onready var popup = $Popup

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	annoyingPopupTimer.timeout.connect(newPopup)


func newPopup():
	var newPopup = popup.duplicate()
	self.add_child(newPopup)
	
	newPopup.position.x = randi_range(0+256,get_viewport().get_visible_rect().size.x-256)
	newPopup.position.y = randi_range(0+256,get_viewport().get_visible_rect().size.y-256)

	newPopup.visible = true
