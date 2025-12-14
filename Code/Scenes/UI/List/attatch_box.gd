@icon("res://Art/ProjectSpecific/swap.png")
extends Control
class_name AttatchBox

#--------------------------------------
#region VARIABLES
@export var side: CardSideUI
@export var singles: bool
@export var stack: Consts.STACKS
@export var stack_act: Consts.STACK_ACT

@onready var header: HBoxContainer = %Header
@onready var footer: PanelContainer = %Footer
@onready var slot_list: SlotList = %SlotList
@onready var playing_list: PlayingList = %PlayingList
@onready var energy_types: EnergyCollection = %EnergyTypes

signal finished

var list: Dictionary[Base_Card, bool]
var action_ammount: int = 1
var energy_ammount: int = 1
var actions_made: int = 0
var energy_attatch_num: int = 0
var reciever_ask: SlotAsk
var allowed_energy: EnData
var reciever: PokeSlotButton
var energy_giving: Array[PlayingButton]
var attatch_history: Array[Dictionary]
#endregion
#--------------------------------------

#--------------------------------------
#region INITALIZATION & PROCESSING
func _ready() -> void:
	slot_list.side = side
	slot_list.singles = singles
	slot_list.setup()
	playing_list.list = list
	playing_list.all_lists = [list]
	playing_list.set_items()
	
	for button in slot_list.slots:
		button.pressed.connect(handle_pressed_slot.bind(button))
	
	playing_list.connect_to_select(select_energy)
	update_info()
	header.setup("[center]ATTATCH BOX")
	footer.setup("PRESS ESC TO UNDO")
	slot_list.find_allowed_givers(reciever_ask, "")

#If this is closable be ready to reverse changes upon closee
func make_closable() -> void:
	%Header.closable = true
		
#endregion
#--------------------------------------

#--------------------------------------
#region GIVE/RECIEVE
func handle_pressed_slot(slot_button: PokeSlotButton):
	if reciever != slot_button:
		reciever = replace_with_button(reciever, slot_button)
	else:
		reciever = replace_with_button(reciever, null)
	
	update_info()

func replace_with_button(orig: PokeSlotButton, new: PokeSlotButton) -> PokeSlotButton:
	if orig != null:
		orig.theme_type_variation = ""
	if new != null:
		new.theme_type_variation = "DragButton"
	return new

#endregion
#--------------------------------------

#--------------------------------------
#region ENERGY SELECTION
func select_energy(button: PlayingButton):
	
	button.selected = not button.selected
	if button.selected:
		energy_giving.append(button)
	elif button in energy_giving:
		energy_giving.erase(button)
	
	allowed_more_energy()
	update_info()

func allowed_more_energy():
	if energy_giving.size() == energy_ammount:
		for button in playing_list.get_items():
			if button.selected: continue
			button.disabled = true
	else:
		for button in playing_list.get_items():
			button.disabled = not playing_list.list[button.card]

func display_current_attatch():
	var energy_dict: Dictionary[String, int] = {"Grass": 0, "Fire": 0, "Water": 0,
	 "Lightning": 0, "Psychic":0, "Fighting":0 ,"Darkness":0, "Metal":0,
	 "Colorless":0, "Magma":0, "Aqua":0, "Dark Metal":0, "React": 0, 
	 "FF": 0, "GL": 0, "WP": 0, "Rainbow":0}
	var energy_names: Array[String]
	
	for button in energy_giving:
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
	energy_attatch_num = energy_giving.size()
	%Instructions.clear()
	
	var actions_left: String = str("Attatchments Left: ",actions_made,"/",
	action_ammount if action_ammount != -1 else "X")
	var reciever_txt: String = str("\nReciever: ", reciever.slot.get_card_name() if reciever else "")
	
	%Instructions.append_text(str(actions_left,reciever_txt))
	%Reset.disabled = actions_made == 0
	%Attatch.disabled = energy_giving.size() == 0 or reciever == null
	
	display_current_attatch()

func anymore_attatchments_allowed():
	if actions_made == action_ammount:
		slot_list.disable_all()
		playing_list.disable_items()

func refresh():
	energy_giving.clear()
	slot_list.refresh_energy()
	energy_types.reset_energy()
	
	if reciever != null:
		reciever.theme_type_variation = ""
		reciever = null
	
	allowed_more_energy()
	slot_list.find_allowed_givers(reciever_ask, "")
	update_info()

func reset():
	actions_made = 0
	playing_list.reset_items()
	playing_list.set_items()
	playing_list.connect_to_select(select_energy)
	
	refresh()
#endregion
#--------------------------------------

#--------------------------------------
#region SIGNALS
func _on_end_pressed() -> void:
	print(attatch_history)
	Globals.control_hide(self, .05)
	
	for attatchment in attatch_history:
		Globals.fundies.stack_manager.get_stacks(side.home).move_cards(
			attatchment["Energy"], Consts.STACKS.HAND, Consts.STACKS.PLAY)
		
		await attatchment["Slot"].count_en_attatch_signals(attatchment["Energy"])
	
	finished.emit()
	SignalBus.remove_top_ui.emit()

func _on_attatch_pressed() -> void:
	print("Attatch")
	var attatch_log: Dictionary = {"Slot" : reciever.slot as PokeSlot,
	 "Energy" : [] as Array[Base_Card]}
	
	for en in energy_giving:
		reciever.slot.signaless_attatch_energy(en.card)
		attatch_log["Energy"].append(en.card)
		playing_list.remove_item(en.card)
	
	attatch_history.append(attatch_log)
	actions_made += 1
	refresh()
	anymore_attatchments_allowed()

func _on_reset_pressed() -> void:
	for attatchment in attatch_history:
		for en in attatchment["Energy"]:
			attatchment["Slot"].signaless_remove_energy(en)
			playing_list.add_item(en)
	reset()
	
	attatch_history.clear()
#endregion
#--------------------------------------
