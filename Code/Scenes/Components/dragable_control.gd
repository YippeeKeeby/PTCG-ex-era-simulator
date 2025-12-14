@tool
@icon("res://Art/ExpansionIcons/40px-SetSymbolUnseen_Forces.png")
extends Button
class_name Draggable_Control

@onready var drag_component = $Drag as Draggable

##Which node will this component drag around?
@export var dragging_node: Control
##If this is filled, it will use this node's position as the offset
@export var based_on: Control
@export var offset: Vector2 = Vector2.ZERO

signal drag(node: Node)
signal drop(node: Node)

var drag_position: Vector2

func _get_configuration_warnings() -> PackedStringArray:
	if not dragging_node:
		return ["Node not connected to anything"]
	else:
		return []

func _ready() -> void:
	set_process(false)

func _process(delta: float) -> void:
	var new_pos: Vector2 = get_global_mouse_position() - drag_position
	
	new_pos.x = clampf(new_pos.x, 0, get_viewport().size.x - size.x)
	new_pos.y = clampf(new_pos.y, 0, get_viewport().size.y - size.y)
	
	if dragging_node:
		dragging_node.position = new_pos

func _on_drag_ended() -> void:
	set_process(false)
	drop.emit()

func _on_drag_started(event_position: Variant) -> void:
	drag_position = event_position
	if based_on:
		drag_position.y += based_on.position.y
	Globals.dragging = true
	set_process(true)
	drag.emit()

func _on_gui_input(event: InputEvent) -> void:
	if dragging_node and not event.is_action_pressed("Drag")\
	 and dragging_node.has_method("_on_gui_input"):
		dragging_node.gui_input.emit(event)
	drag_component.object_held_down(event)
