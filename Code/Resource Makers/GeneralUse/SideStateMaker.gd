extends Resource
class_name SideState

@export var card_stacks: CardStacks
@export var prize_cards: int = 6
@export var bench_size: int = 5
##The boolean will determine whether or not a slot is active or not
##[br] take these cards inside slots from deck if [member home_UD] is null
@export var slots: Dictionary[PokeSlot, bool]
@export var inital_supporter: Base_Card


func duplicate_slots():
	var dup_slots: Dictionary[PokeSlot, bool]
	
	for slot in slots:
		slot = slot as PokeSlot
		
		var new: PokeSlot = slot.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
		dup_slots[new] = slots[slot]
	
	slots = dup_slots
