@icon("res://Art/ProjectSpecific/swap.png")
extends Control
class_name SwapBox
#NEEDS MAJOR REFACTORING, REMOVE RELIANCE ON SWAP RULES

#--------------------------------------
#region VARIABLES
@export var side: CardSideUI
@export var singles: bool = true
 #Should probably work on replacing this with somethig that prevents circular reference
var swap_rules: EnMov = null

@onready var playing_list: PlayingList = %PlayingList
@onready var slot_list: SlotList = %SlotList
@onready var header: UIHeader = %Header
@onready var footer: PanelContainer = %Footer
@onready var energy_types: EnergyCollection = %EnergyTypes

signal finished

const stack = Consts.STACKS.PLAY
const stack_act = Consts.STACK_ACT.ENSWAP

var swaps_made: int = 0
var energy_swapping: int = 0
var energy_swapped: int = 0
var giver: PokeSlotButton
var reciever: PokeSlotButton
var energy_given: Array[PlayingButton]
var swap_history: Array[Dictionary] = []
#endregion
#--------------------------------------

#--------------------------------------
#region INITALIZATION & PROCESSING
func _ready() -> void:
	slot_list.side = side
	slot_list.singles = singles
	slot_list.setup()
	
	for button in slot_list.slots:
		button.pressed.connect(handle_pressed_slot.bind(button))
	
	update_info()
	header.setup("[center]SWAP BOX")
	footer.setup("PRESS ESC TO UNDO")
	slot_list.find_allowed_givers(swap_rules.givers)

#If this is closable be ready to reverse changes upon closee
func make_closable() -> void:
	%Header.closable = true

func manage_input(event: InputEvent) -> void:
	if event.is_action("Back"):
		if giver != null:
			giver.selected = false
			giver = null
			playing_list.reset_items()
			slot_list.find_allowed_givers(swap_rules.givers)
		elif reciever != null:
			reciever.selected = false
			reciever = null
			slot_list.find_allowed(swap_rules.reciever)
		elif energy_given.size() > 0:
			energy_given.pop_back().selected = false
			allowed_more_energy()
			display_current_swap()
		elif swap_history.size() != 0:
			undo_swap()
		else:
			header.handle_back(event)
		update_info()

#endregion
#--------------------------------------

#--------------------------------------
#region GIVE/RECIEVE
func handle_pressed_slot(slot_button: PokeSlotButton):
	#Add giver when there is none
	if giver == null:
		giver = replace_with_button(giver, slot_button)
		get_swappable(slot_button)
		slot_list.find_allowed(swap_rules.reciever)
		#Allow for reset
		giver.disabled = false
	#Reset by deselecting giver
	elif giver == slot_button:
		reset()
	#Replace current reciever with chosen button
	elif reciever != slot_button:
		reciever = replace_with_button(reciever, slot_button)
	#Deselect reciever
	else:
		reciever = replace_with_button(reciever, null)
	update_info()

func replace_with_button(which: PokeSlotButton, with: PokeSlotButton) -> PokeSlotButton:
	if which != null:
		which.selected = false
	if with != null:
		with.selected = true
	return with

func get_swappable(slot_button: PokeSlotButton):
	playing_list.reset_items()
	var energy_dict: Dictionary[Base_Card, bool] = {}
	
	slot_button.slot.count_energy()
	for card in slot_button.slot.energy_cards:
		#Asume true for now, make a function to see if it fails or not later
		energy_dict[card] = swap_rules.energy_allowed(card, false)
	
	playing_list.list = energy_dict
	playing_list.all_lists = [energy_dict]
	playing_list.set_items()
	for button in playing_list.get_items():
		button.select.connect(select_energy.bind(button))
#endregion
#--------------------------------------

#--------------------------------------
#region ENERGY SELECTION
func select_energy(button: PlayingButton):
	button.selected = not button.selected
	if button.selected:
		energy_given.append(button)
	else:
		energy_given.erase(button)
	
	display_current_swap()
	allowed_more_energy()
	update_info()

func allowed_more_energy():
	if swap_rules.enough_energy(energy_given.size() + energy_swapped):
		for button in playing_list.get_items():
			if button.selected: continue
			button.disabled = true
	else:
		for button in playing_list.get_items():
			button.disabled = not playing_list.list[button.card]

func display_current_swap():
	var energy_dict: Dictionary[String, int] = {"Grass": 0, "Fire": 0, "Water": 0,
	 "Lightning": 0, "Psychic":0, "Fighting":0 ,"Darkness":0, "Metal":0,
	 "Colorless":0, "Magma":0, "Aqua":0, "Dark Metal":0, "React": 0, 
	 "FF": 0, "GL": 0, "WP": 0, "Rainbow":0}
	var energy_names: Array[String]
	
	for button in energy_given:
		var en_provide: EnData = button.card.energy_properties.get_current_provide()
		var energy_name: String = en_provide.get_string()
		energy_names.append(energy_name)
		energy_dict[energy_name] += en_provide.number
	
	energy_types.display_energy(energy_names, energy_dict)

#endregion
#--------------------------------------

#--------------------------------------
#region UI UPDATES
func update_info():
	energy_swapping = energy_given.size()
	%indSwapNum.clear()
	%Instructions.clear()
	
	var giver_txt: String = str("Giver: ", 
	"" if giver == null else giver.slot.current_card.name)
	var reciever_txt: String = str("Reciever: ", 
	"" if reciever == null else reciever.slot.current_card.name)
	var giving_txt: String = str(energy_swapping,"/",
	swap_rules.energy_ammount - energy_swapped if swap_rules.energy_ammount != -1 else "X")
	var actions_left: String = str("Swaps Left: ",swaps_made,"/",
	swap_rules.action_ammount if swap_rules.action_ammount != -1 else "X")
	var swap_ready: bool = reciever == null or energy_swapping == 0
	
	%indSwapNum.append_text(giving_txt)
	%Instructions.append_text(str(giver_txt,"\n",reciever_txt,"\n",actions_left))
	%Swap.text = str("Swap" if swap_ready else "Swap Ready")
	%Swap.disabled = swap_ready

func anymore_swaps_allowed():
	if swap_rules.enough_actions(swaps_made) or swap_rules.enough_energy(energy_swapped):
		slot_list.disable_all()
		print("NO MORE SWAPS")

func reset():
	energy_swapping = 0
	playing_list.reset_items()
	energy_types.reset_energy()
	energy_types.hide()
	slot_list.refresh_energy()
	energy_given.clear()
	slot_list.deselect_all()
	
	if giver != null:
		giver.selected = false
		giver = null
	if reciever != null:
		reciever.selected = false
		reciever = null
	
	slot_list.find_allowed_givers(swap_rules.givers)
	update_info()
#endregion
#--------------------------------------

func record_swap(giv: PokeSlot, rec: PokeSlot, cards: Array[Base_Card]):
	var swap_log: Dictionary = {"Giver": null, "Reciever": null, "Cards": null}
	
	swap_log["Giver"] = giv
	swap_log["Reciever"] = rec
	swap_log["Cards"] = cards
	
	swap_history.append(swap_log)
	print(swap_log)

func undo_swap():
	var latest_log = swap_history.pop_back()
	print("REVERSING: ", latest_log)
	swap_rules.swap(latest_log["Reciever"], latest_log["Giver"], latest_log["Cards"])
	swaps_made -= 1
	reset()
	anymore_swaps_allowed()

#--------------------------------------
#region SIGNALS
func _on_end_pressed() -> void:
	finished.emit()
	SignalBus.remove_top_ui.emit()

func _on_swap_pressed() -> void:
	#First convert the list into a list of base_cards
	var card_list: Array[Base_Card] = []
	
	for button in energy_given:
		card_list.append(button.card)
	
	swap_rules.swap(giver.slot, reciever.slot, card_list.duplicate())
	record_swap(giver.slot, reciever.slot, card_list)
	swaps_made += 1
	#Only record previously swapped if the rules ask for it
	if swap_rules.energy_carry_over:
		energy_swapped += energy_swapping
	reset()
	anymore_swaps_allowed()

#Reverse any changes made if closed prematurely
func _on_header_close_button_pressed() -> void:
	if %Header.closable:
		SignalBus.went_back.emit()
		for swap_log in swap_history:
			undo_swap()
	else: push_error("Closed when shouldn't be able to")

#endregion
#--------------------------------------
