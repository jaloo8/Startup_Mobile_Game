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
		var condition = trigger_conditions[key]

		if key == "company_types":
			if condition is Array and game_state.has("company_type"):
				var ct: int = int(game_state["company_type"])
				var type_key: String
				match ct:
					0: type_key = "saas"
					1: type_key = "consumer"
					2: type_key = "marketplace"
					3: type_key = "dev_tools"
					_: type_key = ""
				if not type_key.is_empty() and type_key not in condition:
					return false
			continue

		if not game_state.has(key):
			return false
		var value = game_state[key]
		if condition is float or condition is int:
			if value < condition:
				return false
		elif condition is bool:
			if value != condition:
				return false
	return true
