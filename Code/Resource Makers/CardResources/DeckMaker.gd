@tool
extends Resource
class_name Deck

@export var cards: Dictionary[Base_Card, int]
@export_tool_button("Check Legallity") var button: Callable = is_legal

enum DECK_STATUS {READY, INCOMPLETE, ILLEGAL, TOOBIG}
var status: DECK_STATUS = DECK_STATUS.READY

func is_legal() -> bool:
	var count: int = 0
	for card in cards:
		var en = card.energy_properties
		var basic_energy: bool = en and en.considered == "Basic Energy"
		
		if not basic_energy and cards[card] > 4:
			status = DECK_STATUS.ILLEGAL
			printerr("This deck isn't legal as ", card.name, " has too many cards")
			return false
		
		count += cards[card]
	
	if count > 60:
		status = DECK_STATUS.TOOBIG
		printerr("This deck isn't legal as it has ", count, " cards")
		return false
	if count < 60:
		status = DECK_STATUS.INCOMPLETE
		printerr("This deck isn't legal as it has ", count, " cards")
		return false
	
	status = DECK_STATUS.READY
	print("READY!")
	return true

func make_usable() -> Array[Base_Card]:
	var usable: Array[Base_Card] = []
	
	for card in cards:
		for i in cards[card]:
			var new_card: Base_Card = card.duplicate_deep(DeepDuplicateMode.DEEP_DUPLICATE_ALL)
			#These have to be unique to make search function
			usable.append(new_card)
			
	
	if usable.size() != 60:
		printerr("Warning, this deck has the size of: ", usable.size())
		pass
	
	for card in usable:
		var how_often: int = 0
		for other in usable:
			if card == other:
				how_often += 1
		if how_often > 1:
			printerr("A the same instance of a card shows up multiple times ", card.get_formal_name())
	
	return usable
