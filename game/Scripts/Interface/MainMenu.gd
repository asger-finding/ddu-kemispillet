extends Node2D

@onready var _playing_on_label: Label = %PlayingOn

func _ready() -> void:
	_playing_on_label.text = "Spiller på %s" % MpClient.socket_address

func _on_login_button_button_up() -> void:
	SceneManager.load_scene("Menu/LoginMenu")

func _on_register_button_button_up() -> void:
	SceneManager.load_scene("Menu/RegisterMenu")
