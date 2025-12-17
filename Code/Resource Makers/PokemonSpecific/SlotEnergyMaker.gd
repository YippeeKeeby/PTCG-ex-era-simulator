extends Resource
class_name SlotEnergy

@export var en_table: Array[Array] = [[],[],[],[],[],[],[],[],[]]
@export var en_total: Array[int] = [0,0,0,0,0,0,0,0,0]

class Entry: 
	var card: Base_Card
	var provide: EnData
	
	func _init(a: Base_Card, b: EnData) -> void:
		self.card = a
		self.provide = b

func clear_table():
	en_table = [[],[],[],[],[],[],[],[],[]]

func add_card(card: Base_Card, provide: EnData):
	var new_entry: Entry = Entry.new(card, provide)
	
	for i in range(9):
		if provide.type & (2 ** i) != 0:
			
			if en_table[i].size() == 0 or card.energy_properties.considered == "Basic Energy":
				en_table[i].append(new_entry)
				
			else:
				var flags = Convert.get_number_of_flags(provide.type, 9)
				
				for j in range(en_table[i].size()):
					var home = card.energy_properties.attatched_to.is_home()
					if en_table[i][j].card == new_entry.card:
						print("Found repeat")
						print(card.name, card.energy_properties.attatched_to.get_debug_name())
						break
					#Add special energy before the first card that provides the same num of types 
					if flags >= Convert.get_number_of_flags(en_table[i][j].provide.type, 9):
						print(card.energy_properties.attatched_to.get_debug_name(), " Add ", new_entry.card.name, " to ", Consts.energy_types[i])
						if not home and new_entry.provide.type == 511:
							pass
						en_table[i].insert(j, new_entry)
						break
	
	#display_table()

func remove_card(card: Base_Card):
	for i in range(9):
		for entry in en_table[i]:
			if card == entry.card:
				en_table[i].erase(entry)
	
	#display_table()

func pay_with_first(type_flag: int, num: int):
	var leftover: int = num
	var temp_table = en_table[type_flag].duplicate()
	
	while temp_table.size() != 0:
		#Entries contian card followed by it's current provide
		#Take first one in stack since that's usually the 
		var entry: Entry = temp_table.pop_back()
		leftover = floor(leftover - entry.provide.number)
		if leftover > 0:
			remove_card(entry.card)
		else:
			break
	
	return leftover

func display_table():
	for i in range(9):
		if en_table[i].size() != 0:
			var string: String = ""
			for entry in en_table[i]:
				string += str(entry.card.name, entry.provide.type, "\t")
			print("All ", Consts.energy_types[i], " cards: ", string)

#func count_cards(slot: PokeSlot, en_cards: Array[Base_Card]):
	#Globals.fundies.record_single_src_trg(slot)
	#
	#for energy in en_cards:
		#if energy.energy_properties.attatched_to != slot:
			#energy.energy_properties.attatched_to = slot
		#var en_provide: EnData = slot.get_context_en_provide(energy)
		#add_card(energy, en_provide)
		#
		##print("Checking ", energy.name, energy, " in ", get_card_name())
		#if not en_provide.ignore_effects:
			#for effect in energy.energy_properties.prompt_effects:
				#print(energy.name, " Would play effect")
				##effect.effect_collect_play()
	#
	#Globals.fundies.remove_top_source_target()
	#
	#display_table()
