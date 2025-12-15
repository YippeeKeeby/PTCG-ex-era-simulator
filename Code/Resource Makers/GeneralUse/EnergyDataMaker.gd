@icon("res://Art/Energy/48px-Psychic-attack.png")
@tool
extends Resource
class_name EnData

##How much energy does this provide on a succesful attatch
@export var number: int = 1
##React energy interacts with several poke-powers, so it needs to be categorized
##It doesn't provide different types however, so it's not considered as one
@export var react: bool = false
##Holon's energy are thier own categoory so they can be interacted with
@export_enum("None","FF","GL","WP","ETC") var holon_type: String = "None"
##What types will this data be considered[br]
##Providing multiple types means that one of the multiple types will be accounted for when counting energy
@export_flags("Grass","Fire","Water",
"Lightning","Psychic","Fighting",
"Darkness","Metal","Colorless") var type: int = 511
@export_tool_button("Describe") var button: Callable = describe

##Funciton that tells the game how the energy should be displayed visually
##[br]Not every combination of type needs to be accounted for
##only the ones that appear in the ex Series
##[br]* Basic Types
##[br]* Rainbow
##[br]* Holon's
##[br]* React
##[br]* Magma & Aqua
##[br]* DarkMetal
##[br]* React
func get_string():
	if react: return "React"
	if holon_type != "None": return holon_type
	if type == 2 ** 9 - 1: return "Rainbow"
	elif type == 2 ** 7 + 2 ** 6: return "Dark Metal"
	elif type == 2 ** 5 + 2 ** 6: return "Magma"
	elif type == 2 ** 2 + 2 ** 6: return  "Aqua"
	
	var index = int((log(float(type)) / log(2)))
	return Consts.energy_types[index]

func same_type(compared_to: EnData):
	# 2 & 2  2 && 2
	# 2 & 1  2 && 1
	# 2 & 1023  2 && 1023
	#printt(compared_to.type, type, compared_to.type & type, compared_to.type && type)
	return compared_to.type & type != 0

func describe():
	var final: String
	
	if type != 511 and type != 0:
		final = Convert.combine_flags_to_string(["{Grass}","{Fire}","{Water}",
		"{Lightning}","{Psychic}","{Fighting}","{Darkness}",
		"{Metal}","{Colorless}"], type)
		final = Convert.reformat(final)
	
	if react:
		final = str(final, " React")
	
	if holon_type != "None":
		final = str(final, holon_type if holon_type != "ETC" else "", " Holon")
	
	print_rich(final)
	
	return final
