@icon("res://Art/Energy/35px-Rainbow-attack.png")
extends Control
class_name TypeContainer

@export var retreat: bool = false
@export var energy: bool = false
@onready var bg: TextureRect = %BG
@onready var tabs: TabContainer = %Tabs
@onready var num_label: RichTextLabel = %Number

var number: int = 0

func _ready(): if retreat: tabs.current_tab = 8

func add_type(type: String, ammount: int = 1):
	number = ammount
	display_type(type)
	
	num_label.clear()
	num_label.append_text(str(number))
	
	if number >= 1: show()
	if number > 1: num_label.show()
	else:
		num_label.hide()

func display_type(type: String):
	var type_id: int = Consts.energy_types.find(type)
	tabs.current_tab = type_id
	
	#Special types
	#const energy_types: Array[String] = [8+ "Rainbow", "Magma",
	#"Aqua", "Dark Metal","FF", "GL", "WP", "React"]
	if type_id < 10:
		bg.modulate = Consts.energy_colors[type_id]
	elif type_id < 14:
		bg.modulate = Consts.energy_colors[6]
	elif type_id > 12:
		bg.modulate = Color.WHITE

func remove_type():
	number -= 1
	num_label.clear()
	num_label.append_text(str(number))
	
	if number <= 1: num_label.hide()
	if number < 1: hide()

func make_misc(ammount: int) -> void:
	number = ammount
	tabs.current_tab = tabs.get_tab_count() - 1
	
	num_label.clear()
	num_label.append_text(str(number))
	
	if number <= 1: num_label.hide()
	if number < 1: hide()

func get_type_index() -> int:
	return tabs.current_tab
