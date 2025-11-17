extends Node2D

func _on_login_button_button_up() -> void:
	SceneManager.load_scene("LoginMenu")

func _on_register_button_button_up() -> void:
	SceneManager.load_scene("RegisterMenu")
