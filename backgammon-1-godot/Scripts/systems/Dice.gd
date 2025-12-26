extends Node
class_name Dice

var dice: Array[int] = []
var remaining: Array[int] = []  # list of dice pips still to use this turn

func roll() -> void:
	var d1 := randi_range(1, 6)
	var d2 := randi_range(1, 6)
	dice = [d1, d2]
	remaining.clear()
	if d1 == d2:
		remaining = [d1, d1, d1, d1]
	else:
		remaining = [d1, d2]

func has_moves() -> bool:
	return remaining.size() > 0

func consume_die(die: int) -> bool:
	var idx := remaining.find(die)
	if idx == -1:
		return false
	remaining.remove_at(idx)
	return true
	
func force(d1: int, d2: int) -> void:
	d1 = clampi(d1, 1, 6)
	d2 = clampi(d2, 1, 6)
	dice = [d1, d2]

	remaining.clear()
	if d1 == d2:
		# doubles = 4 moves
		remaining.append(d1)
		remaining.append(d1)
		remaining.append(d1)
		remaining.append(d1)
	else:
		remaining.append(d1)
		remaining.append(d2)
