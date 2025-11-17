extends Button

func _ready():
	pressed.connect(_button_pressed)
	
func _button_pressed() -> void:
	SceneManager.load_scene("Game")
