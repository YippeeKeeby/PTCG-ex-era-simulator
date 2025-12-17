@icon("res://Art/ExpansionIcons/40px-SetSymbolFireRed_and_LeafGreen.png")
extends Resource
class_name PokeSlot

#--------------------------------------
#region VARIABLES
@export var position_string: String = ""
@export var current_card: Base_Card
@export_range(0,400,10) var max_HP: int = 0
@export_range(0,400,10) var damage_counters: int = 0
@export_range(0,10,1) var final_retreat: int = 0
#--------------------------------------
#region NON EXPORT
var ui_slot: UI_Slot
var attached_energy: Dictionary = {"Grass": 0, "Fire": 0, "Water": 0,
	"Lightning": 0, "Psychic":0, "Fighting":0 ,"Darkness":0, "Metal":0,
	"Colorless":0, "Magma":0, "Aqua":0, "Dark Metal":0, "React": 0, 
	"Holon FF": 0, "Holon GL": 0, "Holon WP": 0, "Rainbow":0}
var energy_timers: Dictionary = {}
var damage_timers: Array[Dictionary]
var mimic_attacks: Array[Attack]
var body_exhaust: bool
var power_exhaust: bool
var body_activated: bool
var power_ready: bool

const SlotEnergyScript = preload("res://Code/Resource Makers/PokemonSpecific/SlotEnergyMaker.gd")
#endregion
#--------------------------------------
#--------------------------------------
#region ATTATCHED VARIABLES
@export_group("Attatchments")
@export var evolved_from: Array[Base_Card] = [] #
@export var energy_cards: Array[Base_Card] = []
@export var tm_cards: Array[Base_Card] = []
@export var tool_card: Base_Card
@export var applied_condition: Condition = Condition.new()
@export_subgroup("Slot Changes")
@export var all_changes: Dictionary[String, Dictionary] = {"Buff" : {},
 "Disable" : {}, "Override" : {}, "TypeChange" : {}, "RuleChange" : {}}
#endregion
#--------------------------------------
#--------------------------------------
#region TEMP CHANGES
@export_group("Temp Changes")
@export var current_en: SlotEnergy = preload("uid://j86icjgodnbl")
@export var evolution_ready: bool = false
@export var evolved_this_turn: bool = false
@export var body_disabled: bool = false
@export var power_disabled: bool = false
#endregion
#--------------------------------------
#--------------------------------------
#region HISTORY
@export_group("History")
@export var current_attack: Attack
@export var dealt_damage: int = 0
@export var energy_discarded: int = 0
var current_previous: Base_Card
#endregion
#--------------------------------------
#endregion
#--------------------------------------
#region SIGNALS
@warning_ignore_start("unused_signal")
signal swap(slot: Consts.SLOTS)
signal retreat()

signal will_take_dmg(attacker: PokeSlot)
signal take_dmg(attacker: PokeSlot)
signal ko()

signal attatched_tm(card: Base_Card)
signal attatched_tool(card: Base_Card)
signal evolved(slot: PokeSlot)
signal evolving(slot: PokeSlot)
signal attatch_en_signal(card: EnData)
signal discard_en_signal(card: EnData)
signal played(slot: Consts.SLOTS)
signal first_check
#played only activates when a pokemon is played from the hand as a basic
#first check activates whenever a pokemon is set as the current card, which includes devolution

signal condition_applied(condition: Condition)

signal attacks(slot: PokeSlot)
signal used_power()
signal checked_up()
#endregion
#--------------------------------------

func _init():
	print(SlotEnergy)
	print(typeof(SlotEnergy))
	print(load("uid://cs6h3rwo60eu5").has_method("new"))
	var new = SlotEnergy.new()
	pass

func pokemon_checkup() -> void:
	if not is_filled(): return
	evolved_this_turn = false
	evolution_ready = true
	body_exhaust = false
	power_exhaust = false
	
	await checkup_conditions()
	
	#region TIMERS
	for card in energy_timers.keys():
		if energy_timers[card] == 0 and not Globals.board_state.debug_unlimit:
			energy_timers.erase(card)
			remove_energy(card)
		else:
			energy_timers[card] -= 1
	
	for dmg_timer in damage_timers:
		dmg_timer["Timer"] -= 1
		if dmg_timer["Timer"] == 0:
			dmg_manip(dmg_timer["Damage"])
		else:
			print(dmg_timer)
	
	manage_change_timers()
	
#endregion
	
	Globals.fundies.stack_manager.get_stacks(is_home()).\
		move_cards(tm_cards, Consts.STACKS.PLAY, Consts.STACKS.DISCARD, false, true)
	for tm in tm_cards:
		remove_tm(tm)
	
	refresh()
	
	Globals.fundies.record_single_src_trg(self)
	await ability_emit(checked_up)
	Globals.fundies.remove_top_source_target()

#--------------------------------------
#region POWER/BODY
func setup_abilities():
	current_card = current_card.duplicate_deep()
	var mon: Pokemon = get_pokedata()
	#mon.duplicate_abilities()
	Globals.fundies.record_single_src_trg(self)
	
	if mon.pokebody:
		print(mon, get_debug_name())
		print(mon.pokebody, mon.pokebody.name)
		mon.pokebody.prep_ability(self)
		print(mon.pokebody, mon.pokebody.name)
	if mon.pokepower:
		mon.pokepower.prep_ability(self)
	Globals.fundies.remove_top_source_target()

func disconnect_abilities():
	if get_pokedata().pokebody:
		get_pokedata().pokebody.disconnect_ability()
	if get_pokedata().pokepower:
		get_pokedata().pokepower.disconnect_ability()

func check_passive():
	var pokedata: Pokemon = get_pokedata()
	Globals.fundies.record_single_src_trg(self)
	#Ability
	if pokedata.pokebody:
		if pokedata.pokebody.passive:
			print(get_debug_name(), " is activating passive")
			body_activated = pokedata.pokebody.activate_passive()
			
	if pokedata.pokepower:
		if pokedata.pokepower.passive:
			pokedata.pokepower.activate_passive()
		
		power_ready = pokedata.pokepower.does_press_activate(self)
	
	ui_slot.check_ability_activation()
	Globals.fundies.remove_top_source_target()

func use_ability(ability: Ability):
	Globals.fundies.record_single_src_trg(self)
	await ability.activate_ability()
	used_power.emit()
	Globals.fundies.remove_top_source_target()
	refresh()

func ability_emit(sig: Signal, param: Variant = null):
	print("Does ", get_card_name(), " have connections in ", sig, "? ", sig.has_connections())
	if sig.has_connections():
		#print(sig.get_connections())
		Globals.fundies.record_prev_src_trg_from_self(self)
		Globals.fundies.print_src_trg()
		#This feels wrong but it works if multiple abilities connect to the same signal
		if sig.get_connections().size() > 1:
			print("Source chooses the activation order")
			await Globals.fundies.card_player.decide_ability_order(sig.get_connections(), 
			param, Consts.PLAYER_TYPES.PLAYER)
		else:
			await ability_single_emit(sig, param)
		
		Globals.fundies.clear_emit_abilities()
		Globals.fundies.remove_top_source_target()
		refresh()

func ability_single_emit(sig: Signal, param: Variant = null):
	#This feels wrong but it works if multiple abilities connect to the same signal
	sig.emit(param)
	await SignalBus.ability_checked

func occurance_account_for():
	for slot in Globals.full_ui.get_occurance_slots():
		Globals.fundies.record_single_src_trg(slot)
		
		if slot.get_pokedata().pokebody != null:
			if slot.get_pokedata().pokebody == get_pokedata().pokebody and slot != self:
				printerr("Uh oh body same. Slot card comparison ", slot.current_card == current_card)
			slot.get_pokedata().pokebody.single_prep(self)
		if slot.get_pokedata().pokepower != null:
			if slot.get_pokedata().pokepower == get_pokedata().pokepower and slot != self:
				printerr("Uh oh powers same. Slot card comparison", slot.current_card == current_card)
			slot.get_pokedata().pokepower.single_prep(self)
		
		Globals.fundies.remove_top_source_target()

#endregion
#--------------------------------------

#--------------------------------------
#region HELPERS
func is_in_slot(desired_side: Consts.SIDES, desired_slot: Consts.SLOTS) -> bool:
	var side_bool: bool = false
	var slot_bool: bool = false
	
	#if not is_filled(): return false
	
	match desired_side:
		#var fund: Fundies = Globals.fundies
		Consts.SIDES.BOTH:
			side_bool = true
		Consts.SIDES.ATTACKING:
			side_bool = is_attacker()
		Consts.SIDES.DEFENDING:
			side_bool = not is_attacker()
		Consts.SIDES.SOURCE:
			side_bool = Globals.fundies.get_source_considered() == ui_slot.home
		Consts.SIDES.OTHER:
			side_bool = not Globals.fundies.get_source_considered() == ui_slot.home
	
	match desired_slot:
		Consts.SLOTS.ALL:
			slot_bool = true
		Consts.SLOTS.ACTIVE:
			slot_bool = is_active()
		Consts.SLOTS.BENCH:
			slot_bool = not is_active()
		Consts.SLOTS.TARGET:
			slot_bool = Globals.fundies.get_targets().has(self)
		Consts.SLOTS.REST:
			slot_bool = not Globals.fundies.get_targets().has(self)
	
	return slot_bool and side_bool

func get_card_name() -> String:
	return current_card.name if is_filled() else "null"

func is_filled() -> bool:
	return current_card != null

func is_active() -> bool:
	if ui_slot:
		return ui_slot.active
	else:
		return false

func is_home() -> bool:
	return ui_slot.home

func is_attacker() -> bool:
	return ui_slot.home == Globals.fundies.home_turn

func can_evolve_into(evolution: Base_Card) -> bool:
	return current_card.name == evolution.pokemon_properties.evolves_from\
	 and not evolved_this_turn and evolution_ready

func can_devolve() -> bool:
	return evolved_from.size()

func has_condition(conditions: Array = ["Poison", "Burn",
 Consts.TURN_COND.PARALYSIS, Consts.TURN_COND.ASLEEP, Consts.TURN_COND.CONFUSION]):
	for cond in conditions:
		match cond:
			"Poison":
				if applied_condition.poison > 0:
					return true
			"Burn":
				if applied_condition.burn > 0:
					return true
			"Imprison":
				if applied_condition.imprision:
					return true
			"Shockwave":
				if applied_condition.shockwave:
					return true
			_:
				if applied_condition.turn_cond == cond:
					return true
	
	return false

func get_side() -> Consts.SIDES:
	if is_attacker():
		return Consts.SIDES.ATTACKING
	return Consts.SIDES.DEFENDING

func get_slot_pos() -> Consts.SLOTS:
	if is_active():
		return Consts.SLOTS.ACTIVE
	return Consts.SLOTS.BENCH

func get_targets(atk: PokeSlot, def: Array[PokeSlot]) -> Array[Array]:
	var targets: Array[Array] = [[],[]]
	
	if atk.ui_slot.home:
		targets[0].append(atk)
		targets[1] = def
	else:
		targets[1].append(atk)
		targets[0] = def
	
	return targets

func get_pokedata() -> Pokemon:
	return current_card.pokemon_properties

func get_max_hp() -> int:
	return max_HP

func get_retreat() -> int:
	if get_changes("Buff").size() == 0: return get_pokedata().retreat
	
	var base: int = Globals.fundies.full_check_stat_buff(
		self, Consts.STAT_BUFFS.RETREAT, false, true)
	
	if base < 0:
		return 0
	else:
		base = get_pokedata().retreat
	
	base += Globals.fundies.full_check_stat_buff(
		self, Consts.STAT_BUFFS.RETREAT, true, true)
	
	return clamp(base, 0, 100)

func get_evo_attacks() -> Array[Attack]:
	var evo_attacks: Array[Attack]
	for card in evolved_from:
		evo_attacks.append_array(card.pokemon_properties.attacks)
	
	return evo_attacks

func has_occurance() -> bool:
	if get_pokedata().pokebody and get_pokedata().pokebody.occurance:
		return true
	if get_pokedata().pokepower and get_pokedata().pokepower.occurance:
		return true
	return false

#endregion
#--------------------------------------

#--------------------------------------
#region SLOTTING IN
#If the choice was reversablee, it's likely because it was played from the hand
#If I find examples that break this, I'll have to find another way
func use_card(card: Base_Card, play_as: int, from_hand: bool) -> void:
	#Play fossils, basics and evolutions onto the bench
	if play_as & 1 != 0 or play_as & 256 != 0:
		set_card(card, from_hand)
	elif play_as & 2 != 0:
		if current_card:
			evolve_card(card)
		else:
			set_card(card, from_hand)
	elif play_as & 32 != 0:
		attatch_tool(card)
	elif play_as & 64 != 0:
		attatch_tm(card)
	#play energy onto any pokemon defined by placement
	elif play_as & 512 != 0:
		add_energy(card)
	else:
		printerr("You probably can't pay ", card, " on a pokeslot as ", play_as)

func set_card(card: Base_Card, from_hand: bool) -> void:
	current_card = card
	ui_slot.make_allowed(true)
	refresh_current_card()
	
	Globals.fundies.record_single_src_trg(self)
	if from_hand:
		await ability_emit(played, get_slot_pos())
	Globals.fundies.remove_top_source_target()
	Globals.fundies.check_all_passives()

#General use function, use specific ones if possible
func remove_cards(cards: Array[Base_Card]) -> void:
	for card in cards:
		var removed: bool = false
		#Remove the tool card if it's here
		if tool_card and tool_card.same_card(card):
			remove_tool()
			continue
		#Remove the first energy card that matches this card
		for en in energy_cards:
			if en.same_card(card):
				remove_energy(en)
				removed = true
				break
		if removed: continue
		#Remove any evos if they're here
		for evo in evolved_from:
			if evo.same_card(card):
				devolve_card()
				removed = true

#endregion
#--------------------------------------

#--------------------------------------
#region DAMAGE HANDLERS
func should_ko() -> bool:
	return (get_max_hp() - damage_counters) < 0

func knock_out() -> void:
	await ability_emit(ko)

func add_damage(attacker: PokeSlot, base_ammount: int) -> void:
	if not is_filled() or base_ammount == 0: return
	if Globals.fundies.check_immunity(Consts.IMMUNITIES.DMG_OPP, attacker, self):
		return
	
	await ability_emit(will_take_dmg, attacker)
	
	var final_ammount = base_ammount + \
	Globals.fundies.atk_def_buff(attacker, self, false)
	
	if attacker.current_card.pokemon_properties.type & current_card.pokemon_properties.weak != 0:
		print(get_card_name(), " is weak to ", attacker.get_card_name())
		final_ammount *= 2
	if attacker.current_card.pokemon_properties.type & current_card.pokemon_properties.resist != 0:
		print(get_card_name(), " resists ", attacker.get_card_name())
		final_ammount -= 30
	
	final_ammount += Globals.fundies.atk_def_buff(attacker, self, true)
	
	final_ammount = clamp(final_ammount, 0, 990)
	
	if even_or_odd_immune(final_ammount, attacker):
		return
	
	print(get_card_name(), " TAKES: ", final_ammount, " DAMAGE!")
	damage_counters += final_ammount
	attacker.dealt_damage = final_ammount
	
	ui_slot.damage_counter.set_damage(damage_counters)
	Globals.fundies.check_all_passives()
	
	if final_ammount > 0:
		Globals.fundies.print_src_trg()
		await ability_emit(take_dmg, attacker)

func bench_add_damage(_ammount) -> void:
	return

#Q. Does Strength Charm affect self damage, like Wobbuffet's flip over attack?
#A. Yes - it affects damage done by the Attacking Pokémon. (Mar 25, 2004 PUI Rules Team) 
func self_damage(base_ammount: int) -> void:
	if not is_filled() or base_ammount == 0: return
	
	var final_ammount = base_ammount + \
	Globals.fundies.atk_def_buff(self, self, false)
	
	final_ammount = clamp(final_ammount, 0, 990)
	
	print(get_card_name(), " TAKES: ", final_ammount, " DAMAGE!")
	damage_counters += final_ammount
	dealt_damage = final_ammount
	
	ui_slot.damage_counter.set_damage(damage_counters)
	Globals.fundies.check_all_passives()
	
	if final_ammount > 0:
		Globals.fundies.print_src_trg()
		await ability_emit(take_dmg, self)

func even_or_odd_immune(dmg: int, attacker: PokeSlot) -> bool:
	if dmg <= 0 or dmg >= 190: return false
	
	if int(floori(dmg / 10.0)) % 2 == 0:
		return Globals.fundies.check_immunity(Consts.IMMUNITIES.EVEN, attacker, self)
	return Globals.fundies.check_immunity(Consts.IMMUNITIES.ODD, attacker, self)

#Won't trigger anything that happens on direct damage
func dmg_manip(dmg_change: int, timer: int = -1) -> void:
	if timer == -1:
		damage_counters += dmg_change
		damage_counters = clamp(damage_counters, 0, 990)
	else:
		damage_timers.append({"Damage" : dmg_change, "Timer" : timer})
	ui_slot.damage_counter.set_damage(damage_counters)

func set_max_hp():
	#First look for replacments
	var current: int = get_pokedata().HP
	if get_changes("Buff").size() != 0:
		var replace: int = Globals.fundies.full_check_stat_buff(
		self, Consts.STAT_BUFFS.HP, false, true)
		if replace != 0:
			current = replace
	
	#Then look for additions
	max_HP = current + Globals.fundies.full_check_stat_buff(
		self, Consts.STAT_BUFFS.HP, true, true)
	
	max_HP = clamp(max_HP, 0, 990)

#endregion
#--------------------------------------

#--------------------------------------
#region ENERGY HANDLERS
#region ADD/REMOVE
func signaless_attatch_energy(energy_card: Base_Card):
	energy_cards.append(energy_card)
	energy_card.energy_properties.attatched_to = self
	
	register_energy_timer(energy_card)
	refresh()

func signaless_remove_energy(removing: Base_Card):
	for card in energy_cards:
		if card.same_card(removing):
			card.emit_remove_change()  
			energy_cards.erase(card)
			refresh()
			return

func count_en_attatch_signals(en_cards: Array[Base_Card]):
	for card in en_cards:
		if card in energy_cards:
			Globals.fundies.record_single_src_trg(self)
			await ability_emit(attatch_en_signal, get_context_en_provide(card))
			Globals.fundies.remove_top_source_target()
		else:
			printerr(card.name, " isnt in ", get_card_name())

func count_en_remove_signals(en_provides: Array[EnData]):
	for prov in en_provides:
		Globals.fundies.record_single_src_trg(self)
		await ability_emit(discard_en_signal, prov)
		Globals.fundies.remove_top_source_target()

func add_energy(energy_card: Base_Card):
	Globals.fundies.record_single_src_trg(self)
	signaless_attatch_energy(energy_card)
	
	for effect in energy_card.energy_properties.attatch_effects:
		effect.effect_collect_play()
	
	await ability_emit(attatch_en_signal, get_context_en_provide(energy_card))
	Globals.fundies.remove_top_source_target()

func remove_energy(removing: Base_Card):
	var provide: EnData = get_context_en_provide(removing)
	signaless_remove_energy(removing)
	
	Globals.fundies.record_single_src_trg(self)
	await ability_emit(discard_en_signal, provide)
	Globals.fundies.remove_top_source_target()

func register_energy_timer(card: Base_Card):
	if card.energy_properties.turns != -1:
		energy_timers[card] = card.energy_properties.turns
#endregion

#region COUNTING
#Get whatever the energy provides both in type, number and effects
func count_energy() -> void:
	#Count if energy cars provided give the right energy for each attack
	#Each attackm will be treated differently
	#EG: Double magma will provide two dark for one attack but two fighting for another
	#It depends on which combination satisfies the cost
	attached_energy = {"Grass": 0, "Fire": 0, "Water": 0,
	 "Lightning": 0, "Psychic":0, "Fighting":0 ,"Darkness":0, "Metal":0,
	 "Colorless":0, "Magma":0, "Aqua":0, "Dark Metal":0, "React": 0, 
	 "FF": 0, "GL": 0, "WP": 0, "Rainbow":0}
	Globals.fundies.record_single_src_trg(self)
	
	for energy in energy_cards:
		if energy.energy_properties.attatched_to != self:
			energy.energy_properties.attatched_to = self
		var en_provide: EnData = get_context_en_provide(energy)
		var en_name: String = en_provide.get_string()
		attached_energy[en_name] += en_provide.number
		
		#print("Checking ", energy.name, energy, " in ", get_card_name())
		if not en_provide.ignore_effects:
			for effect in energy.energy_properties.prompt_effects:
				effect.effect_collect_play()
	
	Globals.fundies.remove_top_source_target()
	
	current_en.count_cards(self, energy_cards)
	pass

func get_energy_strings() -> Array[String]:
	var energy_stirngs: Array[String]
	
	for card in energy_cards:
		var en_provide: EnData = get_context_en_provide(card)
		var en_name: String = en_provide.get_string()
		for i in range(en_provide.number):
			energy_stirngs.append(en_name)
	
	print_verbose("BEFORE SORT: ", energy_stirngs)
	
	energy_stirngs.sort_custom(func(a,b): #Basic + Darkness + Metal has highest priority
		return Consts.energy_types.find(a) < Consts.energy_types.find(b))
	print_verbose("AFTER: ", energy_stirngs)
	
	return energy_stirngs

func count_diff_energy() -> int:
	var diff: int = 0
	var recorded: Array[String] = []
	for card in energy_cards:
		if not(card.name in recorded):
			diff += 1
			recorded.append(card.name)
	
	return diff

func get_total_energy(enData_filter: EnData = null, filtered_array: Array[Base_Card] = []) -> int:
	var total: int = 0
	var using: Array[Base_Card] = filtered_array if filtered_array.size() != 0 else energy_cards
	var skip_enData: bool = enData_filter == null or enData_filter.get_string() == "Rainbow"
	
	for card in using:
		var en_provide: EnData = get_context_en_provide(card)
		var add: bool = skip_enData or (en_provide.same_type(enData_filter))
		if add:
			total += en_provide.number
	
	return total

#When provides don't matter
func get_total_en_categories(category_filter: String = "Any") -> Array[Base_Card]:
	var final: Array[Base_Card]
	var skip_category: bool = category_filter == "Any"
	for card in energy_cards:
		var considered: String = card.energy_properties.considered
		if skip_category or considered == category_filter:
			final.append(card)
	return final

#Has a lot of work to do before ready
func get_energy_excess(enData_filter: EnData = null) -> int:
	print(current_attack.pay_cost(self))
	pass
	return get_total_energy(enData_filter) + current_attack.pay_cost(self)

func get_context_en_provide(card: Base_Card):
	SignalBus.record_src_trg_self.emit(self)
	var en: Energy = card.energy_properties
	var data: EnData = en.get_current_provide().duplicate()
	
	var overrides = get_changes("Override").keys() +\
	 Globals.fundies.get_applied_side_changes("Override", self).keys()
	
	for ov in overrides:
		if not ov is Override: continue
		ov = ov as Override
		
		if ov.converting and ov.becomes:
			var right_provide: bool = false
			
			if ov.provides_only:
				right_provide = ov.converting.same_en_data(data)
			else:
				right_provide = ov.converting.type & data.type != 0
			
			if (ov.en_category == "Any" or ov.en_category == en.considered)\
			 and right_provide:
				if ov.replace_num:
					data.number = ov.becomes.number
				if ov.replace_provide:
					data.type = ov.becomes.type
				else:
					data.type |= ov.becomes.type
				data.react = ov.becomes.react
				data.holon_type = ov.becomes.holon_type
					
				if ov.no_effects:
					data.ignore_effects = true
					
	
	SignalBus.remove_src_trg.emit()
	return data
#endregion

#endregion
#--------------------------------------

#--------------------------------------
#region OTHER ATTATCHMENTS
#Q. If a Pokémon uses "Baby Evolution", does it trigger Shiftry-EX's "Dark Eyes"?
#A. No. The Pokémon that used "Baby Evolution" is actually no longer in play. (Nov 16, 2006 PUI Rules Team) 
func evolve_card(evolution: Base_Card) -> void:
	Globals.fundies.record_single_src_trg(self)
	await ability_emit(evolving, self)
	disconnect_abilities()
	current_card.emit_remove_change()
	evolved_from.append(current_card)
	current_card = evolution
	refresh_current_card()
	
	alleviate_all()
	applied_condition.imprision = false
	applied_condition.shockwave = false
	refresh()
	await ability_emit(evolved, self)
	Globals.fundies.remove_top_source_target()

func devolve_card() -> Base_Card:
	var old_card: Base_Card = current_card
	
	disconnect_abilities()
	current_card = evolved_from.pop_back()
	old_card.emit_remove_change()
	
	alleviate_all()
	applied_condition.imprision = false
	applied_condition.shockwave = false
	refresh_current_card()
	refresh()
	return old_card

func attatch_tool(new_tool: Base_Card) -> void:
	if not tool_card:
		tool_card = new_tool
	else:
		push_error(current_card.name, " already has tool attatched")
	ui_slot.tool.show()
	ui_slot.tool.texture = tool_card.image
	
	refresh()
	
	Globals.fundies.record_single_src_trg(self)
	await ability_emit(attatched_tool, new_tool)
	Globals.fundies.remove_top_source_target()

func remove_tool() -> void:
	tool_card.emit_remove_change()
	tool_card = null
	ui_slot.tool.hide()
	refresh()

func attatch_tm(new_tm: Base_Card) -> void:
	tm_cards.push_front(new_tm)
	print("TMS: ",tm_cards)
	
	
	if tm_cards.size():
		ui_slot.tm.texture = tm_cards[0].image
		ui_slot.tm.show()
	refresh()
	
	Globals.fundies.record_single_src_trg(self)
	await ability_emit(attatched_tm, new_tm)
	Globals.fundies.remove_top_source_target()

func remove_tm(tm: Base_Card) -> void:
	tm_cards.erase(tm)
	if tm_cards.size() == 0:
		ui_slot.tm.hide()
	refresh()

func remove_all() -> Array[Base_Card]:
	var moving_cards: Array[Base_Card] = []
	
	if current_card:
		moving_cards.append(current_card) 
	if tool_card:
		moving_cards.append(tool_card)
	moving_cards.append_array(evolved_from)
	moving_cards.append_array(energy_cards)
	moving_cards.append_array(tm_cards)
	
	for card in moving_cards:
		card.emit_remove_change()
	
	current_card = null
	tool_card = null
	evolved_from.clear()
	energy_cards.clear()
	tm_cards.clear()
	
	ui_slot.clear()
	
	refresh()
	
	return moving_cards

#https://compendium.pokegym.net/compendium-ex.html#trainers
#Q. The effect text of "Plunder" says: "Before doing damage,
#discard all Trainer cards attached to the Defending Pokémon." So what happens to Fossils ..."
#A. Fossils are not "attached" to themselves, so they are not discarded by Plunder. (Feb 16, 2006 PUI Rules Team) 
#Q. If I have a Lileep evolved from a Root Fossil in play and my opponent uses ATM-Ice, what happens?
#A. ATM-Ice does not remove fossil cards that have already evolved into actual Pokémon. (Apr 14, 2005 PUI Rules Team) 
#Q. If I use the Ancient Technical Machine [Ice] and my opponent has Claw Fossil, Root Fossil, etc. in play are they discarded?
#A. Yes, Fossil cards are to be treated as both Trainer Cards and as Pokémon while in play. (Apr 5, 2005 PUI Announcements; Apr 7, 2005 PUI Rules Team)
func card_disrupteed(identifier: Identifier, rule: String) -> Array[Base_Card]:
	var moving_cards: Array[Base_Card]
	#CardDisrupt
	#Card and Attatch both remove attatched cards
	if rule != "Evolution":
		#Only if card
		if rule == "Slot":
			#If you can devolve remove all top evolutions untilidentifier stops it
			while can_devolve():
				if identifier.identifier_bool(current_card):
					moving_cards.append(current_card)
					current_card = null if evolved_from.size() == 0 else evolved_from.pop_back()
				else:
					break
			if not is_filled() or identifier.identifier_bool(current_card):
				return remove_all() + moving_cards
		
		for card in energy_cards:
			if identifier.identifier_bool(card):
				moving_cards.append(card)
				energy_cards.erase(card)
		
		if tool_card and identifier.identifier_bool(tool_card):
			moving_cards.append(tool_card)
			remove_tool()
		
		for tm in tm_cards:
			if identifier.identifier_bool(tm):
				moving_cards.append(tm)
				remove_tm(tm)
	#Remove the top evolution
	else:
		if can_devolve():
			var top_evo: Base_Card = current_card
			devolve_card()
			return [top_evo]
	
	refresh()
	return moving_cards
#endregion
#--------------------------------------

#--------------------------------------
#region CONDITION HANDLERS
func add_condition(adding: Condition) -> void:
	if adding.poison != 0 and not Globals.fundies.check_condition_immune(1, self):
		applied_condition.poison = max(adding.poison, applied_condition.poison)
	if adding.burn != 0 and not Globals.fundies.check_condition_immune(2, self):
		applied_condition.burn = max(adding.burn, applied_condition.burn)
	
	if adding.turn_cond != Consts.TURN_COND.NONE:
		var allowed: bool = true
		
		match adding.turn_cond:
			Consts.TURN_COND.PARALYSIS:
				allowed = not Globals.fundies.check_condition_immune(4, self)
			Consts.TURN_COND.ASLEEP:
				allowed = not Globals.fundies.check_condition_immune(8, self)
			Consts.TURN_COND.CONFUSION:
				allowed = not Globals.fundies.check_condition_immune(16, self)
		
		if allowed:
			applied_condition.turn_cond = adding.turn_cond
	
	applied_condition.imprision = adding.imprision or applied_condition.imprision
	applied_condition.shockwave = adding.shockwave or applied_condition.shockwave
	
	ui_slot.display_condition()
	
	await ability_emit(condition_applied, applied_condition)

func add_specified_condition(adding: Condition, cond: String) -> void:
	match cond:
		"Poision":
			if adding.poison != 0 and not Globals.fundies.check_condition_immune(1, self):
				applied_condition.poison = max(adding.poison, applied_condition.poison)
		"Burn":
			if adding.burn != 0 and not Globals.fundies.check_condition_immune(2, self):
				applied_condition.burn = max(adding.burn, applied_condition.burn)
		"Paralyze":
			if not Globals.fundies.check_condition_immune(4, self):
				applied_condition.turn_cond = Consts.TURN_COND.PARALYSIS
		"Sleep":
			if not Globals.fundies.check_condition_immune(8, self):
				applied_condition.turn_cond = Consts.TURN_COND.ASLEEP
		"Confuse":
			if not Globals.fundies.check_condition_immune(16, self):
				applied_condition.turn_cond = Consts.TURN_COND.CONFUSION
	
	ui_slot.display_condition()
	
	await ability_emit(condition_applied, applied_condition)

func affected_by_condition() -> bool:
	var poisioned: bool = applied_condition.poison != 0
	var burnt: bool = applied_condition.burn != 0
	var turnt: bool = applied_condition.turn_cond != Consts.TURN_COND.NONE
	
	return poisioned or burnt or turnt

func alleviate_all() -> void:
	applied_condition.poison = 0
	applied_condition.burn = 0
	applied_condition.turn_cond = Consts.TURN_COND.NONE
	ui_slot.display_condition()

func checkup_conditions():
	if applied_condition.poison != 0:
		prints("Poison", applied_condition.poison)
		damage_counters += applied_condition.poison * 10
		ui_slot.damage_counter.set_damage(damage_counters)
	
	#Prior to Sun & Moon, if a Pokémon was Burned, the coin toss to cure it would happen first,
	#then the damage would only be inflicted if the Burn was not cured. https://bulbapedia.bulbagarden.net/wiki/Pok%C3%A9mon_Checkup
	if applied_condition.burn != 0:
		var result: bool = await condition_rule_utilize(Globals.board_state.burn_rules)
		if result:
			applied_condition.burn = 0
		else:
			prints("Burn", applied_condition.burn)
			damage_counters += applied_condition.burn * 10
			ui_slot.damage_counter.set_damage(damage_counters)
	
	if applied_condition.turn_cond == Consts.TURN_COND.PARALYSIS and not is_attacker():
		print("Paralysis")
		applied_condition.turn_cond = Consts.TURN_COND.NONE
		var result: bool = await condition_rule_utilize(Consts.COND_RULES.TURN_PASS)
		if result:
			applied_condition.turn_cond = Consts.TURN_COND.NONE
		
	if applied_condition.turn_cond == Consts.TURN_COND.ASLEEP:
		print("Sleep")
		var result: bool = await condition_rule_utilize(Globals.board_state.sleep_rules)
		if result:
			applied_condition.turn_cond = Consts.TURN_COND.NONE
	
	ui_slot.display_condition()

func condition_rule_utilize(using: Consts.COND_RULES):
	match using:
		Consts.COND_RULES.NONE:
			return false
		Consts.COND_RULES.FLIP:
			var result: int = LateConsts.coinflip_once.start_comparision()
			await SignalBus.finished_coinflip
			return result != 0
		Consts.COND_RULES.TWOFLIP:
			var result = LateConsts.coinflip_twice.start_comparision()
			await SignalBus.finished_coinflip
			print(result)
			return result
		Consts.COND_RULES.TURN_PASS:
			#Remove after thier side's turn ends
			print(get_card_name(), Globals.fundies.home_turn, is_home(), not is_attacker())
			return not is_attacker()

func confusion_check() -> bool:
	if applied_condition.turn_cond != Consts.TURN_COND.CONFUSION:
		return false
	
	var confused: bool = not await condition_rule_utilize(Globals.board_state.confusion_rules)
	
	if confused:
		dmg_manip(Globals.board_state.confusion_damage)
	
	return confused

#endregion
#--------------------------------------

#--------------------------------------
#region SLOT CHANGE HANDLERS
func get_changes(change: String) -> Dictionary:
	return all_changes[change]

func get_every_change(change: String) -> Dictionary:
	#To prevent all changes from retaining merge changes duplicate it
	var dict: Dictionary = all_changes[change].duplicate()
	dict.merge(Globals.fundies.get_side_change(change, is_home()))
	
	if dict.size() != all_changes[change].size():
		pass
	
	return dict

func apply_slot_change(apply: SlotChange) -> void:
	var category: String = apply.get_script().get_global_name()
	if is_filled() and not apply in get_changes(category):
		var dict: Dictionary = get_changes(category)
		
		if not apply in dict:
			dict[apply] = apply.duration
			changes_ui_check()
			check_passive()

func remove_slot_change(removing: SlotChange) -> void:
	if is_filled():
		var dict: Dictionary = get_changes(removing.get_script().get_global_name())
		
		if removing in dict:
			dict.erase(removing)
			if removing is Disable:
				var dis = removing as Disable
				#this is here for redundancy
				#If a slot get's it's ability reenabled after thier passive check
				if dis.disable_body or dis.disable_power:
					check_passive()
			
			changes_ui_check()

func changes_ui_check() -> void:
	ui_slot.changes_display.set_changes(all_changes.values())
	ui_slot.max_hp.clear()
	set_max_hp()
	ui_slot.max_hp.append_text(str("HP: ",get_max_hp()))

#region SLOT CHANGE CHECKS
func check_bool_disable(which: Consts.MON_DISABL) -> bool:
	var dict = get_every_change("Disable")
	
	for dis in dict:
		if not dis is Disable: continue
		dis = dis as Disable
		
		if dis.check_bool(which) and dis.recieves.check_ask(self, false):
			return true
	
	return false

func check_attack_disable(which: Consts.DIS_ATK, atk_name: String) -> bool:
	for dis in get_every_change("Disable"):
		if not dis is Disable: continue
		dis = dis as Disable
		
		if dis.check_attack(which, atk_name):
			return true
	return false

func check_atk_efct_dis(atk_name: String) -> bool:
	for dis in get_every_change("Disable"):
		if not dis is Disable: continue
		dis = dis as Disable
		
		if dis.check_atk_efct(atk_name):
			return true
	return false

func check_override_evo(card: Base_Card) -> bool:
	if not is_attacker():
		return false
	
	for ov in get_changes("Override"):
		if not ov is Override: continue
		ov = ov as Override
		
		if card.name in ov.can_evolve_into:
			return true
	return false

func check_override_retreat() -> bool:
	for ov in get_changes("Override"):
		if not ov is Override: continue
		ov = ov as Override
		
		if ov.can_retreat_when.size() > 0 and has_condition(ov.can_retreat_when):
			return true
	
	return false
#endregion

func switch_clear() -> void:
	for dict in all_changes.values():
		for change in dict:
			remove_slot_change(change)

func manage_change_timers() -> void:
	printt(all_changes, get_card_name())
	for dict in all_changes.values():
		for change in dict:
			if dict[change] == -1:
				continue
			elif dict[change] == 0:
				remove_slot_change(change)
			else:
				dict[change] -= 1

#endregion
#--------------------------------------

#--------------------------------------
#region MANAGING DISPLAYS
func slot_into(destination: UI_Slot, initalize: bool = false) -> void:
	ui_slot = destination
	position_string = str("Home " if is_home() else "Away " ,ui_slot.name)
	#debug_check()
	if initalize:
		refresh_current_card()
		refresh()
		
		ui_slot.tool.visible = tool_card != null
		if tm_cards.size():
			ui_slot.tm.texture = tm_cards[0].image
			ui_slot.tm.show()

func refresh_current_card() -> void:
	ui_slot.name_section.clear()
	ui_slot.max_hp.clear()
	set_max_hp()
	ui_slot.damage_counter.set_damage(damage_counters)
	
	ui_slot.display_image(current_card)
	ui_slot.name_section.append_text(current_card.name)
	ui_slot.max_hp.append_text(str("HP: ",get_max_hp()))
	ui_slot.display_types(Convert.flags_to_type_array(get_pokedata().type))
	ui_slot.display_condition()
	setup_abilities()
	occurance_account_for()
	await ability_emit(first_check, self)

#Work towards removing functions from this
func refresh() -> void:
	if not is_filled():
		clear_dispay()
		return
	#recognize position of slot
	ui_slot.connected_slot = self
	
	if current_card: 
		ui_slot.damage_counter.set_damage(damage_counters)
		#check for any attatched cards/conditions
		update_energy()
		Globals.fundies.check_all_passives()
	
	else:
		ui_slot.display_image(null)
		ui_slot.display_types([])

func refresh_swap() -> void:
	if not is_filled():
		clear_dispay()
		return
	#Change slot's card display
	ui_slot.name_section.clear()
	ui_slot.max_hp.clear()
	#recognize position of slot
	ui_slot.connected_slot = self
	
	if current_card:
		ui_slot.display_image(current_card)
		ui_slot.name_section.append_text(current_card.name)
		ui_slot.max_hp.append_text(str("HP: ",get_pokedata().HP))
		ui_slot.damage_counter.set_damage(damage_counters)
		ui_slot.display_types(Convert.flags_to_type_array(get_pokedata().type))
		
		ui_slot.display_condition()
		
		#check for any attatched cards/conditions
		count_energy()
		ui_slot.display_energy(get_energy_strings(), attached_energy)
		ui_slot.changes_display.set_changes(all_changes.values())
		
		if tm_cards.size():
			ui_slot.tm.texture = tm_cards[0].image
			ui_slot.tm.show()
		else: ui_slot.tm.hide()
	
	else:
		ui_slot.display_image(null)
		ui_slot.display_types([])

func update_energy():
	count_energy()
	ui_slot.display_energy(get_energy_strings(), attached_energy)

func clear_dispay() -> void:
	damage_counters = 0
	ui_slot.clear()

#endregion
#--------------------------------------

func get_debug_name():
	return str("[" ,position_string, "] ",get_card_name())

func temp_check():
	print("Did something change?")
	for slot in Globals.full_ui.every_slot:
		if slot.connected_slot.is_filled():
			pass
