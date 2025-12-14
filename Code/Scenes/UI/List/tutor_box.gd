extends Control
class_name Tutor_Dock

#--------------------------------------
#region VARIABLES
@export var connected_list: PlayingList
@export var search: Search
@export var start_text: String
@export var disapear_timing: float = .1

@onready var req_text: RichTextLabel = %ReqText
@onready var status: RichTextLabel = %Status
@onready var card_list: VBoxContainer = %CardList

signal blacklist(card: Base_Card, adding_to: bool)
signal check_requirements(id: Identifier, allowed: bool, choices_made: int)
signal disapear

var tutor_requiremnts: Dictionary[Identifier, Array]
var based_on: Array[PokeSlot]
var max_tutor: int = 0
var stack_size: int = 0
var options: Node
#endregion
#--------------------------------------

#--------------------------------------
#region INITALIZATION
func _ready() -> void:
	SignalBus.connect("tutor_card", add_card)
	SignalBus.connect("cancel_tutor", remove_card)

func set_up_tutor():
	for i in range(search.of_this.size()):
		max_tutor += search.how_many[i]
		tutor_requiremnts[search.of_this[i]] = []
	update_requirements()
	
	status.clear()
	status.append_text(str("[center]Tutor Number: 0 / ", max_tutor, "\n"))

#endregion
#--------------------------------------

func update_tutor():
	var current_num: int = 0
	#Check how may cards are added in the tutor
	update_requirements()
	for id in tutor_requiremnts:
		current_num += tutor_requiremnts[id].size()
	
	status.clear()
	status.append_text(str("[center]Tutor Number: ", current_num," / ", max_tutor))

func update_requirements():
	var requirements: String = ""
	
	for i in range(search.of_this.size()):
		var desc: String = str(search.of_this[i].description,"s") if search.how_many[i] != 1 else search.of_this[i].description
		var ammount: String = "Inf" if search.how_many[i] == -1 else str(search.how_many[i])
		var currently: int = tutor_requiremnts[search.of_this[i]].size()
		
		if requirements == "":
			requirements = str(requirements, currently," / ", ammount, " ", desc)
		else:
			requirements = str(requirements, "\n", currently, " / ", ammount, " ", desc)
	
	req_text.clear()
	req_text.append_text(str("[center]",requirements))

#--------------------------------------
#region CARDS DISPLAYED
func add_card(card: Base_Card):
	card.print_info()
	for i in range(search.of_this.size()):
		var num: int = search.how_many[i]
		var id: Identifier = search.of_this[i]
		#Check if this card is allowed to be added
		#id.identifier_bool(card, based_on) and
		if tutor_requiremnts[id].size() < num:
			tutor_requiremnts[id].append(show_card(card, id))
			
			#If the search identifier is now satisfied make sure no more can be added
			check_requirements.emit(id, tutor_requiremnts[id].size() < num, tutor_requiremnts[id].size())
			if id.must_be_different:
				blacklist.emit(card, true)
			
			update_tutor()
			return
	#Only ends up here if a card cannot be added for some reason
	printerr("Can't add ", card.name, " tutor condition doesn't allow it")

func remove_card(button: Button):
	print(tutor_requiremnts)
	for id in tutor_requiremnts:
		#Buttons are recorded so each one is unique and can only be found in one place
		if button in tutor_requiremnts[id]:
			if id.must_be_different:
				blacklist.emit(button.card, false)
			tutor_requiremnts[id].erase(button)
			button.queue_free()
			connected_list.add_item(button.card)
			check_requirements.emit(id, true, tutor_requiremnts[id].size())
	
	connected_list.sort_items()
	update_tutor()

func show_card(card: Base_Card, id: Identifier) -> Button:
	var making = Consts.playing_button.instantiate()
	making.card = card
	making.parent = self
	making.stack_act = Consts.STACK_ACT.TUTOR
	making.from_id = id
	%CardList.add_child(making)
	
	connected_list.remove_item(card)
	making.allow_move_to(connected_list.stack)
	return making

#endregion
#--------------------------------------

#--------------------------------------
#region SIGNALS
func _on_confirm_pressed() -> void:
	if connected_list == null:
		printerr("There is no connected list to ", self)
		return
	
	var all_tutored: Array[Base_Card]
	var rest: Array[Base_Card] = connected_list.list.keys()
	
	for id in tutor_requiremnts:
		for button in tutor_requiremnts[id]:
			all_tutored.append(button.card)
			rest.erase(button.card)
	
	print("Moving ", all_tutored, " from ", Convert.stack_into_string(search.and_then.stack),
	 " to ", Convert.stack_into_string(search.where))
	#Sends signal over to StackManager.placement_handling()
	SignalBus.make_placement.emit(all_tutored, search.and_then, search.where, rest)
	disapear.emit()

#endregion
#-------------------------------------- 
