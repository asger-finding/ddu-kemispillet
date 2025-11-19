extends Node

func _on_online_button_button_up() -> void:
	SceneManager.load_scene('Menu/ConfigureConnectionMenu')

func _on_offline_button_button_up() -> void:
	pass # Replace with function body.
