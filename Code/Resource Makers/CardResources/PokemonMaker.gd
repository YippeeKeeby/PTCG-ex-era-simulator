extends Resource
class_name Pokemon

@export_group("Stats")
@export_range(10,200,10) var HP: int = 50
@export_range(0,6) var retreat: int = 1

@export_group("Actions")
##While a power is allowed to be inserted here, bodies do appear abover powers when both are present
##[br]ex. DF10 Snorlax
@export var pokebody: Ability
##While a power is allowed to be inserted here, bodies do appear abover powers when both are present
##[br]ex. DF10 Snorlax
@export var pokepower: Ability
@export var attacks: Array[Attack] = []

@export_group("Properties")
@export_enum("Basic", "Stage 1", "Stage 2") var evo_stage: String = "Basic"
@export var evolves_from: String = ""
@export_flags("non-ex","ex", "Baby", "Delta", "Star", "Dark") var considered: int = 1
@export_enum("None","Team Aqua","Team Magma","Team Rocket", "Holon") var owner: int = 0

@export_group("Type")
@export_flags("Grass","Fire","Water",
"Lightning","Psychic","Fighting",
"Darkness","Metal","Colorless") var type: int = 1

@export_flags("Grass","Fire","Water",
"Lightning","Psychic","Fighting",
"Darkness","Metal","Colorless") var weak: int = 32

@export_flags("Grass","Fire","Water",
"Lightning","Psychic","Fighting",
"Darkness","Metal","Colorless") var resist: int = 0

func print_pokemon() -> void:
	var type_color: String = str("[color=",Consts.energy_colors[log(type) / log(2)].to_html(),"]") 
	
	print_rich("HP: ", HP,"
	Stage: ", evo_stage,"
	Type: ",type_color,Convert.flags_to_type_array(type),"[/color]")
	if weak != 0:
		var weak_color: String = str("[color=",Consts.energy_colors[log(weak) / log(2)].to_html(),"]")
		print_rich("Weakness: ",weak_color, Convert.flags_to_type_array(weak),"[/color]")
	if resist != 0:
		var resist_color: String = str("[color=",Consts.energy_colors[log(resist) / log(2)].to_html(),"]")
		print_rich("Reistance: ",resist_color, Convert.flags_to_type_array(resist),"[/color]")
	
	print("-------------------------------------------------------------")

func duplicate_abilities():
	if pokebody:
		pokebody = pokebody.duplicate_deep()
	if pokepower:
		pokepower = pokepower.duplicate_deep()
