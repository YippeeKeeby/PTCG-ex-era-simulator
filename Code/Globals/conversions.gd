@tool
extends Node

var all_lists: Array[Dictionary]

#region STRINGS
func reformat(text: String, user: String = "<null>") -> String:
	var result: String = text
	var icon_search = RegEx.new()
	var new_icon_search = RegEx.new()
	var italics_search = RegEx.new()
	var name_search = RegEx.new()
	icon_search.compile(r"\{.*?\}")
	new_icon_search.compile(r"\[.*?\]")
	italics_search.compile(r"\(.*?\)")
	name_search.compile(r"\[name\]")
	
	var matches = icon_search.search_all(text)
	var new_matches = new_icon_search.search_all(text)
	var italics = italics_search.search_all(text)
	var names = name_search.search_all(text)
	
	for found in matches:
		#Specific mentions of energy types should be replaced by icon
		var key: String = found.get_string(0).lstrip("{").rstrip("}")
		var index: int = Consts.energy_types.find(key)
		if index == -1: push_error(key," isn't found in Consts energy_types")
		
		var icon_path: String = str("[img={13%}}]",
		Consts.energy_icons[index],"[/img]")
		
		result = result.replace(found.get_string(0), icon_path)
	
	for found in new_matches:
		#Specific mentions of energy types should be replaced by icon
		var key: String = found.get_string(0).lstrip("[]").rstrip("]")
		var index: int = Consts.energy_characters.find(key)
		
		if index == -1: continue
		
		var icon_path: String = str("[img={13%}}]",
		Consts.energy_icons[index],"[/img]")
		
		result = result.replace(found.get_string(0), icon_path)
	
	for found in italics:
		#Anything in parenthesis should be italisized
		var original: String = found.get_string(0)
		var wrapped: String = "[i]" + original + "[/i]"
		
		result = result.replace(original, wrapped)
	
	for found in names:
		var original: String = found.get_string(0)
		var replaced: String = "[u]" + user + "[/u]"
		result = result.replace(original, replaced)
	
	return result

func get_type_rich_color(type: String) -> String:
	var type_int: float = Consts.energy_types.find(type)
	var color_string: String = str("[color=",Consts.energy_colors[type_int].to_html(),"]")
	return color_string

func stack_into_string(stack: Consts.STACKS) -> String:
	match stack:
		Consts.STACKS.HAND:
			return "Hand"
		Consts.STACKS.DISCARD:
			return "Discard"
		Consts.STACKS.DECK:
			return "Deck"
		Consts.STACKS.PRIZE:
			return "Prize"
		Consts.STACKS.LOST:
			return "Lost Zone"
		Consts.STACKS.PLAY:
			return "In Play"
		_:
			printerr(stack, "Isn't recognized as a viable type")
	return ""

func slot_into_string(slot: Consts.SLOTS) -> String:
	match slot:
		Consts.SLOTS.ALL:
			return ""
		Consts.SLOTS.ACTIVE:
			return "active "
		Consts.SLOTS.BENCH:
			return "benched "
		Consts.SLOTS.TARGET:
			return "targetted "
		Consts.SLOTS.REST:
			return "non-targetted "
	return ""
 
func side_into_string(side: Consts.SIDES) -> String:
	match side:
		Consts.SIDES.BOTH:
			return "both "
		Consts.SIDES.ATTACKING:
			return "attacking "
		Consts.SIDES.DEFENDING:
			return "defending "
		Consts.SIDES.SOURCE:
			return "your "
		Consts.SIDES.OTHER:
			return "opposing "
	return ""

func combine_strings(string_array: Array[String], conjuction: String = "and") -> String:
	var final: String = ""
	
	for i in range(string_array.size()):
		if final == "":
			final += string_array[i]
		elif i == string_array.size() - 1 and conjuction:
			final += str(" ", conjuction, " ", string_array[i])
		else:
			if conjuction:
				final += str(", ", string_array[i])
			else:
				final += str(" ", string_array[i])
	return final

#SlotAsk, Identifier
func combine_flags_to_string(flags_strings: Array[String], flag_int: int, conjuction: String = "or"):
	var looking_for: Array[String]
	for flag in range(flags_strings.size()):
		if flag_int & 2 ** flag: looking_for.append(flags_strings[flag])
	
	return Convert.combine_strings(looking_for, conjuction)

#endregion

#region STRING ARRAYS
func flags_to_type_array(type_flags: int) -> Array[String]:
	var types: Array[String] = []
	
	if type_flags & 1:
		types.append("Grass")
	if type_flags & 2:
		types.append("Fire")
	if type_flags & 4:
		types.append("Water")
	if type_flags & 8:
		types.append("Lightning")
	if type_flags & 16:
		types.append("Psychic")
	if type_flags & 32:
		types.append("Fighting")
	if type_flags & 64:
		types.append("Darkness")
	if type_flags & 128:
		types.append("Metal")
	if type_flags & 256:
		types.append("Colorless")
	
	return types

func get_basic_energy() -> Array[String]:
	var arr: Array[String]
	for i in range(9):
		arr.append(Consts.energy_types[i])
	return arr

func flags_to_allowed_array(allowed_flags: int) -> Array[String]:
	var allowed_array: Array[String]
	var checking: float = allowed_flags
	for i in range(Consts.allowed_list_flags.size()-1, -1, -1):
		print(2 ** i, checking, checking / 2 ** i)
		if checking / 2 ** i > 0:
			checking -= 2 ** i
			allowed_array.append(Consts.allowed_list_flags[i])
			print("Added allowed: ", allowed_array)
		
		pass
	
	return allowed_array
#endregion

#region INTIGERS
func get_allowed_flags(allowed: String = "All") -> int:
	match allowed:
		"Start":
			return (2 ** Consts.allowed_list_flags.find("Basic")
			 + 2 ** Consts.allowed_list_flags.rfind("Fossil"))
		"Pokemon":
			return (2 ** Consts.allowed_list_flags.find("Basic")
			+ 2 ** Consts.allowed_list_flags.find("Evolution")
			 + 2 ** Consts.allowed_list_flags.rfind("Fossil"))
		"Trainer":
			return (2 ** Consts.allowed_list_flags.size() - 1 -
			 (2 ** Consts.allowed_list_flags.find("Basic")
			+ 2 ** Consts.allowed_list_flags.find("Evolution")
			 + 2 ** Consts.allowed_list_flags.rfind("Energy")))
		"All":
			return 2 ** Consts.allowed_list_flags.size() - 1
		_:
			return 2 ** Consts.allowed_list_flags.find(allowed)

func get_card_flags(card: Base_Card) -> int:
	var card_flags: int = 0
	
	if card.categories & 1:
		
		if card.fossil: 
			card_flags += Convert.get_allowed_flags("Fossil")
		elif card.pokemon_properties.evo_stage == "Basic":
			card_flags += Convert.get_allowed_flags("Basic")
		else:
			card_flags += Convert.get_allowed_flags("Evolution")
		
	elif card.categories & 2:
		var considered = card.trainer_properties.considered
		if considered == "Rocket's Secret Machine": considered = "RSM"
		if considered == "Supporter": considered = "Support"
		card_flags += Convert.get_allowed_flags(considered)
	
	if card.categories & 4:
		card_flags += Convert.get_allowed_flags("Energy")
	
	return card_flags

func get_number_of_flags(flags: int, n: int) -> int:
	var count: int = 0
	
	for i in range(n):
		if flags & (2 ** i) != 0:
			count += 1
	
	return count
#endregion

#region BOOLEEANS
func playing_as_pokemon(allowed_flag: int) -> bool:
	return allowed_flag & get_allowed_flags("Pokemon") != 0

#For use in lists
func default_card_sort(button1: Button, button2: Button):
	var card1: Base_Card = button1.card
	var card2: Base_Card = button2.card
	#First prioritize allowed cards
	var first_bool: bool = false
	var second_bool: bool = false
	
	for list in all_lists:
		first_bool = list[card1] or first_bool
		second_bool = list[card2] or second_bool
	if first_bool and not second_bool:
		return true
	elif second_bool and not first_bool:
		return false
	
	#If they're both (not) allowed check card priority
	else:
		return card1.card_priority(card2)
#endregion
