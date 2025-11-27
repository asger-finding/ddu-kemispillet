extends CanvasLayer

const QUESTION_POPUP_SCENE := preload("res://Scenes/Popup/QuestionPopup.tscn")

func _ready() -> void:
	GameManager._new_question.connect(_on_new_question)

func _on_new_question(question: Dictionary) -> void:
	var question_popup = QUESTION_POPUP_SCENE.instantiate()
	
	question_popup.preload_question(question)
	self.add_child(question_popup)
