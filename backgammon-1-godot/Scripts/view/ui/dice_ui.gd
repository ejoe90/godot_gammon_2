extends Control
class_name DiceUI

@onready var rolled_label: Label = $RolledLabel
@onready var remaining_label: Label = $RemainingLabel

func set_dice(rolled: Array[int], remaining: Array[int]) -> void:
	rolled_label.text = "Rolled: " + _fmt(rolled)
	remaining_label.text = "Remaining: " + _fmt(remaining)

func _fmt(a: Array[int]) -> String:
	if a.is_empty():
		return "-"
	var parts: Array[String] = []
	for v in a:
		parts.append(str(v))
	return ", ".join(parts)
