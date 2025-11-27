extends Node2D

@onready var _username_input: LineEdit = %UsernameInput
@onready var _password_input: LineEdit = %PasswordInput
@onready var _error_message: Label = %ErrorMessage

func _ready() -> void:
	_error_message.visible = false

func _on_login_button_button_up() -> void:
	var username = _username_input.get_text()
	var password = _password_input.get_text()
	var result = await Backend.post("login", { "username": username, "password": password })
	
	if (!result["error"]):
		MpClient.player_id = result.response.player_id
		MpClient.auth_token = result.response.auth_token
		MpClient.handshake()
	else: handle_error(result["error"])

func handle_error(code: String) -> void:
	_error_message.text = 'Fejl: ' + code # TODO: human readable errors
	_error_message.visible = true
	await get_tree().create_timer(5).timeout
	_error_message.text = ''
	_error_message.visible = false

func _on_back_button_button_up() -> void:
	SceneManager.load_scene('Menu/MainMenu')
