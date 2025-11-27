extends Control

@onready var _username_value: Label = %UsernameValue
@onready var _player_id_value: Label = %PlayerIdValue
@onready var _games_started_value: Label = %GamesStartedValue
@onready var _games_won_value: Label = %GamesWonValue
@onready var _questions_anwered_value: Label = %QuestionsAnsweredValue
@onready var _questions_correct_value: Label = %QuestionsCorrectValue

func _ready() -> void:	
	_username_value.text = str(GameManager.player_details.username)
	_player_id_value.text = str(GameManager.player_details.player_id)
	_games_started_value.text = str(GameManager.player_details.runs)
	_games_won_value.text = str(GameManager.player_details.victories)
	_questions_anwered_value.text = str(GameManager.player_details.questions_answered)
	_questions_correct_value.text = str(GameManager.player_details.questions_correct)

func _on_close_popup_button_button_up() -> void:
	self.queue_free()
