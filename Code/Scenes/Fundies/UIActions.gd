@icon("res://Art/ProjectSpecific/trading.png")
extends Node
class_name SlotUIActions

#--------------------------------------
#region VARIABLES
@export var preload_debug: bool = false
@export var cancel_txt: String = "Esc to go back"
@export var no_return_txt: String = "No going back"
@export var ability_ani_offset: Vector2
@export var ability_ani_time: float = 1
@export var color_tween_timing: float = .1

signal chosen
signal choice_ready

var adding_card: Base_Card = null
var selected_slot: PokeSlot = null
var allowed_slots: Array[UI_Slot]
var act_on_self: bool = true
var choosing: bool = false
var can_reverse: bool = false

#endregion
#--------------------------------------
func _ready():
	SignalBus.connect("chosen_slot", left_button_actions)

#--------------------------------------
#region HELPER FUNCTIONS
func set_adding_card(for_card: Base_Card) -> void:
	adding_card = for_card

#endregion
#--------------------------------------

#--------------------------------------
#region INPUTS
func left_button_actions(target: PokeSlot):
	if choosing:
		if adding_card:
			selected_slot = target
			Globals.fundies.card_player.record_candidate(target)
			adding_card = null
		else:
			SignalBus.get_candidate.emit(target)
		
		#target.refresh()
		reset_ui()

func _input(event: InputEvent) -> void:
	if event.is_action("Back") and can_reverse:
		reset_ui()

func get_choice(instruction: String):
	%AskInstructions.show()
	%Instructions.clear()
	%Instructions.append_text(str("[center]",instruction))
	%CancelText.clear()
	%CancelText.append_text(cancel_txt if can_reverse else no_return_txt)
	$ColorRect.show()
	await color_tween(Color.WHITE)
	
	choosing = true
	for slot in allowed_slots:
		slot.switch_shine(true)

#endregion
#--------------------------------------

#--------------------------------------
#region CHOICE MANAGEMENT
#Use a lambda function to get different boolean functions
func get_allowed_slots(condition: Callable) -> void:
	allowed_slots = Globals.fundies.find_allowed_slots(condition, Consts.SIDES.BOTH)
	
	if Globals.fundies.atk_efect:
		var poke_slots: Array[PokeSlot]
		for slot in allowed_slots:
			poke_slots.append(slot.connected_slot)
		if Globals.fundies.atk_efect:
			poke_slots = Globals.fundies.filter_immune(Consts.IMMUNITIES.ATK_EFCT_OPP, poke_slots)
		
		allowed_slots = allowed_slots.filter(func (ui: UI_Slot):
			return ui.connected_slot in poke_slots)
	
	for slot in Globals.full_ui.every_slot:
		if slot in allowed_slots:
			slot.z_index = 1
			slot.make_allowed(true)
		else:
			slot.z_index = 0
			slot.make_allowed(false)

func color_tween(destination: Color):
	var color_tweener: Tween = create_tween().set_parallel()
	color_tweener.tween_property($ColorRect, "modulate", destination, color_tween_timing)
	await color_tweener.finished
	choice_ready.emit()

func reset_ui():
	%AskInstructions.hide()
	#Check every previously allowed slot
	#Reset them to look and display like the rest
	for ui_slot in allowed_slots:
		ui_slot.z_index = 0
		ui_slot.switch_shine(false)
	
	#Check every slot to see if they have a pokemon in them
	#If so, let them be checked again
	for slot in Globals.full_ui.every_slot:
		slot.make_allowed(slot.connected_slot.is_filled())
	
	choosing = false
	can_reverse = false
	await color_tween(Color.TRANSPARENT)
	chosen.emit()

#endregion
#--------------------------------------

func play_ability_activate(slot: PokeSlot, ability: Ability):
	%AbilityActivate.show()
	var animation_tween: Tween = get_tree().create_tween().set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT).set_parallel(true)
	var base_pos: Vector2 = slot.ui_slot.global_position
	%AbilityName.clear()
	%AbilityName.visible_ratio = 0
	%AbilityActivate.position = base_pos + ability_ani_offset * 2
	%AbilityActivate.modulate = Color.TRANSPARENT
	
	if ability.category == "Body":
		%AbilityTab.current_tab = 0
		%AbilityName.push_color(Color(0.639, 0.875, 0.447))
	else:
		%AbilityTab.current_tab = 1
		%AbilityName.push_color(Color(0.895, 0.583, 0.625))
	
	%AbilityName.append_text(str(slot.get_card_name(), "'s\n", ability.name))
	
	animation_tween.tween_property(%AbilityName, "visible_ratio", 1.0, ability_ani_time * 2/3)
	animation_tween.tween_property($ColorRect, "modulate", Color.WHITE, ability_ani_time * 3/4)
	animation_tween.tween_property(%AbilityActivate, "modulate", Color.WHITE, ability_ani_time * 3/4)
	animation_tween.tween_property(%AbilityActivate, "position", base_pos, ability_ani_time * 3/4)
	slot.ui_slot.ability_occured(slot.get_pokedata().pokebody == ability, ability_ani_time * 5/3)
	
	await animation_tween.finished
	
	animation_tween.stop()
	animation_tween.set_ease(Tween.EASE_IN)
	animation_tween.tween_property($ColorRect, "modulate", Color.TRANSPARENT, ability_ani_time/8)
	animation_tween.tween_property(%AbilityActivate, "position", base_pos - ability_ani_offset, ability_ani_time/4)
	animation_tween.play()
	
	await animation_tween.finished
	%AbilityActivate.hide()
