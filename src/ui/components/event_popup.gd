class_name EventPopup
extends PanelContainer
## Modal popup for resolving narrative events.
## Shows the event description (with template variables resolved)
## and choice buttons. Player must choose before continuing.

signal event_resolved(event: EventData, choice_index: int)

@onready var title_label: Label = $Margin/VBox/TitleLabel
@onready var description_label: Label = $Margin/VBox/DescLabel
@onready var choices_container: VBoxContainer = $Margin/VBox/ChoicesContainer
@onready var outcome_label: Label = $Margin/VBox/OutcomeLabel
@onready var continue_btn: Button = $Margin/VBox/ContinueButton

var _current_event: EventData
var _current_choice_index: int = -1
var _tween: Tween


func _ready() -> void:
	visible = false
	continue_btn.visible = false
	continue_btn.pressed.connect(_on_continue)


func show_event(event: EventData) -> void:
	_current_event = event
	_current_choice_index = -1

	title_label.text = event.title
	description_label.text = EventEngine.resolve_event_text(event, GameState)

	outcome_label.visible = false
	outcome_label.text = ""
	continue_btn.visible = false

	_free_children(choices_container)
	for i in event.choices.size():
		var choice: Dictionary = event.choices[i]
		var btn := Button.new()
		btn.text = choice.get("label", "...")
		btn.custom_minimum_size = Vector2(0, 44)
		btn.pressed.connect(_on_choice.bind(i))
		choices_container.add_child(btn)

	modulate.a = 0.0
	visible = true
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, 0.2)


func _on_choice(index: int) -> void:
	_current_choice_index = index
	var choice: Dictionary = _current_event.choices[index]

	for child in choices_container.get_children():
		if child is Button:
			child.disabled = true

	outcome_label.text = EventEngine.resolve_outcome_text(choice, GameState)
	outcome_label.visible = true
	continue_btn.visible = true

	_apply_effects(choice.get("effects", {}))


func _apply_effects(effects: Dictionary) -> void:
	if effects.has("cash"):
		GameState.company.cash += float(effects["cash"])
	if effects.has("morale_all"):
		var delta: int = int(effects["morale_all"])
		for emp in GameState.employees:
			emp.morale = clampi(emp.morale + delta, 0, 100)
	if effects.has("stress_all"):
		var delta: int = int(effects["stress_all"])
		for emp in GameState.employees:
			emp.stress = clampi(emp.stress + delta, 0, 100)
	if effects.has("tech_debt"):
		GameState.product.tech_debt = clampi(GameState.product.tech_debt + int(effects["tech_debt"]), 0, 100)
	if effects.has("bugs"):
		GameState.product.bugs = maxi(0, GameState.product.bugs + int(effects["bugs"]))
	if effects.has("reputation"):
		GameState.company.reputation = clampi(GameState.company.reputation + int(effects["reputation"]), 0, 100)
	if effects.has("users"):
		GameState.product.users = maxi(0, GameState.product.users + int(effects["users"]))
	if effects.has("stability"):
		GameState.product.stability = clampi(GameState.product.stability + int(effects["stability"]), 0, 100)
	if effects.has("game_win"):
		GameState.is_game_active = false
		GameState.game_won.emit(str(effects["game_win"]))


func _on_continue() -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, 0.15)
	_tween.tween_callback(_finish_resolve)


func _finish_resolve() -> void:
	visible = false
	event_resolved.emit(_current_event, _current_choice_index)


static func _free_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
