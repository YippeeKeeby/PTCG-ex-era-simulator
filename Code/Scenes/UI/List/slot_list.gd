@icon("res://Art/ProjectSpecific/swap.png")
extends ScrollContainer
class_name SlotList

@export var side: CardSideUI
@export var singles: bool = true

var slots: Array[PokeSlotButton]

func setup():
	for node in %SlotList.get_children():
		slots.append(node as PokeSlotButton)
		node.set_slotNum(node.name)
	
	if singles:
		%SlotList.move_child(slots[1], -1)
		slots[1].set_slotNum("B5")
	else:
		slots[1].set_slotNum("A2")
	
	list_items()

func list_items():
	var ui_slots: Array[UI_Slot]
	if side != null:
		ui_slots = side.get_slots()
	
		for i in range(%SlotList.get_child_count()):
			if ui_slots[i].connected_slot.is_filled():
				slots[i].setup(ui_slots[i].connected_slot)

func refresh_energy():
	for node in %SlotList.get_children():
		if node.slot:
			node.set_energy()

func disable_all():
	for node in %SlotList.get_children():
		node.disabled = true

func deselect_all():
	for node in %SlotList.get_children():
		node.selected = false

func find_allowed(ask: SlotAsk):
	for node in %SlotList.get_children():
		if node.slot:
			node.disabled = not ask.check_ask(node.slot)

func find_allowed_givers(ask: SlotAsk, box: String = "Swap"):
	if not ask:
		return
	
	var givers: Array[PokeSlot] = Globals.full_ui.get_ask_minus_immune(ask, Consts.IMMUNITIES.ATK_EFCT_OPP)
	
	for node in %SlotList.get_children():
		if node.slot:
			print("Is ", node.slot.get_card_name(), " allowed?", (not node.slot in givers), safeguard(node.slot, box))
			node.disabled = (not node.slot in givers) or safeguard(node.slot, box)

func find_allowed_either(ask_giv: SlotAsk, ask_take: SlotAsk, box = "DmgGive"):
	var allowed_as: Dictionary[int, String]
	for node in %SlotList.get_children():
		if node.slot:
			#Would the card be valid if it was a giver?
			var giver: bool = not safeguard(node.slot, box) and ask_giv.check_ask(node.slot) 
			var taker: bool = ask_take.check_ask(node.slot)
			
			if giver and taker:
				allowed_as[node.get_instance_id()] = "Both"
			elif giver:
				allowed_as[node.get_instance_id()] = "Giver"
			elif taker:
				allowed_as[node.get_instance_id()] = "Taker"
			else:
				allowed_as[node.get_instance_id()] = "None"
			
			
			node.disabled = not (giver or taker)
	
	return allowed_as

func safeguard(slot: PokeSlot, box: String):
	match box:
		"Swap":
			return slot.energy_cards.size() == 0
		"DmgGive":
			return slot.damage_counters == 0
	
	return false
