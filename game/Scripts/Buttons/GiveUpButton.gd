extends Button

func _ready():
	pressed.connect(_button_pressed)
	
func _button_pressed() -> void:
	get_tree().quit()
