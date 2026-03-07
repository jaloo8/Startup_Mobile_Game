class_name EventData
extends Resource

@export var id: String = ""
@export var title: String = ""
@export var description: String = ""
@export var choices: Array[Dictionary] = []  # [{label, effects:{}, outcome_text}]
@export var trigger_conditions: Dictionary = {}
@export var weight: float = 1.0
@export var one_time: bool = false

func is_eligible(game_state: Dictionary) -> bool:
	for key in trigger_conditions:
		if not game_state.has(key):
			return false
		var condition = trigger_conditions[key]
		var value = game_state[key]
		if condition is float or condition is int:
			if value < condition:
				return false
		elif condition is bool:
			if value != condition:
				return false
	return true
