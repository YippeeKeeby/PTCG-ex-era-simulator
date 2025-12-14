@tool
@icon("res://Art/ProjectSpecific/car.png")
extends Resource
class_name IndvCounter

#--------------------------------------
#region VARIABLES
#script constants
const pokeSlot = preload("uid://cs70ix831b5g4")
const stackRes = preload("uid://calm3n7va5yjo")
const which_vars: PackedStringArray = ["Slot", "Stack", "Coinflip", "Input"]
const en_methods: PackedStringArray = ["Total", "Excess", "Diff Types", "Categories"]
const en_category_enum: PackedStringArray = ["Any", "Basic Energy", "Special Energy"]

var slot_instance = pokeSlot.new()
var stack_instance = stackRes.new()
var internal_data = {"which" : "Slot",
 "slot_vars" : "current_card", "stack_vars" : "None",
 "coin_flip" : load("uid://csc2clyxejdwm") as CoinFlip,
 "ask" : load("uid://bns8h72u2hxqo") as SlotAsk, "identifier": null,
 "stack_portion" : -1, "en_count_methods" : "Total", "en_categories" : "Any",
 "en_counting" : load("uid://cv8xofc4ofaom") as EnData 
 ,"input_title" : "Input Number" ,"cap" : -1}
#endregion
#--------------------------------------

#--------------------------------------
func _get_property_list() -> Array[Dictionary]:
	#region GATHERINFO
	var props: Array[Dictionary] = []
	var slot_array_names: PackedStringArray = []
	var stack_array_names: PackedStringArray = ["None"]
	var res_prop_list = ClassDB.class_get_property_list("Resource")
	#Collect the name of every property that's in a poke_slot
	#Will not include any non-export variables
	for p in slot_instance.get_property_list():
		if (p.has("usage") and p.usage & PROPERTY_USAGE_DEFAULT
		 and p.name not in slot_array_names and not p in res_prop_list):
			slot_array_names.append(p.name)
		#else:
			#print(p.name, p.has("usage"), p.usage ,p.usage & PROPERTY_USAGE_DEFAULT,
			#p.name not in slot_array_names, not p in res_prop_list)
	
	#Only get the variables that are defined as variables without exports
	#These are the stacks that get used during play
	for p in stackRes.new().get_property_list():
		if (p.has("usage") and p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and
		 not p.usage & PROPERTY_USAGE_DEFAULT and p.name not in stack_array_names):
			stack_array_names.append(p.name)
	#endregion
	
	#region ESTABLISH PROPERTIES
	props.append({
		"name" : "which",
		"type" : TYPE_STRING,
		"hint" : PROPERTY_HINT_ENUM,
		"hint_string" : ",".join(which_vars),
		"usage" : PROPERTY_USAGE_DEFAULT
	})
	if _get("which") != "Coinflip" and _get("which") != "Input":
		#I'll always need ask for at least defining side to check
		props.append({
				"name" : "ask",
				"type" : TYPE_OBJECT,
				"hint" : PROPERTY_HINT_RESOURCE_TYPE,
				"hint_string" : "SlotAsk",
				"usage" : PROPERTY_USAGE_DEFAULT
		})
	#Find slot_vars
	if _get("which") == "Slot":
		#Append their names into an enum to select from
		props.append({
			"name" : "slot_vars",
			"type" : TYPE_STRING,
			"hint" : PROPERTY_HINT_ENUM,
			"hint_string" : ",".join(slot_array_names),
			"usage" : PROPERTY_USAGE_DEFAULT
			})
		if _get("slot_vars") == "energy_cards":
			#Slot specific count methods
			props.append({
				"name" : "en_count_methods",
				"type" : TYPE_STRING,
				"hint" : PROPERTY_HINT_ENUM,
				"hint_string" : ",".join(en_methods),
				"usage" : PROPERTY_USAGE_DEFAULT
			})
			if _get("en_count_methods") == "Categories"\
			or _get("en_count_methods") == "Diff Types":
				props.append({
					"name" : "en_categories",
					"type" : TYPE_STRING,
					"hint" : PROPERTY_HINT_ENUM,
					"hint_string" : ",".join(en_category_enum),
					"usage" : PROPERTY_USAGE_DEFAULT
				})
			if _get("en_count_methods") == "Total"\
			 or _get("en_count_methods") == "Excess":
				props.append({
					"name" : "en_counting",
					"type" : TYPE_OBJECT,
					"hint" : PROPERTY_HINT_RESOURCE_TYPE,
					"hint_string" : "EnData",
					"usage" : PROPERTY_USAGE_DEFAULT
					})
	#Find Stack vars
	elif _get("which") == "Stack":
		props.append({
			"name" : "stack_vars",
			"type" : TYPE_STRING,
			"hint" : PROPERTY_HINT_ENUM,
			"hint_string" : ",".join(stack_array_names),
			"usage" : PROPERTY_USAGE_DEFAULT
		})
		props.append({
				"name" : "identifier",
				"type" : TYPE_OBJECT,
				"hint" : PROPERTY_HINT_RESOURCE_TYPE,
				"hint_string" : "Identifier",
				"usage" : PROPERTY_USAGE_DEFAULT
		})
		props.append({
			"name" : "stack_portion",
			"type" : TYPE_INT,
			"usage" : PROPERTY_USAGE_DEFAULT
		})
	#Find Coin flip
	elif _get("which") == "Coinflip":
		props.append({
			"name" : "coin_flip",
			"type" : TYPE_OBJECT,
			"hint" : PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string" : "CoinFlip",
			"usage" : PROPERTY_USAGE_DEFAULT
		})
	
	elif _get("which") == "Input":
		props.append({
				"name" : "input_title",
				"type" : TYPE_STRING,
				"usage" : PROPERTY_USAGE_DEFAULT
		})
		
	
	props.append({
		"name" : "cap",
		"type" : TYPE_INT,
		"usage" : PROPERTY_USAGE_DEFAULT
	})
	#endregion
	
	return props
#--------------------------------------

#--------------------------------------
#region GET FUNCTIONS
func _get(property):
	if internal_data == null:
		internal_data = _property_get_revert("internal_data")
		return null
	elif not internal_data.has(property) and _property_can_revert(property):
		internal_data[property] = _property_get_revert(property)
	
	match property:
		"which": return internal_data["which"]
		"slot_vars": return internal_data["slot_vars"]
		"stack_vars": return internal_data["stack_vars"]
		"coin_flip": return internal_data["coin_flip"] as CoinFlip
		"ask": return internal_data["ask"] as SlotAsk
		"identifier": return internal_data["identifier"] as Identifier
		"stack_portion": return internal_data["stack_portion"]
		"en_count_methods": return internal_data["en_count_methods"]
		"en_categories": return internal_data["en_categories"]
		"en_counting": return internal_data["en_counting"] as EnData
		"input_title": return internal_data["input_title"]
		"cap": return internal_data["cap"]
	
	return null

func _property_can_revert(property: StringName):
	if (property == "which" or property == "slot_vars" or property == "stack_vars"
	or property == "coin_flip" or property == "ask" or property == "identifier" or
	property == "stack_portion" or property == "en_count_methods" or
	property == "en_categories" or property == "en_counting" or
	property == "input_title" or property == "cap"):
		return true
	return false

func _property_get_revert(property: StringName) -> Variant:
	match property: 
		"which": return "Slot"
		"slot_vars": return "current_card"
		"stack_vars": return "None"
		"coin_flip": return load("uid://csc2clyxejdwm") as CoinFlip
		"ask": return load("uid://bns8h72u2hxqo") as SlotAsk
		"identifier": return load("uid://dm2i7spst0qpp") as Identifier
		"stack_portion": return -1
		"en_count_methods": return "Total"
		"en_categories": return "Any"
		"en_counting": return load("uid://cv8xofc4ofaom") as EnData
		"input_title": return "Input Number"
		"cap": return -1
		"internal_data": return {"which" : "Slot",
		 "slot_vars" : "current_card", "stack_vars" : "None",
		 "coin_flip" : load("uid://csc2clyxejdwm") as CoinFlip,
		 "ask" : load("uid://bns8h72u2hxqo") as SlotAsk, "identifier": null,
		 "stack_portion" : -1, "en_count_methods" : "Total", "en_categories" : "Any",
		 "en_counting" : load("uid://cv8xofc4ofaom") as EnData 
		 ,"input_title" : "Input Number" ,"cap" : -1}
	return null
#endregion
#--------------------------------------

#--------------------------------------
func _set(property, value):
	match property:
		"which":
			internal_data["which"] = value
			notify_property_list_changed()
			return true
		"slot_vars": 
			internal_data["slot_vars"] = value
			notify_property_list_changed()
			return true
		"stack_vars": 
			internal_data["stack_vars"] = value
			return true
		"coin_flip":
			if not value is CoinFlip:
				return false
			internal_data["coin_flip"] = value as CoinFlip
		"ask": 
			if not value is SlotAsk:
				return false
			internal_data["ask"] = value as SlotAsk
			return true
		"identifier":
			if not value is Identifier:
				return false
			internal_data["identifier"] = value as Identifier
			return true
		"stack_portion":
			internal_data["stack_portion"] = value
			return true
		"en_count_methods": 
			internal_data["en_count_methods"] = value
			notify_property_list_changed()
			return true
		"en_categories":
			internal_data["en_categories"] = value
			return true
		"en_counting":
			if not value is EnData:
				return false
			internal_data["en_counting"] = value as EnData
			return true
		"input_title":
			internal_data["input_title"] = value
			return true
		"cap": 
			internal_data["cap"] = value
			return true
	
	return false
#--------------------------------------

#--------------------------------------
#region EVALUATION
func evaluate() -> int:
	var result: int = 0
	
	match _get("which"):
		"Slot":
			result = slot_evaluation(_get("slot_vars"), _get("ask"))
		"Stack":
			result = stack_evaluation(_get("stack_vars"), _get("ask"))
		"Coinflip":
			result = coinflip_evaluation(_get("coin_flip"))
	if _get("cap") != -1:
		result = clamp(result, 0, _get("cap"))
	
	return result

func slot_evaluation(slot_data: String, ask_data: SlotAsk) -> int:
	var result: int = 0
	var poke_slots: Array[PokeSlot] = Globals.full_ui.get_poke_slots()
	var filtered_slots: Array[PokeSlot] = []
	for slot in poke_slots:
		if ask_data.check_ask(slot):
			filtered_slots.append(slot)
	#For now .filter doesn't work here so.....
	#print("a:", poke_slots.filter(func (slot: PokeSlot): not ask_data.check_ask(slot)))
	#print("B:", poke_slots.filter(func (slot: PokeSlot): ask_data.check_ask(slot)))
	
	for slot in filtered_slots:
		#print(slot, slot.get(slot_data))
		if slot_data == "energy_cards":
			result += energy_card_evaluation(_get("en_count_methods"), slot)
		else:
			var data = slot.get(slot_data)
			if data is Array:
				result += data.size()
			#This is here for counting number of pokemon as it will use current_card instead of an int
			elif not data is int and data != null:
				result += 1
			else:
				result += slot.get(slot_data)
	
	return result

func energy_card_evaluation(en_count_methods_data: String, slot: PokeSlot):
	match en_count_methods_data:
		"Total":
			return slot.get_total_energy(_get("en_counting"))
		"Excess":
			return slot.get_energy_excess(_get("en_counting"))
		"Diff Types":
			return slot.count_diff_energy()
		"Categories":
			return slot.get_total_en_categories(_get("en_categories")).size()

func stack_evaluation(stack_data: String, ask_data: SlotAsk) -> int:
	var fundies: Fundies = Globals.fundies
	if ask_data.side_target == Consts.SIDES.BOTH:
		var atk_stack: CardStacks = fundies.stack_manager.get_stacks(fundies.get_considered_home(Consts.SIDES.ATTACKING))
		var def_stack: CardStacks = fundies.stack_manager.get_stacks(fundies.get_considered_home(Consts.SIDES.DEFENDING))
		
		var atk_num: int = identifier_count(atk_stack.get(stack_data), _get("identifier"))\
			if _get("identifier") else atk_stack.get(stack_data).size()
		var def_num: int = identifier_count(def_stack.get(stack_data), _get("identifier"))\
			if _get("identifier") else def_stack.get(stack_data).size()
		
		return atk_num + def_num
	else:
		var stacks: CardStacks = fundies.stack_manager.get_stacks(fundies.get_considered_home(ask_data.side_target))
		
		return identifier_count(stacks.get(stack_data), _get("identifier"))\
		 if _get("identifier") else stacks.get(stack_data).size()

func identifier_count(stack: Array[Base_Card], identifier: Identifier) -> int:
	var num: int = 0
	var using: Array[Base_Card] = stack
	if _get("stack_portion") != -1:
		using = stack.slice(0,_get("portion"))
	
	for card in using:
		if identifier.identifier_bool(card):
			num += 1
	
	print("Found ", num, " for stack identifer count")
	return num

func coinflip_evaluation(coinflip_data: CoinFlip) -> int:
	var flip_data: Dictionary = coinflip_data.activate_CF()
	var flip_results: Array[bool] = coinflip_data.get_flip_array(flip_data)
	var flip_box: Control
	
	if coinflip_data.until:
		flip_box = Consts.until_flip_box.instantiate()
	else:
		flip_box = Consts.reg_flip_box.instantiate()
		flip_results.shuffle()
	
	flip_box.flip_results = flip_results
	flip_box.top_level = true
	Globals.full_ui.set_top_ui(flip_box)
	
	return flip_data["Heads"] if coinflip_data.heads else flip_data["Tails"]

func input_evaluation() -> int:
	var input_return: int = 0
	var input_box: InputNum = Consts.input_number.instantiate()
	
	input_box.title = _get("input_title")
	input_box.cap = _get("cap")
	
	Globals.full_ui.set_top_ui(input_box)
	
	await input_box.finished
	input_return = int(input_box.spin_box.value)
	
	SignalBus.remove_top_ui.emit()
	print("INPUT: ", input_return)
	return input_return

#endregion
#--------------------------------------

func has_coinflip() -> bool:
	return _get("which") == "Coinflip"

func has_input() -> bool:
	return _get("which") == "Input"
