extends Node

@warning_ignore_start("unused_signal")
#--------------------------------------
#region SIGNALS
#--------------------------------------
#region STACK SIGNALS
signal show_list(home: bool, list: Consts.STACKS, act: Consts.STACK_ACT)
signal show_energy_attatched(origin: PokeSlot)
signal make_placement(card: Array[Base_Card], placement: Placement, from: Consts.STACKS)
signal reorder_cards(card: Array[Base_Card], placement: Placement,)
signal start_tutor(search: Search)
signal tutor_card(card: Base_Card)
signal cancel_tutor(button: Button)
#endregion
#--------------------------------------
#region SLOT SIGNALS
signal chosen_slot(showing: PokeSlot)
signal main_attack(slot: PokeSlot, attack: Attack)
signal trigger_attack(slot: PokeSlot, attack: Attack)
signal disable_attack(slot: PokeSlot, attack: Attack)
signal retreat(slot: PokeSlot)
signal ability_activated()
signal ability_checked()
signal force_disapear()
signal end_turn()
#endregion
#--------------------------------------
#region CARD PLAY SIGNALS
signal play_basic(card: Base_Card)
signal play_evo(card: Base_Card)
signal play_trainer(card: Base_Card)
signal play_stadium(card: Base_Card)
signal play_tool(card: Base_Card)
signal play_tm(card: Base_Card)
signal play_fossil(card: Base_Card)
signal play_energy(card: Base_Card)
#endregion
#--------------------------------------
#region EFFECT SIGNALS
signal get_candidate(pokeSlot: PokeSlot)
signal went_back
signal finished_coinflip()
signal prompt_answered(answer: bool)
signal begin_swap(giver: PokeSlot, reciever: PokeSlot, energy: Array[Base_Card])
signal slot_change_failed(change: SlotChange)
signal trigger_finished
#endregion
#--------------------------------------
signal record_src_trg(home: bool, atk_stack: Array[PokeSlot], def_stack: Array[PokeSlot])
signal record_src_trg_from_prev(slot: PokeSlot)
signal record_src_trg_self(slot: PokeSlot)
signal remove_src_trg()
signal remove_top_ui()
signal empty_ui()
signal hide_ui()
signal finished_remove_top_ui()

#endregion
#--------------------------------------
@warning_ignore_restore("unused_signal")

func call_action(action: int, card: Base_Card) -> void:
	match action:
		0:
			play_basic.emit(card)
		1:
			play_evo.emit(card)
		4:
			play_stadium.emit(card)
		5:
			play_tool.emit(card)
		6:
			play_tm.emit(card)
		8:
			play_fossil.emit(card)
		9:
			play_energy.emit(card)
		_:
			play_trainer.emit(card)
	print("PLAY AS ", Consts.allowed_list_flags[action])

func connect_to(functions: Array[Callable]) -> void:
	var signals: Array[Signal] = [play_basic, play_evo, play_stadium,
	 play_tool, play_tm, play_fossil, play_energy, play_trainer]
	
	for i in range(functions.size()):
		signals[i].connect(functions[i])
