@icon("res://Art/ProjectSpecific/Override.svg")
@tool
extends SlotChange
##This is just a schmorgesborg of stuff I had no place for otherwise
class_name Override

@export_group("Card Override")
@export var identifier: Identifier
@export_flags("non-ex","ex", "Baby", "Delta", "Star", "Dark") var considered: int = 0

@export_group("Pokemon Override")
@export_enum("Add", "Subtract", "Replace") var mode: String = "Replace"
@export var prize_count: int = -1
@export var can_evolve_into: Array[String] = []
@export var can_retreat_when: Array[Consts.TURN_COND]

@export_group("Energy Override")
@export_enum("Any", "Basic Energy", "Special Energy") var en_category: String = "Any"
##If this is true look for energy that fits the exact flags of [member converting][br]
##This prevents rainbow energy and such from counting
@export var provides_only: bool = true
@export var converting: EnData
@export var no_effects: bool = false
##If this is true, then the EnData's number will become whatever is
##in [member becomes] otherwise it retains it's own number
@export var replace_num: bool = false
##If this is true then EnData will be replaced with [member becomes]
##otherwise the two type flags are added together
@export var replace_provide: bool = false
@export var becomes: EnData

func how_display() -> Dictionary[String, bool]:
	return {"Override" : false}

func describe() -> String:
	if can_evolve_into.size() != 0:
		print("Can evolve into ", Convert.combine_strings(can_evolve_into))
		return str("Can evolve into ", Convert.combine_strings(can_evolve_into))
	
	return "Not described yet"
