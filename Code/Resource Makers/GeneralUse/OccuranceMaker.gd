@tool
extends Resource
class_name Occurance

const pokeSlot = preload("uid://cs70ix831b5g4")

signal occur

var slot_instance = pokeSlot.new()
var internal_data = { "signal": "checked_up",
 "from_ask" : load("res://Resources/Components/Effects/Asks/General/AnyMon.tres") as SlotAsk,
 "must_be_ask": load("res://Resources/Components/Effects/Asks/General/AnyMon.tres") as SlotAsk,
 "card_type" : load("res://Resources/Components/Effects/Identifiers/AnyCard.tres") as Identifier,
 "energy_type": load("res://Resources/Components/EnData/Rainbow.tres") as EnData,
 "condition" : load("res://Resources/Components/Effects/Conditions/EverythingHurts.tres") as Condition}
var owner: PokeSlot
#--------------------------------------
func _get_property_list() -> Array[Dictionary]:
	var props: Array[Dictionary] = []
	var signal_array_names: PackedStringArray = []
	var res_signal_list = ClassDB.class_get_signal_list("Resource")
	
	#Collect the name of every property that's in a poke_slot
	#Will not include any non-export variables
	for s in slot_instance.get_signal_list():
		if (not s in res_signal_list):
			signal_array_names.append(s.name)
	
	props.append({
		"name" : "from_ask",
		"type" : TYPE_OBJECT,
		"hint" : PROPERTY_HINT_RESOURCE_TYPE,
		"hint_string" : "SlotAsk",
		"usage" : PROPERTY_USAGE_DEFAULT
	})
	#Append their names into an enum to select from
	props.append({
		"name" : "signal",
		"type" : TYPE_STRING,
		"hint" : PROPERTY_HINT_ENUM,
		"hint_string" : ",".join(signal_array_names),
		"usage" : PROPERTY_USAGE_DEFAULT
	})
	
	if _get("signal") == "attatch_en_signal" or _get("signal") == "discard_en_signal":
		#props.append({
			#"name" : "card_type",
			#"type" : TYPE_OBJECT,
			#"hint" : PROPERTY_HINT_RESOURCE_TYPE,
			#"hint_string" : "Identifier",
			#"usage" : PROPERTY_USAGE_DEFAULT
		#})
		props.append({
			"name" : "energy_type",
			"type" : TYPE_OBJECT,
			"hint" : PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string" : "EnData",
			"usage" : PROPERTY_USAGE_DEFAULT
		})
	
	if _get("signal") == "take_dmg" or _get("signal") == "will_take_dmg"\
	 or _get("signal") == "used_power":
		props.append({
			"name" : "must_be_ask",
			"type" : TYPE_OBJECT,
			"hint" : PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string" : "SlotAsk",
			"usage" : PROPERTY_USAGE_DEFAULT
		})
	
	if _get("signal") == "condition_applied":
		props.append({
			"name" : "condition",
			"type" : TYPE_OBJECT,
			"hint" : PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string" : "Condition",
			"usage" : PROPERTY_USAGE_DEFAULT
		})
	return props
#--------------------------------------

#--------------------------------------
#region GET FUNCTIONS
func _get(property):
	match property:
		"from_ask": return internal_data["from_ask"] as SlotAsk
		"signal": return internal_data["signal"]
		"must_be_ask": return internal_data["must_be_ask"] as SlotAsk
		"card_type": return internal_data["card_type"] as Identifier
		"energy_type": return internal_data["energy_type"] as EnData
		"condition": return internal_data["condition"] as Condition
	return null

func _property_can_revert(property: StringName):
	if (property == "from_ask" or property == "signal"
	or property == "must_be_ask" or property == "card_type"
	or property == "energy_type" or property == "condition"):
		return true
	return false

func _property_get_revert(property: StringName) -> Variant:
	match property: 
		"signal": return "checked_up"
		"from_ask": return load("res://Resources/Components/Effects/Asks/General/AnyMon.tres") as SlotAsk
		"must_be_ask": return load("res://Resources/Components/Effects/Asks/General/AnyMon.tres") as SlotAsk
		"card_type": return load("res://Resources/Components/Effects/Identifiers/AnyCard.tres") as Identifier
		"condition": return load("res://Resources/Components/Effects/Conditions/EverythingHurts.tres") as Condition
		"energy_type": return load("res://Resources/Components/EnData/Rainbow.tres") as EnData
	return null
#endregion
#--------------------------------------

#--------------------------------------
func _set(property, value):
	match property:
		"signal":
			internal_data["signal"] = value
			notify_property_list_changed()
			return true
		"from_ask": 
			if not value is SlotAsk:
				return false
			internal_data["from_ask"] = value as SlotAsk
			return true
		"must_be_ask":
			internal_data["must_be_ask"] = value
			return true
		"card_type":
			internal_data["card_type"] = value
			return true
		"energy_type":
			internal_data["energy_type"] = value
			return true
		"condition":
			internal_data["condition"] = value
			return true
	return false
#--------------------------------------

#--------------------------------------
#region SIGNAL FUNCTIONS
func connect_occurance():
	print(self)
	var slots: Array[PokeSlot] = Globals.full_ui.get_ask_slots(_get("from_ask"))
	
	for slot in slots:
		if not connected_to_this(slot):
			slot.connect(_get("signal"), should_occur)

func disconnect_occurance():
	var slots: Array[PokeSlot] = Globals.full_ui.get_ask_slots(_get("from_ask"))
	
	for slot in slots:
		if slot.get(_get("signal")).has_connections():
			slot.disconnect(_get("signal"), should_occur)

func single_connect(slot: PokeSlot):
	if not connected_to_this(slot) and _get("from_ask").check_ask(slot):
		slot.connect(_get("signal"), should_occur)

func single_disconnect(slot: PokeSlot):
	if slot.get(_get("signal")).has_connections() and _get("from_ask").check_ask(slot):
		slot.disconnect(_get("signal"), should_occur)

func should_occur(param: Variant = null):
	if param is String and param == "CheckingMultiples":
		return owner
	elif is_allowed(param):
		occur.emit()
		return

func is_allowed(param: Variant = null):
	if param is PokeSlot:
		return _get("must_be_ask").check_ask(param)
	elif param is EnData:
		return _get("energy_type").same_type(param)
	else:
		return true

func connected_to_this(slot: PokeSlot) -> bool:
	for connection in slot.get(_get("signal")).get_connections():
		if connection["callable"] == should_occur:
			return true
	return false

#endregion
#--------------------------------------
