# res://game/CheckerSprite.gd  (adjust path if needed)
extends Node2D
class_name CheckerSprite

@export var tex_white: Texture2D
@export var tex_black: Texture2D

# If your sprite node is not named Sprite2D, change this path
@export var sprite_path: NodePath = NodePath("Sprite2D")
@export var click_area_path: NodePath = NodePath("ClickArea")

@onready var sprite: Sprite2D = get_node_or_null(sprite_path) as Sprite2D
@onready var click_area: Area2D = get_node_or_null(click_area_path) as Area2D

# Assigned by BoardPieces when node is created/reused
var checker_id: int = -1

func _ready() -> void:
	if sprite == null:
		push_error("[CheckerSprite] Sprite not found at: %s" % str(sprite_path))
	if tex_white == null:
		push_error("[CheckerSprite] tex_white not assigned")
	if tex_black == null:
		push_error("[CheckerSprite] tex_black not assigned")

	# Click wiring (optional but needed for printing IDs on click)
	if click_area == null:
		push_error("[CheckerSprite] ClickArea not found at: %s (add an Area2D child named ClickArea)" % str(click_area_path))
	else:
		click_area.input_pickable = true
		click_area.input_event.connect(Callable(self, "_on_click_area_input_event"))

func set_checker_id(id: int) -> void:
	checker_id = id
	set_meta("checker_id", id)

func set_color(is_white: bool) -> void:
	if sprite == null:
		return
	sprite.modulate = Color(1, 1, 1, 1) # clears any tint
	sprite.texture = tex_white if is_white else tex_black

func _on_click_area_input_event(_vp: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("[CHECKER CLICK] id=", checker_id)
