@icon("res://Art/Counters/Spiral.png")
extends Resource
class_name DamageManip

##If this is not -1, put this effect in a stack that applies later, in the mean time get it's srctrgt
@export var choosing: Consts.SIDES = Consts.SIDES.SOURCE
@export_enum("Add", "Remove", "Swap") var mode: String = "Remove"
##Who will get the counter manipulation[br]
##On [enum Swap] this determines who gives dmg counters
@export var ask: SlotAsk
##-1 means remove/add max ammount
@export_range(-1,20) var how_many: int = 1
##The player must choose to add [member how_many] this many times.
##[br] On -1, ignore and place [member how_many] on every mon that meets [member ask]
@export var choose_num: int = 1
##If this is true, then the player can divide [member how_many]
## in any way instead of adding it [member choose_num] times
@export var turn_delay: int = -1
@export var prevent_KO: bool = false
@export var anyway_u_like: bool = false
@export_group("Leftovers")
##For DF9 Dragonite ex who uses a second type of DmgManip using leftovers
@export_enum("None", "Add", "Remove", "Swap") var with_leftover: String = "None"
@export var leftover_anyway: bool = false
##Determines how many will be added/removed based on the Counter
@export_group("Counter")
@export var vary_choose_num: bool = false
##If this is false, subtract based on comparator instead
@export var plus: bool = true
@export var comparator: Comparator
@export var modifier: int = 1
@export_group("Swap Exclusive")
@export var takers: SlotAsk

signal finished

func play_effect(reversable: bool = false, replace_num: int = -1) -> void:
	print("PLAY DAMAGE MANIPULATION")
	if anyway_u_like:
		await dmg_manip_box(reversable, replace_num)
	elif mode != "Swap":
		await simple_manip(reversable, replace_num)
	else:
		await swap_manip(reversable, replace_num)
	
	finished.emit()

func simple_manip(reversable: bool = false, replace_num: int = -1):
	print("simple this time")
	var counters: int = how_many if replace_num == -1 else replace_num
	var mod_by: int
	
	#If anything other than max ammount
	if counters != -1:
		if comparator:
			print(ask)
			print(comparator, comparator.first_comparison)
			mod_by = await comparator.start_comparision() * modifier
			mod_by *= 1 if plus else -1
			if comparator.has_coinflip():
				await SignalBus.finished_coinflip
			

		if vary_choose_num:
			choose_num += mod_by
		else:
			counters += mod_by
		counters *= -10 if mode == "Remove" else 10
	
	#Choose from candidates shown by ask
	if choose_num != -1:
		for i in range(choose_num):
			var manip_candidate: PokeSlot
			manip_candidate = await Globals.fundies.card_player.get_choice_candidates(\
			"Choose which pokemon to ", func(slot): return ask.check_ask(slot), reversable)
			
			if manip_candidate == null: return
			
			manip_candidate.dmg_manip(get_final_ammount(counters, manip_candidate), turn_delay)
	
	#Apply manip on all ask candidates for -1 mainpulations
	else:
		for slot in Globals.full_ui.get_ask_minus_immune(ask, Consts.IMMUNITIES.ATK_EFCT_OPP):
			if mode == "Remove":
				slot.dmg_manip(-1 * slot.get_max_hp(), turn_delay)
			elif slot.damage_counters != 0 or mode == "Add":
				slot.dmg_manip(get_final_ammount(counters, slot), turn_delay)
	
	finished.emit()

func dmg_manip_box(reversable: bool = false, replace_num: int = -1):
	
	#If no one can give return
	if Globals.full_ui.get_ask_minus_immune(ask, Consts.IMMUNITIES.ATK_EFCT_OPP).size() == 0:
		return
	
	var dmg_manip: DmgManipBox = Consts.dmg_manip_box.instantiate()
	var counters: int = how_many if replace_num == -1 else replace_num
	if mode == "Swap":
		var taker_array: Array[PokeSlot] = Globals.full_ui.get_ask_minus_immune(takers, Consts.IMMUNITIES.ATK_EFCT_OPP)
		
		#If no one can take return
		if taker_array.size() == 0: return
		
		if counters == -1:
			counters = 0
			for slot in taker_array:
				printt(counters, slot.get_max_hp(), slot.damage_counters)
				counters += slot.get_max_hp() - slot.damage_counters - 10
			counters /= 10
	
	if comparator:
		if plus:
			counters += comparator.start_comparision() * modifier
		else:
			counters -= comparator.start_comparision() * modifier
	
	dmg_manip.max_counters = counters
	dmg_manip.first_ask = ask
	dmg_manip.second_ask = takers
	dmg_manip.mode = mode
	dmg_manip.prevent_ko = prevent_KO
	
	Globals.full_ui.set_top_ui(dmg_manip)
	
	await dmg_manip.finished
	
	SignalBus.remove_top_ui.emit()

func swap_manip(reversable: bool = false, replace_num: int = -1):
	var first: PokeSlot = await Globals.fundies.card_player.get_choice_candidates(
		str("Choose a damaged pokemon [Swap ", how_many," Counter(s)]"), 
		func(slot: PokeSlot):
			if slot.damage_counters > 0:
				return ask.check_ask(slot)
				, reversable)
	if first == null: return
	
	#var final_ammount: int = clamp(how_many * 10, 0, first.get_pokedata().HP - first.damage_counters)
	var final_ammount: int = how_many * 10
	
	@warning_ignore("integer_division")
	var second: PokeSlot = await Globals.fundies.card_player.get_choice_candidates(
		str("Place ", how_many," Counter(s) onto which pokemon?"),
		func(slot: PokeSlot):
			if slot != first:
				return takers.check_ask(slot)
			, reversable)
	if second == null: return
	
	first.dmg_manip(-1 * final_ammount, turn_delay)
	second.dmg_manip(final_ammount, turn_delay)

func get_final_ammount(counters: int, slot: PokeSlot) -> int:
	var ammount: int = counters
	if counters == -1:
		ammount = slot.get_max_hp() - slot.damage_counters
		if prevent_KO:
			ammount -= 10
	
	return ammount
