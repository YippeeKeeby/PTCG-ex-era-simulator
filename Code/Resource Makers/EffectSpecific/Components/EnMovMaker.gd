@icon("res://Art/ProjectSpecific/swap.png")
extends Resource
class_name EnMov

##[enum Send] takes attatched energy and moves it to the [member to_stack][br]
##[enum Swap] takes attatched energy and looks for a second candidate to attatch it to[br]
##[enum Attatch] Using energy found in [member to_stack] attatch energy to this mon 
@export_enum("Send", "Swap", "Attatch") var action: int = 0
##If the chooser is [enum Consts.SIDES.NONE], then default to [enum Consts.SIDES.SOURCE]
@export var chooser: Consts.SIDES = Consts.SIDES.SOURCE
@export var givers: SlotAsk
@export_group("From - To")
##If they targets from slot ask will determine if they're allowed
@export var reciever: SlotAsk
##Targets for removal
@export var to_stack: Consts.STACKS = Consts.STACKS.DISCARD
@export_enum("Top", "Bottom", "Eh") var stack_direction: int = 2
@export_group("Energy")
##If this is true, instead limit actions based on number of energy allowed to swap
@export var energy_carry_over: bool = false
##How many times are you allowed to perform [member action]. -1 means infinite
@export var action_ammount: int = 1
##Ammount of energy per action. -1 means infinite.
@export var energy_ammount: int = 1
@export_enum("Basic", "Special", "Any") var energy_move_type: int = 0
##If any energy is currently considered
@export var en_type: EnData = preload("res://Resources/Components/EnData/Rainbow.tres")

signal finished

func play_effect(reversable: bool = false, replace_num: int = -1) -> void:
	print("PLAY ENMOV")
	match action:
		0:
			await send_effect(reversable)
		1:
			await swap_effect(reversable)
		2:
			await attatch_effect(reversable)
	
	finished.emit()

#--------------------------------------=
#region EFFECTS
func send_effect(reversable: bool = false) -> void:
	Globals.fundies.card_player.set_reversable(reversable)
	var giver_call: Callable = func(slot: PokeSlot):
		return slot.energy_cards.size() != 0 and givers.check_ask(slot)
	
	#Get whichever meant to discard
	var candidate: PokeSlot = await Globals.fundies.card_player.get_choice_candidates(\
	"Choose a Pokemon", giver_call, reversable)
	
	if candidate == null:
		SignalBus.went_back.emit()
		return
	
	print(candidate.energy_cards, candidate.count_diff_energy())
	if candidate.count_diff_energy() == 1 and not reversable:
		candidate.remove_energy(candidate.energy_cards[0])
	else:
		var en_dict: Dictionary[Base_Card, bool]
		for en in candidate.energy_cards:
			var duplicated: Base_Card = en.duplicate(true)
			en_dict[duplicated] = energy_allowed(en, false)
		
		var dis_box: DiscardList = Globals.fundies.stack_manager.spawn_discard_list(
			en_dict, Consts.STACKS.PLAY, to_stack)
		
		dis_box.pokeslot_origin = candidate
		dis_box.home = Globals.fundies.get_considered_home(givers.side_target)
		dis_box.discard_num = energy_ammount
		dis_box.header_txt = str(candidate.get_card_name(),"'s Energy")
		dis_box.footer_prefix = str("Energy Left: ")
		dis_box.action_txt = str("Send to ",Convert.stack_into_string(to_stack))
		if reversable: dis_box.allow_reverse()
		
		Globals.full_ui.set_top_ui(dis_box)
		await dis_box.finished
		if dis_box.discarded:
			SignalBus.remove_top_ui.emit()
	
	finished.emit()

func swap_effect(reversable: bool = false) -> void:
	var new_box: SwapBox = Consts.swap_box.instantiate()
	#Globals.fundies.get_considered_home(chooser)
	new_box.swap_rules = self.duplicate()
	new_box.side = Globals.full_ui.get_const_side(givers.side_target)
	new_box.singles = Globals.full_ui.singles
	new_box.action_max = action_ammount
	new_box.energy_max = energy_ammount
	new_box.energy_move_type = energy_move_type
	new_box.carry_over = energy_carry_over
	new_box.giver_ask = givers
	new_box.reciever_ask = reciever
	
	if reversable: new_box.make_closable()
	
	Globals.full_ui.set_top_ui(new_box)
	await new_box.tree_exited
	
	finished.emit()

func attatch_effect(reversable: bool = false) -> void:
	var attatch_box: AttatchBox = Consts.attatch_box.instantiate()
	var hand_dict: Dictionary[Base_Card, bool]
	var hand: Array[Base_Card] = Globals.fundies.stack_manager.get_stacks(
		Globals.fundies.get_considered_home(reciever.side_target)).hand
	
	for card in hand:
		if card.energy_properties and not card.pokemon_properties:
			hand_dict[card] = en_type.same_type(card.energy_properties.fail_provide)
		else:
			hand_dict[card] = false
	
	attatch_box.list = hand_dict
	attatch_box.side = Globals.full_ui.get_const_side(reciever.side_target)
	attatch_box.singles = Globals.full_ui.singles
	attatch_box.action_ammount = action_ammount
	attatch_box.energy_ammount = energy_ammount
	attatch_box.reciever_ask = reciever
	
	Globals.full_ui.set_top_ui(attatch_box)
	await  attatch_box.finished
	
	finished.emit()
#endregion
#--------------------------------------

func swap(giver: PokeSlot, rec: PokeSlot, energy_giving: Array[Base_Card]):
	var left: Array[Base_Card] = energy_giving.duplicate()
	
	for en in energy_giving:
		for card in giver.energy_cards:
			if card.same_card(en):
				left.erase(en)
				giver.energy_cards.erase(en)
				break
	
	if left.size() != 0:
		printerr(left," has ",left.size()," cards left")
	
	for en in energy_giving:
		rec.add_energy(en)
	
	giver.refresh()

#--------------------------------------
#region BOOL RETURNS
func energy_allowed(card: Base_Card, fail: bool) -> bool:
	var current_en: EnData = card.energy_properties.get_current_provide()
	var is_react: bool = (en_type.react and en_type.react == current_en.react) or not en_type.react
	var same: bool = energy_move_type == 2 or\
	 (energy_move_type == 1 and card.energy_properties.considered == "Special Energy")\
	 or (energy_move_type == 0 and card.energy_properties.considered == "Basic Energy")
	
	
	return current_en.same_type(en_type) and same and is_react

func enough_energy(ammount: int) -> bool:
	return energy_ammount != -1 and ammount == energy_ammount 

func enough_actions(ammount: int) -> bool:
	return action_ammount != -1 and ammount == action_ammount
#endregion
#--------------------------------------
