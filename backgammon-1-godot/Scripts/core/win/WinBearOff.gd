# res://scripts/core/win/WinBearOff.gd
extends WinCondition
class_name WinBearOff

@export var target_off: int = 15

func check(state: Variant) -> bool:
	var bs := state as BoardState
	if bs == null:
		return false

	return bs.off_white.size() >= target_off or bs.off_black.size() >= target_off
