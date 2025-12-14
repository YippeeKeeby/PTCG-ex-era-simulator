@icon("res://Art/Counters/Poison.png")
extends Resource
class_name Condition

@export var ask: SlotAsk = load("res://Resources/Components/Effects/Asks/General/Other.tres")

@export var any: bool = false
##Number of dmg Counters added from this effect, multiplied by 10 on implementation
@export_range(0,20,1) var poison: int = 0
##Number of dmg Counters added from this effect, multiplied by 10 on implementation
@export_range(0,20,1) var burn: int = 0
@export var turn_cond: Consts.TURN_COND = Consts.TURN_COND.NONE
@export var imprision: bool = false
@export var shockwave: bool = false
@export var knockOut: bool = false

signal finished

func play_effect(reversable: bool = false, replace_num: int = -1) -> void:
	print("PLAYING CONDITION")
	var slots: Array[PokeSlot] = Globals.full_ui.get_ask_slots(ask)
	slots = Globals.fundies.filter_immune(Consts.IMMUNITIES.ATK_EFCT_OPP, slots)
	if slots.size() == 0: return
	
	if any:
		var input: InputCondition = Consts.input_condition.instantiate()
		var cond: String
		
		Globals.full_ui.set_top_ui(input)
		
		await input.finished
		cond = input.selected.name
		print(cond)
		
		SignalBus.remove_top_ui.emit()
		
		for filtered in slots:
			filtered.add_specified_condition(self, cond)
	
	else:
		for filtered in slots:
			filtered.add_condition(self)
	
	finished.emit()

func huh():
	var new: InputCondition = Consts.input_condition.instantiate()
	
	await new.finished

func print_condition() -> String:
	if any:
		return "conditioned"
	
	var conditions: Array[String]
	
	if poison > 1:
		conditions.append("poisioned")
	if burn > 1:
		conditions.append("burnt")
	match turn_cond:
		Consts.TURN_COND.PARALYSIS:
			conditions.append("paralyzed")
		Consts.TURN_COND.ASLEEP:
			conditions.append("asleep")
		Consts.TURN_COND.CONFUSION:
			conditions.append("confused")
	if imprision:
		conditions.append("imprisioned")
	if shockwave:
		conditions.append("shockwaved")
	
	return Convert.combine_strings(conditions, "or")
