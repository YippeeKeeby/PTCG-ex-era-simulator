@icon("res://Art/ProjectSpecific/beauty.png")
extends Resource
class_name EffectCall

##Determine the order in which the effects are called.
##It's best to fill this in, if you don't want the default enum order
@export var order: Array[Consts.EFFECTS]
##Add a condition
@export var condition: Condition
##Draw an ammount of cards
@export var draw_ammount: Draw
##Buff/Debuff a pokemon's stats or properties
@export var buff: Buff
##Send cards elsewhere
@export var card_disrupt: CardDisrupt
##Disable the player/pokemon's possible moves
@export var disable: Disable
##Move current energy in play
@export var energy_movement: EnMov
##Move/Add damage counters around slots and stacks
@export var dmgManip: DamageManip
##Look for cards in deck/discard
@export var search: Search
##Heal from any status
@export var alleviate: Alleviate
##Swap the active pokemon
@export var swap: PokeSwap
##Mimic other pokemon's moves
@export var mimic: Mimic
##What rules should be changed on a slot?
@export var override: Override
##What rules should be changed across the whole game
@export var rule_change: RuleChange
##What cards can you play now?
@export var cheat_play: CheatPlay
##How should types change?
@export var type_change: TypeChange

signal finished

var went_back: bool = false
var replace_num: int = -1

#These are params since the indivdual call knows best which is what
func play_effect(reversable: bool = false) -> void:
	var default_order = [condition, buff, card_disrupt, disable, energy_movement,
	 dmgManip, search, swap, draw_ammount, alleviate, mimic, override, cheat_play, type_change]
	#var enum_dict: Dictionary = {effect_types.CONDITION:condition, effect_types.BUFF:buff,
	 #effect_types.DISRUPT:card_disrupt, effect_types.DISABLE:disable,
	 #effect_types.ENMOV:energy_movement, effect_types.DMGMANIP: dmgManip,
	 #effect_types.SEARCH: search, effect_types.SWAP:swap, effect_types.DRAW:draw_ammount,
	 #effect_types.ALLEVIATE:alleviate, effect_types.MIMIC:mimic}
	
	went_back = false
	if reversable: SignalBus.went_back.connect(just_reversed)
	
	print("Playing effect ", resource_name)
	
	if order.size() > 0:
		for effect in order:
			if went_back: return
			if default_order[effect]:
				await handle_component(default_order[effect], reversable)
	
	else:
		for effect in default_order:
			if went_back: return
			if effect: await handle_component(effect, reversable)
	
	if reversable: SignalBus.went_back.disconnect(just_reversed)
	finished.emit()

func handle_component(comp, reversable: bool = false):
	await comp.play_effect(reversable, replace_num)
	print("FINISHED")

func just_reversed():
	went_back = true
	SignalBus.went_back.disconnect(just_reversed)

func has_effect_type(comps: Array[String]):
	var default_order: Array[Object] = [condition, buff, card_disrupt, disable, 
	 energy_movement, dmgManip, search, swap, draw_ammount, alleviate, mimic]
	
	for comp in comps:
		for current_comps in default_order:
			if current_comps and current_comps.get_script().get_global_name() == comp:
				return true
	
	return false

func get_slot_changes() -> Array[SlotChange]:
	var inital: Array[SlotChange] = [buff, disable, override, type_change, rule_change]
	var valid: Array[SlotChange]
	for change in inital:
		if change != null:
			valid.append(change)
	return valid
