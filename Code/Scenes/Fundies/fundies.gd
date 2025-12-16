@icon("res://Art/ProjectSpecific/cards.png")
extends Node
class_name Fundies

#--------------------------------------
#region VARIABLES
@export var board: BoardNode
@export var first_turn: bool = false
@export var attatched_energy: bool = false

@onready var ui_actions: SlotUIActions = $UIActions
@onready var stack_manager: StackManager = $StackManager
@onready var card_player: CardPlayer = $CardPlayer
@onready var pass_turn_graphic: Control = $PassTurnGraphic

var turn_number: int = 1
var home_turn: bool = true
var atk_efect: bool = false
var home_targets: Array[Array]
var away_targets: Array[Array]
var source_stack: Array[bool]
var used_turn_abilities: Array[String]
var used_emit_abilities: Array[String]
var side_buffs: Dictionary[bool, Dictionary] = {true:{}, false:{}}
var side_disables: Dictionary[bool, Dictionary] = {true:{}, false:{}}
var side_overrides: Dictionary[bool, Dictionary] = {true:{}, false:{}}
var side_typechanges: Dictionary[bool, Dictionary] = {true:{}, false:{}}
var side_rulechanges: Dictionary[bool, Dictionary] = {true:{}, false:{}}
var cpu_players: Array[CPU_Player]

#endregion
#--------------------------------------

func _ready() -> void:
	Globals.fundies = self
	SignalBus.end_turn.connect(next_turn)
	SignalBus.slot_change_failed.connect(remove_change)
	SignalBus.record_src_trg.connect(record_attack_src_trg)
	SignalBus.record_src_trg_self.connect(record_single_src_trg)
	SignalBus.record_src_trg_from_prev.connect(record_prev_src_trg_from_self)
	SignalBus.remove_src_trg.connect(remove_top_source_target)

#--------------------------------------
#region PRINT
func current_turn_print():
	#Get the side that's attacking
	print("CURRENT ATTACKER")
	Globals.full_ui.get_home_side(home_turn).print_status()
	
	#Get the side that's defending
	print("CURRENT DEFENDER")
	Globals.full_ui.get_home_side(not home_turn).print_status()
	
	print_simple_slot_types()

func print_simple_slot_types():
	print("-------------------------")
	#GET ATTACKING
	print_slots(Consts.SIDES.ATTACKING, Consts.SLOTS.ALL, "ATTACKING SLOTS: ")
	print_slots(Consts.SIDES.DEFENDING, Consts.SLOTS.ALL, "DEFENDING SLOTS: ")
	print_slots(Consts.SIDES.BOTH, Consts.SLOTS.ACTIVE, "ACTIVE SLOTS: ")
	print_slots(Consts.SIDES.BOTH, Consts.SLOTS.BENCH, "BENCH SLOTS: ")
	print("-------------------------")

func print_slots(sides: Consts.SIDES, slots: Consts.SLOTS, init_string: String):
	var slot_string: String = init_string
	for slot in Globals.full_ui.get_slots(sides, slots):
		if not slot.connected_slot.is_filled():
			continue
		slot_string = str(slot_string, "[", slot.connected_slot.current_card.name, "]")
	
	print(slot_string, "\n")
#endregion
#--------------------------------------

#--------------------------------------
#region HELPERS
func get_side_ui() -> CardSideUI:
	return Globals.full_ui.get_home_side(home_turn)

func get_considered_home(side: Consts.SIDES):
	match side:
		Consts.SIDES.ATTACKING:
			return home_turn
		Consts.SIDES.DEFENDING:
			return not home_turn
		Consts.SIDES.SOURCE:
			return get_source_considered()
		Consts.SIDES.OTHER:
			return not get_source_considered()

func is_home_side_player() -> bool:
	var check_side = board.board_state.home_side\
	 if home_turn else board.board_state.away_side
	
	return check_side == Consts.PLAYER_TYPES.PLAYER

func get_current_player():pass

func can_be_played(card: Base_Card) -> int:
	if check_play_disable(card):
		return false
	
	var considered: int = Convert.get_card_flags(card)
	var allowed_to: int = 0
	#Basic
	if considered & 1 != 0:
		if find_allowed_slots(func(slot: PokeSlot): 
			return not slot.is_filled(), Consts.SIDES.ATTACKING).size() != 0:
				allowed_to += 1
			
		if check_override_evo(card):
			allowed_to += 2
	
	#Evo
	if considered & 2 != 0:
		var can_evo_from = Globals.make_can_evo_from(card)
		if find_allowed_slots(can_evo_from, Consts.SIDES.ATTACKING).size() != 0:
			allowed_to += 2
		else:
			print(card.name, " can't evolve from any current slot")
	#Item
	if considered & 4 != 0:
		allowed_to += 4
	#Supporter
	if considered & 8 != 0:
		if (not Globals.full_ui.get_home_side(home_turn).supporter_played() and not first_turn)\
		 or Globals.board_state.debug_unlimit:
			allowed_to += 8
	#Stadium
	if considered & 16 != 0:
		allowed_to += 16
	#Tool
	if considered & 32 != 0:
		if find_allowed_slots(func (slot: PokeSlot):\
		 return slot.tool_card == null, Consts.SIDES.ATTACKING).size() != 0:
			allowed_to += 32
	#TM
	if considered & 64 != 0:
		allowed_to += 64
	#RSM
	if considered & 128 != 0:
		allowed_to += 128
	#Fossil
	if considered & 256 != 0 and find_allowed_slots(func(slot: PokeSlot):
		return not slot.is_filled(),
		Consts.SIDES.ATTACKING).size() != 0:
			allowed_to += 256
	#Energy
	if (considered & 512 and not attatched_energy) or Globals.board_state.debug_unlimit:
		allowed_to += 512
	return allowed_to

func check_all_passives() -> void:
	for ui in Globals.full_ui.every_slot:
		if ui.connected_slot.is_filled():
			ui.connected_slot.check_passive()

func used_ability(ability_name: String) -> bool:
	return used_turn_ability(ability_name) or used_emit_ability(ability_name)

func used_turn_ability(ability_name: String) -> bool:
	return ability_name in used_turn_abilities

func used_emit_ability(ability_name: String) -> bool:
	return ability_name in used_emit_abilities

func clear_emit_abilities() -> void:
	used_emit_abilities.clear()

#endregion
#--------------------------------------

#--------------------------------------
#region SLOT FUNCTIONS
func find_allowed_slots(condition: Callable, sides: Consts.SIDES,\
 slots: Consts.SLOTS = Consts.SLOTS.ALL) -> Array[UI_Slot]:
	return Globals.full_ui.get_slots(sides, slots).filter(func(uislot: UI_Slot):\
	 return condition.call(uislot.connected_slot))

#region TARGET SOURCE MANAGEMENT
func record_attack_src_trg(is_home: bool, atk_trg: Array, def_trg: Array):
	source_stack.append(is_home)
	if is_home:
		home_targets.append(atk_trg)
		away_targets.append(def_trg)
	else:
		home_targets.append(def_trg)
		away_targets.append(atk_trg)

#First record then print out what I can get from this, then rmeove when used up
func record_source_target(is_home: bool, home_trg: Array, away_trg: Array):
	source_stack.append(is_home)
	home_targets.append(home_trg)
	away_targets.append(away_trg)

func record_single_src_trg(slot: PokeSlot):
	var home_trg: Array = []
	var away_trg: Array = []
	var is_home: bool = slot.is_home()
	
	if is_home: home_trg.append(slot)
	else: away_trg.append(slot)
	
	record_source_target(is_home, home_trg, away_trg)

##This function will record a src_trg stack with a new source item that equals the caller's side
func record_prev_src_trg_from_self(slot: PokeSlot):
	source_stack.append(slot.is_home())
	home_targets.append(home_targets[-1])
	away_targets.append(away_targets[-1])

func remove_top_source_target():
	source_stack.pop_back()
	home_targets.pop_back()
	away_targets.pop_back()
	
	if source_stack.size() == 0:
		print(source_stack)

func get_first_target(source: bool) -> PokeSlot:
	return home_targets[-1][0] if source_stack[-1] == source else away_targets[-1][0]

func get_targets() -> Array:
	return home_targets[-1] + away_targets[-1]

func get_source_considered() -> bool:
	return source_stack[-1]

func get_single_src_trg() -> PokeSlot:
	var src_stack = home_targets[-1] if source_stack[-1] else away_targets[-1]
	
	if src_stack.size() != 1:
		printerr("Using ", get_single_src_trg, " when the source stack's size is greater than 1")
	
	return home_targets[-1][-1] if source_stack[-1] else away_targets[-1][-1]

func print_src_trg():
	print("----------------------------------------------------------")
	print_slots(Consts.SIDES.SOURCE, Consts.SLOTS.ALL, "SOURCE SLOTS: ")
	print_slots(Consts.SIDES.BOTH, Consts.SLOTS.TARGET, "TARGET SLOTS: ")
	print("----------------------------------------------------------")

#endregion
#endregion
#--------------------------------------

#--------------------------------------
#region SLOT CHANGE MANAGEMENT
func get_side_change(change_class: String, home_val: bool) -> Dictionary:
	var dict: Dictionary
	match change_class:
			"Buff":
				dict = side_buffs
			"Disable":
				dict = side_disables
			"Override":
				dict = side_overrides
			"TypeChange":
				dict = side_typechanges
			"RuleChange":
				dict = side_rulechanges
	
	return dict[home_val] as Dictionary[SlotChange, int]

func get_applied_side_changes(change_class: String, slot: PokeSlot) -> Dictionary:
	var dict: Dictionary
	var filter_from: Dictionary = get_side_change(change_class, slot.is_home())
	
	for change in filter_from:
		if change.recieves.check_ask(slot):
			dict[change] = filter_from[change]
	
	return dict

func get_all_side_changes(home_val: bool) -> Dictionary[String, Dictionary]:
	return {"Buff" : side_buffs[home_val], "Disable" : side_disables[home_val],
	 "Override" : side_overrides[home_val], "TypeChange" : side_typechanges[home_val],
	 "RuleChange" : side_rulechanges[home_val]}

func apply_change(ask: SlotAsk, applying: SlotChange):
	for side in Globals.full_ui.sides:
		var dict = get_side_change(applying.get_script().get_global_name(), side.home)
		
		printt(side.is_side(ask.side_target), not applying in dict, dict, applying)
		if side.is_side(ask.side_target) and\
		not applying in dict:
			dict[applying] = applying.duration
			Globals.full_ui.display_changes(side.home, get_all_side_changes(side.home).values())

func remove_change(removing: Array[SlotChange]):
	for change in removing:
		for home in [true, false]:
			var dict: Dictionary = get_side_change(change.get_script().get_global_name(), home)
			if change in dict:
				dict.erase(change)
				Globals.full_ui.display_changes(home, get_all_side_changes(home).values())
		for slot in Globals.full_ui.get_poke_slots():
			slot.remove_slot_change(change)

func allowed_against(change: SlotChange, against: PokeSlot) -> bool:
	if change.against:
		if change.against.check_ask(against):
			return true
	else:
		return true
	return false

#region BUFF CHECKS
func full_check_stat_buff(slot: PokeSlot, stat: Consts.STAT_BUFFS,
 adding: bool = true, after: bool = true) -> int:
	var total: int = 0
	
	print(side_buffs[slot.is_home()])
	
	total += check_stat_buff(side_buffs[slot.is_home()], stat, adding)
	total += check_stat_buff(slot.get_changes("Buff"), stat, adding)
	
	return total

#For HP, RETREAT and ATK replacements
func check_stat_buff(dict: Dictionary, stat: Consts.STAT_BUFFS,
 adding: bool) -> int:
	var total: int = 0
	for change in dict:
		if change is Buff:
			change = change as Buff
			var after_allowed: bool = (change.operation == "Add") == adding
			
			if after_allowed and change.has_stat(stat):
				if adding:
					total += change.get_stat(stat)
				else:
					total = change.get_stat(stat)
	
	return total

func check_against_stat_buff(from: PokeSlot, against: PokeSlot, dict: Dictionary,
 stat: Consts.STAT_BUFFS, after: bool):
	var total: int = 0
	for change in dict:
		if not change is Buff: continue
		change = change as Buff
		
		if after == change.after_weak_res and change.has_stat(stat):
			if allowed_against(change, against):
				total += change.get_stat(stat)
	
	return total

func atk_def_buff(attacker: PokeSlot, defender: PokeSlot, after: bool) -> int:
	var final: int = check_against_stat_buff(attacker, defender, attacker.get_changes("Buff"),
	 Consts.STAT_BUFFS.ATTACK, after) + check_against_stat_buff(attacker,\
	 defender, side_buffs[attacker.is_home()], Consts.STAT_BUFFS.ATTACK, after)
	
	record_prev_src_trg_from_self(defender)
	
	final -= check_against_stat_buff(defender, attacker, defender.get_changes("Buff"),
	 Consts.STAT_BUFFS.DEFENSE, after) + check_against_stat_buff(defender, \
	 attacker, side_buffs[defender.is_home()], Consts.STAT_BUFFS.DEFENSE, after)
	
	remove_top_source_target()
	
	return final

func filter_immune(immunity: Consts.IMMUNITIES, slots: Array[PokeSlot]) -> Array[PokeSlot]:
	if atk_efect:
		var against: PokeSlot = get_first_target(true)
		print("Before: ", slots)
		slots = slots.filter(func(slot: PokeSlot): return not slot.is_attacker() and slot.is_filled()\
			and not check_immunity(Consts.IMMUNITIES.ATK_EFCT_OPP, against, slot))
		print("After: ", slots)
		
	return slots

#https://compendium.pokegym.net/compendium-ex.html#two_on_two_gameplay
#Holon Energy WP and Ancient Technical Machine [Ice] only prevent effects
#that come from attacks, not all effects in play. Trainer cards, Poké-Powers, and Poké-Bodies are not prevented by those cards. (Jul 25, 2006 PUI Announcements) 
func has_immune(immunity: Consts.IMMUNITIES, dict: Dictionary, against: PokeSlot):
	for change in dict:
		if not change is Buff: continue
		
		change = change as Buff
		match immunity:
			Consts.IMMUNITIES.DMG_OPP:
				if change.damage_immune and allowed_against(change, against):
					return true
			Consts.IMMUNITIES.ATK_EFCT_OPP:
				if change.attack_effect_immune and allowed_against(change, against):
					return true
			Consts.IMMUNITIES.PWR_EFCT_OPP:
				if change.power_immune and allowed_against(change, against):
					return true
			Consts.IMMUNITIES.BDY_EFCT_OPP:
				if change.body_immune and allowed_against(change, against):
					return true
			Consts.IMMUNITIES.TR_EFCT_OPP:
				if change.trainer_immune and allowed_against(change, against):
					return true
			Consts.IMMUNITIES.EVEN:
				if change.even_immunity and allowed_against(change, against):
					return true
			Consts.IMMUNITIES.ODD:
				if change.odd_immunity and allowed_against(change, against):
					return true

func check_immunity(immunity: Consts.IMMUNITIES, attacker: PokeSlot, defender: PokeSlot):
	if not atk_efect and immunity == Consts.IMMUNITIES.ATK_EFCT_OPP:
		return false
	#There are no affects that provide immunities to source side
	if attacker.is_attacker() == defender.is_attacker():
		return false
	
	record_prev_src_trg_from_self(defender)
	if defender.get_changes("Buff").size() > 0:
		if has_immune(immunity, defender.get_changes("Buff"), attacker):
			return true
		elif has_immune(immunity, side_buffs[defender.is_home()], attacker):
			return true
	remove_top_source_target()
	
	return false

func has_pierce():
	pass

func check_pierce():
	pass

func has_cond_immune():
	pass

func check_condition_immune(cond: int, defender: PokeSlot):
	for change in defender.get_changes("Buff"):
		if not change is Buff: continue
		
		change = change as Buff
		if change.condition_immune & cond != 0:
			return true
	
	return false
#endregion

#region DISABLE CHECKS
func check_attack_disable():
	pass

func check_play_disable(card: Base_Card):
	var dict = get_side_change("Disable", home_turn)
	for dis in dict:
		if not dis is Disable: continue
		dis = dis as Disable
		
		if dis.card_type and dis.card_type.identifier_bool(card):
			return true
	
	return false
#endregion

#region OVERRIDE CHECK
func check_override_evo(card: Base_Card):
	var atk: Array[PokeSlot] = Globals.full_ui.get_poke_slots(Consts.SIDES.ATTACKING)
	var dict = get_side_change("Override", home_turn).duplicate()
	for slot in atk:
		dict.merge(slot.get_changes("Override").duplicate())
	
	for ov in dict:
		if not ov is Override: continue
		ov = ov as Override
		
		if card.name in ov.can_evolve_into:
			return true
	
	return false

#endregion

#endregion
#--------------------------------------

func next_turn():
	print_rich("[center]--------------------------END TURN-------------------------")
	used_turn_abilities.clear()
	home_turn = not home_turn
	attatched_energy = false
	turn_number += 1
	
	await Globals.full_ui.set_between_turns()
	#When animations and other stuff are added for checkups, remove this
	await get_tree().create_timer(.1).timeout
	
	print_rich("[center]--------------------------TURN ", turn_number, "-------------------------")
	pass_turn_graphic.turn_change()
	await pass_turn_graphic.animation_player.animation_finished
	
	if stack_manager.get_stacks(home_turn).get_array(Consts.STACKS.DECK).size() == 0:
		print("You lose")
	else:
		stack_manager.draw(1)
	
	for player in cpu_players:
		player.can_operate()
