extends Control

@onready var _object_container: HBoxContainer = %ObjectContainer
@onready var _scroll_container: ScrollContainer = %ScrollContainer
@onready var _username_label: Label = %UsernameLabel

const STATISTICS_POPUP_SCENE := preload("res://Scenes/Popup/StatisticsPopup.tscn")

var targetScroll = 0

func _ready() -> void:
	_set_selection()
	if not GameManager.player_details.is_empty():
		_username_label.text = GameManager.player_details.username

func _set_selection():
	await get_tree().create_timer(0.01).timeout
	_select_deselect_highlight()

func _on_previous_button_pressed() -> void:
	var scrollValue = targetScroll - _get_space_between()
	if scrollValue < 0 : scrollValue = _get_space_between() * 3
	await _tween_scroll(scrollValue)
	
	_select_deselect_highlight()

func _on_next_button_pressed() -> void:
	var scrollValue = targetScroll + _get_space_between()
	if scrollValue > _get_space_between() * 3: scrollValue = 0
	await _tween_scroll(scrollValue)
	
	_select_deselect_highlight()

func _get_space_between():
	var distanceSize = _object_container.get_theme_constant("separation")
	var objectSize = _object_container.get_children()[1].size.x
	
	return distanceSize + objectSize

func _tween_scroll(scrollValue):
	targetScroll = scrollValue
	
	var tween = get_tree().create_tween()
	tween.tween_property(_scroll_container, "scroll_horizontal", scrollValue, 0.25)
	await tween.finished

func _select_deselect_highlight():
	var selectedNode = get_selected_value()
	
	for child in _object_container.get_children():
		if child is not TextureRect: continue
		
		var tween = get_tree().create_tween()
		if child == selectedNode:
			tween.tween_property(child, "modulate", Color(1.0, 1.0, 1.0), 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		else:
			tween.tween_property(child, "modulate", Color(0.0, 0.0, 0.0), 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func get_selected_value():
	var selectedPosition = %SelectionMarker.global_position
	for child in _object_container.get_children():
		if child.get_global_rect().has_point(selectedPosition):
			return child

func _on_play_button_button_up() -> void:
	var player_skin = get_selected_value().name;
	GameManager.join_game(player_skin)

func _on_log_out_button_button_up() -> void:
	MpClient.send_to_server(MpMessage.create_message(MpMessage.TypeId.LEAVE_MESSAGE, {}))
	SceneManager.load_scene("Menu/ConfigureConnectionMenu")

func _on_statistics_button_button_up() -> void:
	var statistics_popup = STATISTICS_POPUP_SCENE.instantiate()
	self.add_child(statistics_popup)
