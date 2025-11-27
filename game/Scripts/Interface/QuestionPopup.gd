extends Control

@onready var _chapter_label: Label = %ChapterLabel
@onready var _question_label: Label = %QuestionLabel
@onready var _description_label: Label = %DescriptionLabel
@onready var _timeout_label: Label = %TimeoutLabel
@onready var _input_container: VBoxContainer = %InputContainer

var question: Dictionary
var current_type: String = ""
var autoclose_timer: Timer = null
var menu_theme: Theme = load("res://Theme/Menu.tres")

func _ready() -> void:
	_chapter_label.text = question.CHAPTER
	_question_label.text = question.QUESTION
	_description_label.text = question.DESCRIPTION
	
	autoclose_timer = Timer.new()
	autoclose_timer.one_shot = true
	autoclose_timer.timeout.connect(_on_autoclose)
	add_child(autoclose_timer)
	autoclose_timer.start(Constants.QUESTION_POPUP_AUTOCLOSE_TIME)
	
	generate_input()

func _process(_delta: float) -> void:
	_timeout_label.text = "Lukker om %s s" % floori(autoclose_timer.time_left)

func _on_autoclose() -> void:
	GameManager._question_answered_none.emit(self)

func preload_question(question_data: Dictionary):
	question = question_data

func _on_submit_button_button_up():
	var user_answer = get_submitted_answer()
	var is_correct = validate_answer(user_answer)
	
	if is_correct:
		print("User answered question correct")
		GameManager._question_answered_correct.emit(self)
	else:
		print("User answered question wrong")
		GameManager._question_answered_wrong.emit(self)

func _on_give_up_button_button_up() -> void:
	GameManager._question_quit.emit(self)

func generate_input() -> void:
	for child in _input_container.get_children():
		child.queue_free()
	
	match question.ANSWER_TYPE:
		"TEXT":
			_create_text_input()
		"RADIO":
			_create_radio_input(question["OPTIONS"])
		"CHECKBOX":
			_create_checkbox_input(question["OPTIONS"])
	
func _create_text_input() -> void:
	var input = LineEdit.new()
	input.placeholder_text = "Skriv dit svar her..."
	input.custom_minimum_size.y = 40
	input.theme = menu_theme
	_input_container.add_child(input)

func _create_radio_input(options: Array) -> void:
	var group = ButtonGroup.new()
	
	for option_text in options:
		var radio = CheckBox.new()
		radio.text = option_text
		radio.theme = menu_theme
		radio.button_group = group
		_input_container.add_child(radio)

func _create_checkbox_input(options: Array) -> void:
	for option_text in options:
		var box = CheckBox.new()
		box.text = option_text
		box.theme = menu_theme
		_input_container.add_child(box)

func get_submitted_answer() -> Variant:
	match question.ANSWER_TYPE:
		"TEXT":
			# value: String
			var input_node = _input_container.get_child(0) as LineEdit
			return input_node.text.strip_edges()
			
		"RADIO":
			# index: int
			var index = 0
			for child in _input_container.get_children():
				if child is CheckBox and child.button_pressed:
					return index
				index += 1
			return -1
			
		"CHECKBOX":
			# Array[String]
			var selected_answers = []
			for child in _input_container.get_children():
				if child is CheckBox and child.button_pressed:
					selected_answers.append(child.text)
			return selected_answers
	
	return null

func validate_answer(user_answer) -> bool:
	var answer_type = question.get("ANSWER_TYPE", "TEXT")
	var correct_answer = question.get("ANSWER")
	
	match answer_type:
		"TEXT":
			return _validate_text_answer(question.KEY, user_answer, correct_answer)
		"RADIO":
			return _validate_radio_answer(user_answer, correct_answer)
		"CHECKBOX":
			return _validate_checkbox_answer(user_answer, correct_answer)
		_:
			push_error("Unknown answer type: " + str(answer_type))
			return false

# Loose validation
# because text input can be tricky
func _validate_text_answer(key: int, user_answer: String, correct_answer: String) -> bool:
	var user_input = user_answer.strip_edges().to_lower()
	var correct = correct_answer.strip_edges().to_lower()
	
	match key:
		0:
			return user_input == "kuldioxid" or user_input == "carbondioxid"
		
		1:
			return user_input == "dinitrogentrioxid"
		
		2:
			return user_input == "2" or user_input == "to"
		
		5:
			var has_92 = "92" in user_input
			var has_146 = "146" in user_input
			return has_92 and has_146
		
		7:
			var clean_answer = _remove_special_chars(user_input)
			return clean_answer == "cuo"
		
		8:
			var clean_answer = _remove_special_chars(user_input)
			var clean_correct = _remove_special_chars(correct)
			return clean_answer == clean_correct or clean_answer == "oh-"
		
		9:
			var clean_answer = _remove_special_chars(user_input)
			return clean_answer == "so42-" or clean_answer == "so4(2-)"
		
		10:
			var number = _extract_number(user_input)
			if number == null:
				return false
			return abs(number - 4.5) <= 0.5
		
		11:
			var number = _extract_number(user_input)
			if number == null:
				return false
			return abs(number - 6.19) <= 0.5 or abs(number - 6.2) <= 0.1
		
		_:
			return user_input == correct

func _validate_radio_answer(user_answer: int, correct_answer: int) -> bool:
	return user_answer == correct_answer

func _validate_checkbox_answer(user_answer: Array, correct_answer: Array) -> bool:
	if user_answer.size() != correct_answer.size():
		return false
	
	var user_set = {}
	var correct_set = {}
	
	for item in user_answer:
		user_set[item] = true
	
	for item in correct_answer:
		correct_set[item] = true
	
	for item in user_set.keys():
		if not correct_set.has(item):
			return false
	
	for item in correct_set.keys():
		if not user_set.has(item):
			return false
	
	return true

func _remove_special_chars(text: String) -> String:
	# We trim all special character (superscript, different syntax)
	# because we just want to parse the raw format
	var result = ""
	for c in text:
		if c.is_valid_int() or (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or c == '+' or c == '-':
			result += c
	return result.to_lower()

func _extract_number(text: String) -> float:
	text = text.replace(",", ".")
	
	var regex = RegEx.new()
	regex.compile("\\d+(?:[.,]\\d+)?")
	var result = regex.search(text)
	
	if result:
		var num_str = result.get_string().replace(",", ".")
		return float(num_str)
	
	return NAN
