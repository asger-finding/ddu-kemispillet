extends Node2D

@export var _username_input: LineEdit
@export var _password_input: LineEdit
@export var _error_text: Label

func _ready() -> void:
	_error_text.visible = false

func _on_username_input_text_changed(new_text: String) -> void:
	var pos := _username_input.caret_column
	var regex := RegEx.new()
	regex.compile("[A-Za-z0-9_-]")

	var filtered := ""
	for c in new_text:
		if regex.search(c):
			filtered += c
	filtered = filtered.substr(0, 25)
	if filtered != new_text:
		_username_input.text = filtered
		_username_input.caret_column = clamp(pos - (new_text.length() - filtered.length()), 0, filtered.length())

func _on_sign_up_button_button_up() -> void:
	AudioManager.play_sfx(load("res://Audio/SFX/ButtonPress.ogg"))
	
	var username = _username_input.get_text()
	var password = _password_input.get_text()
	var result = await Backend.post("login", { "username": username, "password": password })

	if (!result["error"]): SceneManager.load_scene('Game')
	else: handle_error(result["error"])

func _on_login_redirect_button_button_up() -> void:
	AudioManager.play_sfx(load("res://Audio/SFX/ButtonPress.ogg"))
	SceneManager.load_scene('LoginMenu')

func handle_error(code: String) -> void:
	_error_text.text = "Fejl: " + code # TODO: human readable errors
	_error_text.visible = true
	await get_tree().create_timer(5).timeout
	_error_text.text = ""
	_error_text.visible = false
