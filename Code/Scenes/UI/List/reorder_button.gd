extends PanelContainer

@export var card: Base_Card
@onready var movable: Draggable_Control = $Movable

var parent: Node
var checking_card: Node
var stack_act: Consts.STACK_ACT
var allowed: bool = false
var from_id: Identifier
var origin: Vector2

func show_card():
	if card != null:
		%Class.clear()
		%Class.append_text(card.get_considered())
		
		%Art.texture = card.image
		%Name.clear()
		%Name.append_text(card.name)
		
		set_name(card.name)
	else:
		printerr("Card in ", self, " is nothing")

func _on_movable_drag() -> void:
	origin = position
	top_level = true
	global_position = get_global_mouse_position()

func _on_movable_drop() -> void:
	top_level = false
	position = origin

func _on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("Check"):
		Globals.show_card(card, self)
