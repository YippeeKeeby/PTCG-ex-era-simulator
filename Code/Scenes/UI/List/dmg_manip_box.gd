@icon("res://Art/Counters/Spiral.png")
extends Control
class_name DmgManipBox

#--------------------------------------
#region VARIABLES
@export var side: CardSideUI
@export var second_side: CardSideUI
@export var singles: bool = true

@onready var slot_list: SlotList = %SlotList
@onready var header: HBoxContainer = %Header
@onready var footer: PanelContainer = %Footer

signal finished

var swap_candidates: Dictionary[int, String]
var first_ask: SlotAsk
var second_ask: SlotAsk
var mode: String
var prevent_ko: bool = false
var max_counters: int = 0
var counters_left: int = 0
var counters_swap_away: int = 0
#endregion
#--------------------------------------
#DamageManip
#For now this is only used with Add dmg so only worry about that
#Test this with DF91, UF28, MA33, SS4, LM5, CG56
func _ready() -> void:
	if not side:
		return
	side = Globals.full_ui.get_const_side(first_ask.side_target)
	slot_list.side = side
	slot_list.singles = not Globals.board_state.doubles
	slot_list.setup()
	
	for button in slot_list.slots:
		button.pressed.connect(handle_pressed_slot.bind(button), Object.CONNECT_DEFERRED)
		#button.pressed.connect(func(): handle_pressed_slot.call_deferred(button))
	
	counters_left = max_counters
	header.setup(str("COUNTER ",mode.to_upper()," BOX"))
	footer.setup("PRESS ESC TO UNDO")
	if mode ==  "Swap":
		swap_candidates = slot_list.find_allowed_either(first_ask, second_ask, "DmgGive")
		only_givers()
	else:
		slot_list.find_allowed_givers(first_ask, "")
	update_info()

#If this is closable be ready to reverse changes upon closee
func make_closable() -> void:
	%Header.closable = true

func handle_pressed_slot(slot_button: PokeSlotButton):
	if counters_left != 0 or mode == "Swap":
		#Once I find a card that uses Remove/Swap in 'anyway you like', I'll make those two
		match mode:
			"Add":
				add_counter(slot_button)
			"Remove":
				remove_counter(slot_button)
			"Swap":
				if swap_candidates[slot_button.get_instance_id()] == "Both":
					pass
				elif swap_candidates[slot_button.get_instance_id()] == "Giver":
					remove_counter(slot_button)
				elif swap_candidates[slot_button.get_instance_id()] == "Taker":
					add_counter(slot_button)
				check_enable()
		
		update_info()
		anymore_actions_allowed()

func leftover_couters(slot_button: PokeSlotButton) -> bool:
	var any_left: bool
	var difference: int = slot_button.slot.damage_counters + slot_button.counter_change.current_dmg
	
	if prevent_ko:
		any_left = difference == slot_button.slot.get_max_hp() - 10
	else:
		any_left = difference == slot_button.slot.get_max_hp()
	
	return difference <= 0 or any_left

func add_counter(slot_button: PokeSlotButton):
	if mode == "Swap":
		counters_swap_away += 1
	else:
		counters_left -= 1
	slot_button.manip_counters(1)

func remove_counter(slot_button: PokeSlotButton):
	counters_left -= 1
	slot_button.manip_counters(-1)

func update_info():
	%Instructions.clear()
	#Only add to this when mode is swap
	%indSwapNum.clear()
	
	if mode == "Swap":
		var givers: PackedStringArray
		var takers: PackedStringArray
		for id in swap_candidates:
			var node: PokeSlotButton = instance_from_id(id) as PokeSlotButton
			if swap_candidates[id] == "Giver":
				givers.append(node.slot.get_card_name())
			elif swap_candidates[id] == "Taker":
				takers.append(node.slot.get_card_name())
		%Instructions.append_text(str("Givers: ",givers , "\nTakers: ",takers))
	else:
		%Instructions.append_text(str(mode, " counters: ", counters_left, "/", max_counters))

func only_givers():
	for id in swap_candidates:
		if swap_candidates[id] == "Takers":
			instance_from_id(id).disabled = true

func check_enable():
	for id in swap_candidates:
		if swap_candidates[id] != "None":
			instance_from_id(id).disabled = leftover_couters(instance_from_id(id))
			if swap_candidates[id] != "Taker":
				instance_from_id(id).disabled = instance_from_id(id).disabled or counters_left == 0
			if swap_candidates[id] != "Giver":
				instance_from_id(id).disabled = instance_from_id(id).disabled or counters_swap_away == max_counters

func reenable_all():
	for id in swap_candidates:
		var button = instance_from_id(id)
		if swap_candidates[id] != "None":
			button.disabled = false
		else:
			button.disabled = true

func anymore_actions_allowed():
	if mode == "Swap":
		%End.disabled = counters_left != max_counters - counters_swap_away
	else:
		%End.disabled = counters_left != 0

func reset():
	counters_left = max_counters
	
	for slot in slot_list.slots:
		slot.reset_counters()
	
	slot_list.find_allowed_givers(first_ask, "DmgTake")
	if mode == "Swap":
		counters_swap_away = 0
		reenable_all()
	
	update_info()
	anymore_actions_allowed()

func _on_clear_pressed() -> void:
	reset()

func _on_end_pressed() -> void:
	%End.disabled = true
	
	for slot_button in slot_list.slots:
		if not slot_button.slot:
			continue
		slot_button.slot.dmg_manip(slot_button.counter_change.current_dmg)
	
	finished.emit()
