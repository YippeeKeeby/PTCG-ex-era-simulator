extends Resource
class_name Ability

@export_enum("Body", "Power") var category: String = "Body"
@export var name: String = ""
@export_multiline var description: String = ""

##If they're affected by a condition they cannot use the ability as long as this is true
@export var affected_by_condition: bool = true
##Mon must be in active slot to use this ability
@export var active: bool = false
##How often can this ability be used in a per turn basis
##[br][enum Once per Mon] Each pokeslot that has this ability can play it once per turn
##[br][enum Once per turn] Abilities with this [member name] can only be used once per turn
##[br][enum Once per Emit] Abilities with this [member name] can only be triggered once per [member occurance] emit
##[br][enum Infinite] No limits to how often this ability can be used
@export_enum("Once per Mon", "Once per turn", "Once per Emit", "Infinite") var how_often: String = "Once per Mon"
##If true then the ability will activate with a src_trg stack of just the slot activating the ability
##[br]Otherwise the src stack is the previous one based on the slot activating the ability
##[br][color=yellow]Useful for DR7&8 Minun and Plusle who activate based on anyone else attacking
##but it doesn't care about them afterwards
@export var independent_src_trg: bool = false
##Any conditions to pass to activate the effect?
@export var prompt: PromptAsk
##If this ability activates at a certain time, when is that time? Uses signals from [member PokeSlot]
@export var occurance: Occurance
##As long as the prompt is passed this effect will activate without calling for any occurances from other slots
@export var passive: EffectCall
##This will call an ability activation
@export var shared_prompt: bool = true
@export var effects: Array[EffectCollect]

var attatched_to: PokeSlot

#region INITALIZATION
func prep_ability(slot: PokeSlot):
	attatched_to = slot
	if occurance:
		occurance.connect_occurance()
		occurance.owner = slot
		if not occurance.occur.has_connections():
			occurance.occur.connect(activate_ability)
		else:
			pass

func disconnect_ability():
	if occurance:
		occurance.disconnect_occurance()
		if occurance.occur.is_connected(activate_ability):
			occurance.occur.disconnect(activate_ability)

func single_prep(slot: PokeSlot):
	if occurance:
		occurance.single_connect(slot)

func single_disconnect(slot: PokeSlot):
	if occurance:
		occurance.single_disconnect(slot)

#endregion

#region BOOLEANS
##Passives will activate on thier own
func does_press_activate(slot: PokeSlot) -> bool:
	if occurance:
		return false
	
	return general_allowed(slot)

func general_allowed(slot: PokeSlot) -> bool:
	var quick_result: bool = quick_checks(slot)
	
	match how_often:
		"Once per Mon":
			var exhaust: bool = slot.body_exhaust if category == "Body" else slot.power_exhaust
			return not exhaust and check_allowed(slot) and quick_result
		"Once per turn":
			return  not Globals.fundies.used_turn_ability(name) and check_allowed(slot) and quick_result
		"Once per Emit":
			return  not Globals.fundies.used_emit_ability(name) and check_allowed(slot) and quick_result
		"Infinite":
			return check_allowed(slot) and quick_result
	
	return false

func quick_checks(slot: PokeSlot):
	var quick_result: bool = true
	if active:
		quick_result = slot.is_active()
	if affected_by_condition:
		quick_result = quick_result and not slot.has_condition()
	
	if slot.get_every_change("Disable").size() != 0 and slot.check_bool_disable(\
		Consts.MON_DISABL.BODY if category == "Body" else Consts.MON_DISABL.POWER):
		quick_result = false
	
	return quick_result

func check_allowed(slot: PokeSlot) -> bool:
	if prompt and prompt.has_check_prompt():
		Globals.fundies.record_single_src_trg(slot)
		var result: bool = prompt.check_prompt()
		Globals.fundies.remove_top_source_target()
		return result
	else:
		return true

func has_effect(effect_types: Array[String]):
	if passive:
		if passive.has_effect_type(effect_types):
			return true
	if effects.size() != 0:
		for effect in effects:
			if ToolBool.effect_collect_contains(effect, effect_types):
				return true
	return false
#endregion

#region ACTIVATION
func activate_passive() -> bool:
	var slot: PokeSlot = Globals.fundies.get_single_src_trg()
	var result: bool = quick_checks(slot)
	
	if prompt and result:
		if prompt.check_prompt():
			passive.play_effect()
			return true
	elif result:
		passive.play_effect()
		return true
	
	SignalBus.slot_change_failed.emit(passive.get_slot_changes())
	return false

#So far prompt seems to evaluate as expected so no prompts in effect collects seems necessary yet
func activate_ability():
	if not general_allowed(attatched_to):
		return
	
	if prompt:
		if prompt.has_check_prompt():
			var result: bool = prompt.check_prompt()
			if prompt.has_coinflip():
				await SignalBus.finished_coinflip
			if not result:
				SignalBus.ability_checked.emit()
				return
		
		if prompt.has_before_prompt():
			var went_back: bool = await prompt.before_activating()
			if went_back:
				SignalBus.ability_checked.emit()
				return
		if prompt.has_prompt_question():
			var confirmed: bool = await prompt.check_prompt_question()
			if not confirmed:
				SignalBus.ability_checked.emit()
				return
	
	if independent_src_trg:
		Globals.fundies.record_single_src_trg(attatched_to)
	
	await Globals.fundies.ui_actions.play_ability_activate(attatched_to, self)
	
	for effect in effects:
		await effect.effect_collect_play()
	
	if independent_src_trg:
		Globals.fundies.remove_top_source_target()
	
	match how_often:
		"Once per Mon":
			if category == "Body":
				attatched_to.body_exhaust = true
			else:
				attatched_to.power_exhaust = true
		"Once per Turn":
			Globals.fundies.used_turn_abilities.append(name)
		"Once per Emit":
			Globals.fundies.used_emit_abilities.append(name)
	
	SignalBus.ability_checked.emit()
	SignalBus.ability_activated.emit()
#endregion
