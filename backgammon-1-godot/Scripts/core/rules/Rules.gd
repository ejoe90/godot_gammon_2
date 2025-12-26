extends Object
class_name Rules

static func _dir(p: int) -> int:
	return 1 if p == BoardState.Player.WHITE else -1

static func _home_range(p: int) -> Vector2i:
	# WHITE home: 18..23, BLACK home: 0..5
	return Vector2i(18, 23) if p == BoardState.Player.WHITE else Vector2i(0, 5)

static func _entry_point_from_bar(p: int, die: int) -> int:
	# WHITE enters at 0..5 via die-1; BLACK enters at 23..18 via 24-die
	return (die - 1) if p == BoardState.Player.WHITE else (24 - die)

static func _blocked_by_opponent(state: BoardState, p: int, dst: int) -> bool:
	if dst < 0 or dst > 23:
		return false
	var c: int = state.stack_count(dst)
	if c < 2:
		return false
	var o: int = state.stack_owner(dst)
	return o != -1 and o != p

static func _is_hit(state: BoardState, p: int, dst: int) -> bool:
	if dst < 0 or dst > 23:
		return false
	return state.stack_count(dst) == 1 and state.stack_owner(dst) != -1 and state.stack_owner(dst) != p

static func all_in_home(state: BoardState, p: int) -> bool:
	var hr: Vector2i = _home_range(p)
	for i in range(24):
		var c: int = state.stack_count(i)
		if c == 0:
			continue
		if state.stack_owner(i) != p:
			continue
		if i < hr.x or i > hr.y:
			return false
	return state.bar_stack(p).size() == 0

static func _has_checker_behind_in_home(state: BoardState, p: int, from_i: int) -> bool:
	var hr: Vector2i = _home_range(p)
	if p == BoardState.Player.WHITE:
		for i in range(hr.x, from_i):
			if state.stack_count(i) > 0 and state.stack_owner(i) == p:
				return true
	else:
		for i in range(from_i + 1, hr.y + 1):
			if state.stack_count(i) > 0 and state.stack_owner(i) == p:
				return true
	return false

static func legal_moves_for_die(state: BoardState, p: int, die: int) -> Array[Dictionary]:
	var res: Array[Dictionary] = []
	die = clampi(die, 1, 6)

	# Must enter from bar if any on bar
	var bar: PackedInt32Array = state.bar_stack(p)
	if bar.size() > 0:
		var dst: int = _entry_point_from_bar(p, die)
		if not _blocked_by_opponent(state, p, dst):
			res.append({
				"from": -1,
				"to": dst,
				"hit": _is_hit(state, p, dst),
			})
		return res

	var d: int = _dir(p)
	for from_i in range(24):
		if state.stack_count(from_i) == 0:
			continue
		if state.stack_owner(from_i) != p:
			continue

		var dst_i: int = from_i + d * die

		# Normal move
		if dst_i >= 0 and dst_i <= 23:
			if not _blocked_by_opponent(state, p, dst_i):
				res.append({
					"from": from_i,
					"to": dst_i,
					"hit": _is_hit(state, p, dst_i),
				})
			continue

		# Bear off
		if all_in_home(state, p):
			# exact or overshoot-with-no-behind (simple but standard-friendly)
			var bear_ok: bool = false
			if p == BoardState.Player.WHITE:
				if dst_i == 24:
					bear_ok = true
				elif dst_i > 24 and not _has_checker_behind_in_home(state, p, from_i):
					bear_ok = true
			else:
				if dst_i == -2:
					bear_ok = true
				elif dst_i < -2 and not _has_checker_behind_in_home(state, p, from_i):
					bear_ok = true

			if bear_ok:
				res.append({
					"from": from_i,
					"to": 24 if p == BoardState.Player.WHITE else -2,
					"hit": false,
				})

	return res

static func apply_move(state: BoardState, p: int, m: Dictionary) -> void:
	var from_i: int = int(m["from"])
	var to_i: int = int(m["to"])
	var hit: bool = bool(m.get("hit", false))

	# Pop moving checker id
	var moving_id: int = -1
	if from_i == -1:
		var bar: PackedInt32Array = state.bar_stack(p)
		moving_id = bar[bar.size() - 1]
		bar.remove_at(bar.size() - 1)
		if p == BoardState.Player.WHITE:
			state.bar_white = bar
		else:
			state.bar_black = bar
	else:
		var src: PackedInt32Array = state.points[from_i]
		moving_id = src[src.size() - 1]
		src.remove_at(src.size() - 1)
		state.points[from_i] = src

	# Handle hit on destination point
	if hit and to_i >= 0 and to_i <= 23:
		var dst: PackedInt32Array = state.points[to_i]
		if dst.size() == 1:
			var hit_id: int = dst[0]
			var opp: int = state.owner_of(hit_id)
			dst = PackedInt32Array() # cleared
			state.points[to_i] = dst

			var opp_bar: PackedInt32Array = state.bar_stack(opp)
			opp_bar.append(hit_id)
			if opp == BoardState.Player.WHITE:
				state.bar_white = opp_bar
			else:
				state.bar_black = opp_bar

	# Push to destination
	if to_i >= 0 and to_i <= 23:
		var dst2: PackedInt32Array = state.points[to_i]
		dst2.append(moving_id)
		state.points[to_i] = dst2
		return

	# Bear off
	if (p == BoardState.Player.WHITE and to_i == 24) or (p == BoardState.Player.BLACK and to_i == -2):
		var off: PackedInt32Array = state.off_stack(p)
		off.append(moving_id)
		if p == BoardState.Player.WHITE:
			state.off_white = off
		else:
			state.off_black = off
			
	print("moved id", moving_id, "from", from_i, "to", to_i)
