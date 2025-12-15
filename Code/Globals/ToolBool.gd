@tool
extends Node

func _ready():
	#Make two edits and saves on prompt so I don't have to think about it every time I load
	#Make a branch before trying to make this
	pass

func is_empty(card: Base_Card) -> bool:
	if card.pokemon_properties:
		return false
	if card.trainer_properties:
		return false
	if card.energy_properties:
		return false
	return true

func is_considered(card: Base_Card, considered: String) -> bool:
	if card.pokemon_properties and card.pokemon_properties.evo_stage == considered:
		#Tool bool differs from the original function here,
		#holon mons are both for filters
		return true
	if card.trainer_properties and card.trainer_properties.considered == considered:
		return true
	if card.energy_properties and card.energy_properties.considered == considered:
		#Energy might need a function for this
		return true
	
	return false

func has_ability(card: Base_Card) -> bool:
	var mon: Pokemon = card.pokemon_properties
	if card.pokemon_properties:
		return mon.pokebody or mon.pokepower
	
	return false

#Might never finish, depend on how much I need this
func has_effect(card: Base_Card, effect_type: Array[String]) -> bool:
	if card.pokemon_properties:
		var mon: Pokemon = card.pokemon_properties
		for attack in mon.attacks:
			if attack_has_effect(attack,effect_type):
				return true
		if mon.pokebody != null:
			if mon.pokebody.passive != null:
				if effect_has_effect_type(mon.pokebody.passive, effect_type):
					return true
			if mon.pokebody.prompt != null:
				if mon.pokebody.prompt.effect != null:
					if effect_has_effect_type(mon.pokebody.prompt.effect, effect_type):
						return true
		if mon.pokepower != null:
			if mon.pokepower.passive:
				if effect_has_effect_type(mon.pokepower.passive, effect_type):
					return true
			if mon.pokepower.prompt != null:
				if mon.pokepower.prompt.effect != null:
					if effect_has_effect_type(mon.pokepower.prompt.effect, effect_type):
						return true
	if card.trainer_properties:
		var train: Trainer = card.trainer_properties
		if train.prompt != null:
			if train.prompt.effect != null:
				if effect_has_effect_type(train.prompt.effect,effect_type):
					return true
		if train.provided_attack != null:
			if attack_has_effect(train.provided_attack, effect_type):
				return true
		if train.tool_properties != null:
			pass
		if train.stadium_properties != null:
			pass
	if card.energy_properties:
		var en: Energy = card.energy_properties
		for effect in en.prompt_effects:
			if effect_collect_contains(effect, effect_type):
				return true
		for effect in en.attatch_effects:
			if effect_collect_contains(effect, effect_type):
				return true
	
	return false

func attack_has_effect(attack: Attack, comps: Array[String]) -> bool:
	var data: AttackData = attack.attack_data
	if not data:
		print(attack.name)
	elif data.prompt != null:
		if data.prompt.effect != null:
			if effect_has_effect_type(data.prompt.effect, comps):
				return true
		for effect in data.prompt_effects:
			if effect_collect_contains(effect, comps):
				return true
	
	return false

func effect_collect_contains(effect_collect: EffectCollect, comps: Array[String]) -> bool:
	if not effect_collect:
		print_rich("[color=blue][b]Empty effect Collect?", effect_collect)
		return false
	
	if effect_collect.success:
		if effect_has_effect_type(effect_collect.success, comps):
			return true
	if effect_collect.fail:
		if effect_has_effect_type(effect_collect.fail, comps):
			return true
	if effect_collect.prompt:
		if effect_collect.prompt.effect:
			if effect_has_effect_type(effect_collect.prompt.effect, comps):
				return true
	
	return false

func effect_has_effect_type(effect: EffectCall, comps: Array[String]) -> bool:
	if effect == null:
		print("oh")
		return false
	
	var gathered_comps: Array = []
	for comp in comps:
		match comp:
			"Condition":
				if effect.condition:
					gathered_comps.append(effect.condition)
			"Buff":
				if effect.buff:
					gathered_comps.append(effect.buff)
			"CardDisrupt":
				if effect.card_disrupt:
					gathered_comps.append(effect.card_disrupt)
					return true
			"Disable":
				if effect.disable:
					gathered_comps.append(effect.disable)
			"EnMov":
				if effect.energy_movement:
					gathered_comps.append(effect.energy_movement)
			"DmgManip":
				if effect.dmgManip:
					gathered_comps.append(effect.dmgManip)
			"Search":
				if effect.search:
					gathered_comps.append(effect.search)
			"Swap":
				if effect.swap:
					gathered_comps.append(effect.swap)
			"Draw":
				if effect.draw_ammount:
					gathered_comps.append(effect.draw_ammount)
			"Alleviate":
				if effect.alleviate:
					gathered_comps.append(effect.alleviate)
			"Mimic":
				if effect.mimic:
					gathered_comps.append(effect.mimic)
			"Override":
				if effect.override:
					gathered_comps.append(effect.override)
			"RuleChange":
				if effect.rule_change:
					gathered_comps.append(effect.rule_change)
			"TypeChange":
				if effect.type_change:
					gathered_comps.append(effect.type_change)
	
	for current_comp in gathered_comps:
		if current_comp.get_script().get_global_name() in comps:
			return true
	
	return false
