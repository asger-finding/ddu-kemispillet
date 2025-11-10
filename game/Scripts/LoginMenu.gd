extends Node2D

@export var _username_input: LineEdit
@export var _password_input: LineEdit
@export var _error_text: Label

func _ready() -> void:
	_error_text.visible = false

func _on_login_button_button_up() -> void:
	AudioManager.play_sfx(load("res://Audio/SFX/ButtonPress.ogg"))
	
	var username = _username_input.get_text()
	var password = _password_input.get_text()
	var result = await Backend.post("login", { "username": username, "password": password })
	
	if (!result["error"]): SceneManager.load_scene('Game')
	else: handle_error(result["error"])

func _on_sign_up_redirect_button_button_up() -> void:
	AudioManager.play_sfx(load("res://Audio/SFX/ButtonPress.ogg"))
	SceneManager.load_scene("SignUpMenu")

func handle_error(code: String) -> void:
	_error_text.text = "Fejl: " + code # TODO: human readable errors
	_error_text.visible = true
	await get_tree().create_timer(5).timeout
	_error_text.text = ""
	_error_text.visible = false
