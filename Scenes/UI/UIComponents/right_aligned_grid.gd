@tool
extends Control

@export var rows: int = 1
@export var columns: int = 1
@export var h_seperation: int = 4
@export var v_seperation: int = 4

func _ready() -> void:
	pass

func determine_grid():
	var row: VBoxContainer = VBoxContainer.new()
	
	row.theme_override_constants.separation = v_seperation
	
	add_child(row)
	
	for i in rows:
		var column: HBoxContainer = HBoxContainer.new()
		var margin: Control = Control.new()
		
		column.theme_override_constants.separation = h_seperation
		margin.size_flags_horizontal = Control.SIZE_EXPAND
		
		row.add_child(column)
		column.add_child(margin)

func arrange_grid():
	pass
