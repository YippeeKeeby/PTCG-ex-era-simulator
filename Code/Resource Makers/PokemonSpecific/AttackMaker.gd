extends Resource
class_name Attack

@export var name: String
@export var attack_cost: AttackCost = preload("res://Resources/Components/Pokemon/Attacks/AttackCosts/Colorless1.tres")
@export var attack_data: AttackData

#region DEBUG
func print_attack() -> void:
	print_rich("[center]------------------",name,"------------------")
	print_rich("Description: ", attack_data.description)
	print_rich("[center]------------------COST------------------")
	
	for type in Convert.get_basic_energy():
		print_cost(type)
	attack_data.print_data()

func print_cost(energy: String):
	var using: int = get_cost(Consts.energy_types.find(energy))
	if using == 0: return
	print_rich(str(Convert.get_type_rich_color(energy), energy, ":[/color] ", using))

func get_cost(index: int) -> int:
	match index:
		0: return attack_cost.grass_cost
		1: return attack_cost.fire_cost
		2: return attack_cost.water_cost
		3: return attack_cost.lightning_cost
		4: return attack_cost.psychic_cost
		5: return attack_cost.fighting_cost
		6: return attack_cost.darkness_cost
		7: return attack_cost.metal_cost
		8: return attack_cost.colorless_cost
	
	return -1

#endregion

#region ENERGY
##Returns only the specified required energy for the attack to start 
func get_energy_cost(slot: PokeSlot) -> Array[String]:
	var all_costs: Array[int] = get_modified_cost(slot)
	var final_array: Array[String] = []
	
	for i in range(all_costs.size()):
		var energy_type: String = Consts.energy_types[i]
		for j in range(all_costs[i]):
			final_array.append(energy_type)
	
	return final_array

func get_modified_cost(slot: PokeSlot) -> Array[int]:
	if not slot:
		return attack_cost.get_energy_cost_int()
	
	var side_changes = Globals.fundies.get_side_change("Buff", slot.is_home()).keys()
	var slot_changes = slot.get_changes("Buff")
	
	if slot_changes.size() == 0 and side_changes.size() == 0:
		return attack_cost.get_energy_cost_int()
	
	#First find any replacements
	var replace: Array[int] = get_cost_buffs(slot_changes.keys(), true)
	var side_replace: Array[int] = get_cost_buffs(side_changes, true)
	print(replace, side_replace)
	print(replace.any(func(a: int): return a != 0), side_replace.any(func(a: int): return a != 0))
	#This means that replace overrides any addition or subtraction buffs
	#Idk if it should be like this
	if replace.any(func(a: int): return a != 0):
		return replace
	if side_replace.any(func(a: int): return a != 0):
		return side_replace
	
	var final: Array[int] = attack_cost.get_energy_cost_int()
	var side_buffs = get_cost_buffs(side_changes, false)
	#Then evaluate any additions and subtractions
	final = cost_arithmetic(final, get_cost_buffs(slot_changes.keys(), false), true)
	final = cost_arithmetic(final, side_buffs, true)
	for i in range(final.size()):
		final[i] = clamp(final[i], 0, 99)
	
	return final

func get_cost_buffs(arr: Array, replace: bool = false) -> Array[int]:
	var total: Array[int] = []
	total.resize(9)
	
	for change in arr:
		if change is Buff:
			change = change as Buff
			if change.attack_cost:
				var using: Array[int] =  change.get_cost(name)
				if replace and change.cost_modifier == "Replace":
					total = using
				elif not replace and change.cost_modifier != "Replace":
					total = cost_arithmetic(total, using, change.cost_modifier == "Add")
	
	return total

func cost_arithmetic(first: Array[int], second: Array[int], addition: bool = true) -> Array[int]:
	for i in range(second.size()):
		first[i] += second[i] if addition else -second[i]
	
	return first

func pay_cost(slot: PokeSlot):
	print("CHECK COSTS FOR ", name)
	var all_costs: Array[int] = get_modified_cost(slot)
	var basic_energy: Array[Base_Card] = slot.get_total_en_categories("Basic Energy")
	var special_energy: Array[Base_Card] = slot.get_total_en_categories("Special Energy")
	
	#Edit costs depending on whatever factors
	#Priotitize basic/single type first
	#print("ENERGY SORT ", basic_energy)
	for card in basic_energy:
		var index = int((log(float(card.energy_properties.get_current_type())) / log(2)))
		#print("Used ", card.name, " for ", Consts.energy_types[index] if all_costs[index] > 0 else "Colorless")
		
		if all_costs[index] > 0: all_costs[index] = clamp(all_costs[index]-1, 0, all_costs[index])
		else: all_costs[8] = clamp(all_costs[8]-1, 0, all_costs[8])
	
	#Maybe sort based on flag size
	special_energy.sort_custom(func(a: Base_Card,b: Base_Card):\
	 return a.energy_properties.get_current_type() < b.energy_properties.get_current_type())
	print("SPECIAL SORT: ")
	for card in special_energy:
		var finished: bool = true
		all_costs = pay_with(all_costs, card)
		#print(card.get_formal_name())
		
		for cost in all_costs:
			if cost != 0:
				finished = false
		if finished:
			break
	
	var final_cost: int = 0
	#How to consider special energy later
	for cost in all_costs:
		final_cost += cost
	
	if final_cost > 0:
		print(" LEFTOVER: ", final_cost)
	#else:
		#print(basic_energy, special_energy)
	
	return final_cost

func new_pay(slot: PokeSlot):
	var all_costs: Array[int] = get_modified_cost(slot)
	var current_energy: Array[int]
	#Get the en dictionary of the pokemon's current energy
	for en in slot.attached_energy:
		current_energy.append(slot.attached_energy[en])
	
	#Prioritize paying for colored energy with it's type
	for i in range(all_costs.size() - 1):
		if all_costs[i] != 0 and current_energy[i] != 0:
			var diff: int = clamp(0, all_costs[i] - current_energy[i], all_costs[i])
			current_energy[i] = clamp(0, current_energy[i] - all_costs[i], current_energy[i])
			all_costs[i] = diff
	
	#Pay for leftover colored energy with Rainbow
	for i in range(all_costs.size()):
		if all_costs[i] != 0:
			var diff: int = clamp(0, all_costs[i] - current_energy[16], all_costs[i])
			current_energy[i] = clamp(0, current_energy[16] - all_costs[i], current_energy[16])
			all_costs[i] = diff
	
	#Pay colorless with leftovers
	if all_costs[-1] != 0:
		for i in range(current_energy.size()):
			if current_energy[i] != 0:
				var diff: int = clamp(0, all_costs[-1] - current_energy[i], all_costs[-1])
				current_energy[i] = clamp(0, current_energy[i] - all_costs[-1], current_energy[i])
				all_costs[-1] = diff
	
	#If the remaining cost is 0, you can pay for this attack.
	var final_cost: int = 0
	#How to consider special energy later
	for cost in all_costs:
		final_cost += cost
	
	if final_cost > 0:
		print(" LEFTOVER: ", final_cost)
	
	return final_cost

func colored_pay_loop():
	pass

func pay_with(all_costs: Array[int], card: Base_Card):
	var energy_provide = card.energy_properties.get_current_provide()
	var energy_num: int = energy_provide.number
	print("Using ", card.name, " with ", energy_num, " Energy")
	for i in range(all_costs.size()):
		if all_costs[i] == 0: continue
		var type_flag: int = 2 ** i
		
		if type_flag & energy_provide.type != 0\
		 or Consts.energy_types[i] == "Colorless":
			var difference = all_costs[i] - energy_num
			all_costs[i] = clamp(difference, 0, all_costs[i])
			energy_num  = clamp(difference * -1, 0, energy_num)
			if energy_num == 0:
				print("Used up ", card.name)
			else:
				print("Remember to save this info somewhere later")
	return all_costs

##Checks if the provided energy is enough to cover for the attack cost[br]
##This function prioritizes using basic energy first to optimize energy spending[br]
##ex. [i] [Grass, Darkness] [Rainbow][/i][br] for an attack that costs
## [i][Grasss, Grass, Darkness] [/i] [br]
##It will fill in every cost it can without using multicolor energy only using when necessary.
##Special energy is sorted based on how many colors it can fill in Rainbow > Aqua & Magma
func can_pay(slot: PokeSlot) -> bool:
	return true if pay_cost(slot) == 0 else false
#endregion

#region DAMAGE
func get_damage() -> int:
	var data: AttackData = attack_data
	var final_damage: int = data.initial_main_DMG
	var mod_times: int = 1
	var modifier_result: int = 0
	
	if data.comparator:
		mod_times = data.comparator.start_comparision()
		print("HAS A MODIFIER WITH THE RESULT OF ", mod_times, " * ", data.modifier_num)
		if data.comparator.has_coinflip():
			await SignalBus.finished_coinflip
	if data.mod_prompt:
		mod_times *= 1 if data.prompt_hold else 0
	
	if mod_times != null:
		print(data.modifier_num, mod_times)
		modifier_result = data.modifier_num * mod_times
		match data.modifier:
			0:
				if mod_times == 0:
					final_damage = modifier_result
			1:
				final_damage += modifier_result
			2:
				final_damage = modifier_result
			3:
				final_damage -= modifier_result
	
	return final_damage

func needs_target() -> bool:
	var need_target: bool = attack_data.prompt_effects.size() != 0\
	 and not ToolBool.attack_has_effect(self, ["Mimic", "Search", "Draw"])
	
	return attack_data.initial_main_DMG != 0 or need_target\
	or attack_data.modifier_num != 0 or attack_data.self_damage != 0

#Check if you're allowed to attack while having this condition
func condition_prevents(turn_cond: Consts.TURN_COND) -> bool:
	match turn_cond:
		Consts.TURN_COND.PARALYSIS:
			print(attack_data.condition && 2, attack_data.condition & 2)
			return attack_data.condition & 2 == 0
		Consts.TURN_COND.ASLEEP:
			return attack_data.condition & 4 == 0
		_:
		#For now confusion doesn't block anything,
		#just check if they can attack without condition
			print(attack_data.condition && 1, attack_data.condition & 1, attack_data.condition)
			return attack_data.condition & 1 == 0

func has_effect(effect_type: Array[String]) -> bool:
	if attack_data.prompt and attack_data.prompt.effect:
		if attack_data.prompt.effect.has_effect_type(effect_type):
			return true
	if attack_data.bench_damage:
		print("Make this later")
	return false
#endregion
