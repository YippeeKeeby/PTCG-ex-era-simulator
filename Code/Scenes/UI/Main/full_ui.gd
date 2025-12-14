extends CanvasLayer
class_name FullBoardUI

@export var singles: bool = true
@export var side_rules: int = 3
@export var side_ui: Array[PackedScene]
@export var disapear_timing: float = .075

var current_card: Control

@onready var end_turn: Button = $EndTurn
@onready var player_side: CardSideUI
@onready var opponent_side: CardSideUI
@onready var sides: Array[CardSideUI] = [player_side, opponent_side]
@onready var stadium: Button = %ArtButton

var home_side: Consts.PLAYER_TYPES
var ui_stack: Array[Control] = []
var every_slot: Array[UI_Slot]

#--------------------------------------
#region INITALIZATION & PROCESSING
func _ready() -> void:
	get_sides()
	%ArtButton.get_child(0).size = %ArtButton.size
	%ArtButton.current_card = null
	Globals.full_ui = self
	#every_slot = player_side.get_slots() + opponent_side.get_slots()

func get_sides():
	if side_rules && 1: #Doubles Position (479, 579)
		player_side = side_ui[2].instantiate()
		
	else: #Singles Position (57, 366)
		player_side = side_ui[0].instantiate()
	
	player_side.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	add_child(player_side)
	
	if side_rules && 2: #Doubles Away (113, -30)
		opponent_side = side_ui[3].instantiate()
		
	else: #Singles Away (57, 18)
		opponent_side = side_ui[1].instantiate()
	
	opponent_side.set_anchors_preset(Control.PRESET_TOP_WIDE)
	add_child(opponent_side)

#endregion
#--------------------------------------

#--------------------------------------
#region HELPERS
func get_player_type(side: Consts.SIDES) -> Consts.PLAYER_TYPES:
	return get_const_side(side).player_type

func get_home_side(home: bool) -> CardSideUI:
	return player_side if home else opponent_side

func get_const_side(side: Consts.SIDES) -> CardSideUI:
	print(Convert.side_into_string(side))
	return get_home_side(Globals.fundies.get_considered_home(side))

func all_slots() -> Array[UI_Slot]:
	return player_side.get_slots() + opponent_side.get_slots()

func get_slots(side: Consts.SIDES, slot: Consts.SLOTS) -> Array[UI_Slot]:
	return all_slots().filter(func(uislot: UI_Slot):
		return uislot.connected_slot.is_in_slot(side, slot))

func get_poke_slots(side: Consts.SIDES = Consts.SIDES.BOTH,
 slot: Consts.SLOTS = Consts.SLOTS.ALL) -> Array[PokeSlot]:
	var pokeslots: Array[PokeSlot]
	for ui_slot in every_slot:
		if ui_slot.connected_slot.is_in_slot(side, slot):
			pokeslots.append(ui_slot.connected_slot)
	
	return pokeslots

func get_ask_slots(ask: SlotAsk) -> Array[PokeSlot]:
	var pokeslots: Array[PokeSlot]
	for ui_slot in every_slot:
		if ask.check_ask(ui_slot.connected_slot):
			pokeslots.append(ui_slot.connected_slot)
	return pokeslots

func get_aks_minus_immune(ask: SlotAsk, immune: Consts.IMMUNITIES) -> Array[PokeSlot]:
	var pokeslots: Array[PokeSlot]
	for ui_slot in every_slot:
		if Globals.fundies.check_immunity(immune,\
		Globals.fundies.get_first_target(true), ui_slot.connected_slot):
			continue
		if ask.check_ask(ui_slot.connected_slot):
			pokeslots.append(ui_slot.connected_slot)
	return pokeslots

func get_occurance_slots() -> Array[PokeSlot]:
	var pokeslots: Array[PokeSlot]
	for ui_slot in every_slot:
		if ui_slot.connected_slot.is_filled() and ui_slot.connected_slot.has_occurance():
			pokeslots.append(ui_slot.connected_slot)
	return pokeslots

func get_self() -> PokeSlot:
	for ui_slot in every_slot:
		var slot: PokeSlot = ui_slot.connected_slot
		if slot.is_filled() and slot.is_in_slot(Consts.SIDES.SOURCE, Consts.SLOTS.TARGET):
			return slot
	return null

#endregion
#--------------------------------------

#--------------------------------------
#region CARD MANAGEMENT
func remove_card() -> void:
	print("IHJBEFDI")

func update_stacks(dict: Dictionary[Consts.STACKS,Array], side: bool):
	var temp_side: CardSideUI = get_home_side(side)
	for stack in dict:
		if stack == Consts.STACKS.PLAY: break
		temp_side.non_mon.update_stack(stack, dict[stack].size())
#endregion
#--------------------------------------

#--------------------------------------
#region UI MANAGEMENT
#Send inputs only to the top UI
func _input(event: InputEvent) -> void:
	#This is only for button inputs, mouse inputs are supported through node built in functions
	if event is InputEventMouse or not event.is_pressed():
		return
	if ui_stack[-1].has_method("manage_input"):
		ui_stack[-1].manage_input(event)
	if event.is_action_pressed("A") and Globals.checking:
		remove_card()

#Set top ui every time a new one is created
func set_top_ui(node: Control, par: Node = self):
	node.z_index = ui_stack[-1].z_index + 1
	par.add_child(node)
	ui_stack.append(node)
	disable_sides()
	print("Just added, so now ", ui_stack)

#Set the top UI for removal 
func remove_top_ui():
	control_disapear(ui_stack.pop_back())
	print("Just removed so now: ", ui_stack)
	if ui_stack.size() == 1:
		enable_sides()

func enable_sides():
	for slot in Globals.full_ui.every_slot:
		slot.make_allowed(slot.connected_slot.is_filled())

func disable_sides():
	for slot in every_slot:
		slot.make_allowed(false)

func control_disapear(node: Node):
	var disapear_tween: Tween = get_tree().create_tween().set_parallel()
	
	disapear_tween.tween_property(node, "position", ui_stack[-1].global_position, disapear_timing)
	disapear_tween.tween_property(node, "modulate", Color.TRANSPARENT, disapear_timing)
	disapear_tween.tween_property(node, "scale", Vector2(.1,.1), disapear_timing)
	
	await disapear_tween.finished
	
	node.queue_free()

func display_changes(home: bool, change_array: Array[Dictionary]):
	get_home_side(home).non_mon.change_display.set_changes(change_array)

#endregion
#--------------------------------------

func set_between_turns():
	player_side.non_mon.clear_supporter()
	player_side.non_mon.sync_stacks()
	opponent_side.non_mon.clear_supporter()
	opponent_side.non_mon.sync_stacks()
	end_turn.disabled = not Globals.fundies.is_home_side_player()
	
	for slot in every_slot:
		await slot.connected_slot.pokemon_checkup()
