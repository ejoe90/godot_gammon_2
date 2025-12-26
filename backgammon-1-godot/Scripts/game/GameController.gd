# res://scripts/game/GameController.gd
extends Node
class_name GameController

@onready var board: BoardView = $BoardView
@onready var dice: Dice = $Dice
@onready var dice_ui: DiceUI = $HUD/DiceUI

@export var win_conditions: Array[WinCondition] = []

var state: BoardState
var selected_from: int = -999 # -1 bar, 0..23 point, -999 none

func _ready() -> void:
	randomize()

	state = BoardState.new()
	state.reset_standard()
	#state.debug_validate_unique_ids()

	board.sync_from_state_full(state)
	board.point_clicked.connect(Callable(self, "_on_point_clicked"))

	start_turn()

func start_turn() -> void:
	selected_from = -999
	board.clear_move_targets()

	dice.roll()
	dice_ui.set_dice(dice.dice, dice.remaining)

	if _count_all_legal_moves() == 0:
		end_turn()

func end_turn() -> void:
	state.turn = state.opponent(state.turn)
	start_turn()

func _count_all_legal_moves() -> int:
	var p: int = state.turn
	var total: int = 0
	for d in dice.remaining:
		total += Rules.legal_moves_for_die(state, p, d).size()
	return total

func _on_point_clicked(i: int) -> void:
	var p: int = state.turn

	# Force from bar if needed
	var bar: PackedInt32Array = state.bar_white if p == BoardState.Player.WHITE else state.bar_black
	if bar.size() > 0:
		selected_from = -1
		board.show_move_targets(_compute_targets_for_selected(), p)
		_try_move_to(i)
		return

	# No selection -> select a friendly stack
	if selected_from == -999:
		if i >= 0 and i <= 23 and state.stack_count(i) > 0 and state.stack_owner(i) == p:
			selected_from = i
			board.show_move_targets(_compute_targets_for_selected(), p)
		return

	# Selection exists -> try move FIRST
	if _try_move_to(i):
		return

	# If move did not start and clicked another friendly point, switch selection
	if i >= 0 and i <= 23 and state.stack_count(i) > 0 and state.stack_owner(i) == p:
		selected_from = i
		board.show_move_targets(_compute_targets_for_selected(), p)
		return

	# Otherwise clear
	selected_from = -999
	board.clear_move_targets()

func _compute_targets_for_selected() -> Array[int]:
	var p: int = state.turn
	var targets: Array[int] = []

	if selected_from == -999:
		return targets

	for d in dice.remaining:
		var moves: Array[Dictionary] = Rules.legal_moves_for_die(state, p, d)
		for m in moves:
			if int(m["from"]) == selected_from:
				var to_i: int = int(m["to"])
				if not targets.has(to_i):
					targets.append(to_i)

	return targets

# Returns true if a move animation started
func _try_move_to(dst_index: int) -> bool:
	var p: int = state.turn

	for d in dice.remaining.duplicate():
		var moves: Array[Dictionary] = Rules.legal_moves_for_die(state, p, d)
		for m in moves:
			if int(m["from"]) == selected_from and int(m["to"]) == dst_index:
				# Clear highlights immediately once committed
				board.clear_move_targets()

				board.animate_move_persistent(state, m, p, func() -> void:
					Rules.apply_move(state, p, m)
					dice.consume_die(d)
					dice_ui.set_dice(dice.dice, dice.remaining)

					# Keep visuals consistent with ID stacks
					board.sync_from_state_full(state)

					# (temporary validation; remove later)
					# state.debug_validate_unique_ids()

					selected_from = -999

					for wc in win_conditions:
						if wc != null and wc.check(state):
							print("Game over:", wc.id)
							return

					if not dice.has_moves():
						end_turn()
					elif _count_all_legal_moves() == 0:
						end_turn()
				)
				return true

	return false
