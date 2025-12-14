@icon("res://Art/ProjectSpecific/recycle-bin.png")
extends Resource
class_name CardDisrupt

##[enum Stack] sends cards in a stack that meet [member card_options] requirements
##[enum Slot] sends card and anything else attatched to it[br]
##[enum Evolution] just sends the evolution card back[br]
##[enum Attatched] sends any cards attatched to a slot but not the card itself
@export_enum("Stack", "Slot", "Evolution", "Attatched") var send: String = "Stack"
@export var send_to: Consts.STACKS = Consts.STACKS.DISCARD
##Should the card be sent to the top of it's stack, usually for discard that's yes
@export var top_stack: bool = true
@export var shuffle: bool = false
##-1 mean remove all possible. This variable is ignored if [member variable_ammount] is filled
@export var card_ammount: int = 1
@export var variable_ammount: Comparator
@export var reveal: bool = false
@export var who_chooses: Consts.SIDES = Consts.SIDES.SOURCE

@export_group("Choose From")
@export var side: Consts.SIDES = Consts.SIDES.DEFENDING
@export var card_options: Identifier
##If this is false then you cannot view the card being sent, depending on where, the results differ
##[br][i]ex. it's random from the hand but takes the top card from deck
@export var view: bool = true
@export var portion: int = -1
@export var from_stack: Consts.STACKS = Consts.STACKS.HAND
##If it's -1, choose every possible choice acoording to [member in_play_options] 
@export_range(-1,6,1) var slot_choose_num: int = -1
@export var in_play_options: SlotAsk

signal finished

#Find a way to not discard the card playing the effect
func play_effect(reversable: bool = false, replace_num: int = -1) -> void:
	print("PLAY DISRUPT")
	var home: bool = Globals.fundies.get_considered_home(side)
	var stacks: CardStacks = Globals.fundies.stack_manager.get_stacks(home)
	var chooser: Consts.PLAYER_TYPES = Globals.full_ui.get_player_type(who_chooses)
	var list: Dictionary[Base_Card, bool] = stacks.identifier_search(from_stack, card_options, [], portion)
	var num: int = card_ammount
	if variable_ammount:
		num = variable_ammount.start_comparision()
		if num < 1:
			finished.emit()
			return
	
	#Player shouldn't be able to disrupt the card playing the effect
	if Globals.fundies.card_player.hold_playing:
		list[Globals.fundies.card_player.hold_playing] = false
	
	#Discard from a stack
	if send == "Stack":
		#Choose
		if view:
			var disc_box: DiscardList = Consts.discard_box.instantiate()
			
			disc_box.list = list
			disc_box.stack = from_stack
			disc_box.stack_act = Consts.STACK_ACT.DISCARD
			disc_box.destination = send_to
			disc_box.discard_num = num
			disc_box.home = Globals.fundies.get_considered_home(side)
			disc_box.energy_discard = false
			disc_box.top_deck = top_stack
			disc_box.shuffle = shuffle
			if reversable:
				disc_box.allow_reverse()
			
			Globals.full_ui.set_top_ui(disc_box)
			await disc_box.finished
			SignalBus.remove_top_ui.emit()
		#Random
		else:
			var disc_from: Array[Base_Card]
			var lets_discard: Array[Base_Card]
			
			for card in list:
				if list[card]:
					disc_from.append(card)
			for i in num:
				lets_discard.append(disc_from.pick_random())
			print("Let's Discard...")
			for card in lets_discard:
				print(card.get_formal_name())
			
			stacks.move_cards(lets_discard, from_stack, send_to, shuffle, top_stack)
	
	#Discard from a slot
	else:
		var slots: Array[PokeSlot] = Globals.full_ui.get_ask_minus_immune(in_play_options, Consts.IMMUNITIES.ATK_EFCT_OPP)
		
		#Specified number of mons to disrupt
		if slot_choose_num != -1:
			var picked: Array[PokeSlot]
			for i in range(slot_choose_num):
				var disrupting: PokeSlot = await Globals.fundies.card_player.get_choice_candidates(
					"Which cards will you disrupt?", func(slot: PokeSlot): return slot.is_filled() and\
					slot in slots and not slot in picked, reversable, chooser)
				if disrupting == null:
					return
				picked.append(disrupting)
			#Only move what was picked out
			slots = picked
		
		#move all cards in slot accoording to identifier
		var moving_cards: Array[Base_Card]
		for slot in slots:
			moving_cards.append_array(slot.card_disrupteed(card_options, send)\
				if card_options else slot.remove_all())
			for card in moving_cards:
				print(card.get_formal_name())
		
		stacks.move_cards(moving_cards, Consts.STACKS.PLAY, send_to, shuffle, top_stack)
	
	Globals.full_ui.get_home_side(home).non_mon.sync_stacks()
	finished.emit()
