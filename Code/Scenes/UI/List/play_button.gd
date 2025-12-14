extends Button
class_name PlayingButton

@export var card: Base_Card
@export var option_offset: Vector2 = Vector2(30, 100)
@export_flags("Basic", "Evolution", "Item",
"Supporter", "Stadium", "Tool", "TM", "RSM", "Fossil",
 "Energy") var card_flags: int = 0

signal select

var from_id: Identifier
var parent: Node
var checking_card: Node
var stack_act: Consts.STACK_ACT
var disable_flags: int = 0
var allowed: bool = false
var selected: bool = false:
	set(value):
		selected = value
		if value:
			theme_type_variation = "DragButton"
		else:
			theme_type_variation = ""


#--------------------------------------
#region INITALIZATION
func _ready() -> void:
	if not card:
		printerr("There is no card on ", self)
		return

	%Class.clear()
	card_flags = Convert.get_card_flags(card)
	
	if card_flags & 1 or card_flags & 2: %Class.append_text(card.pokemon_properties.evo_stage)
	elif card_flags & 8: %Class.append_text("Support")
	elif card_flags & 128: %Class.append_text("RSM")
	elif card_flags & 256: %Class.append_text("Fossil")
	elif card_flags & 512: %Class.append_text(card.energy_properties.considered)
	else: %Class.append_text(card.trainer_properties.considered)
	
	%Art.texture = card.image
	%Name.clear()
	%Name.append_text(card.name)
	
	set_name(card.name)

func allow(play_as: int):
	#var check_first: Array[String] = Convert.flags_to_allowed_array(play_as)
	#var allowed_as = Globals.fundies.can_be_played(card)
	printt("ALLOW CHECK:",card.name,play_as & card_flags, play_as, card_flags)
	#printt("ALLOWED AS:", allowed_as)
	card_flags = play_as & card_flags
	
	#if allowed_as != card_flags:
		#disable_flags = card_flags - allowed_as
	allowed = true
	disabled = false

func not_allowed():
	allowed = false
	disabled = true

func allow_move_to(destination: Consts.STACKS):
	allowed = true
	disabled = false
	#match destination:
		#Consts.STACKS.DISCARD: stack_act = Consts.STACK_ACT.DISCARD
		#Consts.STACKS.PLAY: stack_act = Consts.STACK_ACT.TUTOR

func is_tutored() -> bool:
	return not parent is PlayingList

#endregion
#--------------------------------------

func deselect():
	selected = false

#--------------------------------------
#region ACTIONS
#probably should add a way to check if closer to left or right
func show_options() -> Node:
	var option_Display = load("res://Scenes/UI/Lists/item_options_copy.tscn").instantiate()
	option_Display.card_flags = card_flags
	option_Display.scale = Vector2(.05, .05)
	option_Display.modulate = Color.TRANSPARENT
	option_Display.origin_button = self
	option_Display.stack_act = stack_act if allowed else Consts.STACK_ACT.LOOK
	
	Globals.full_ui.set_top_ui(option_Display, Globals.full_ui.ui_stack[-1])
	option_Display.tree_exited.connect(deselect)
	option_Display.position = get_option_position(option_Display)
	option_Display.bring_up()
	
	return option_Display

func get_option_position(option: ItemOptions) -> Vector2:
	var set_pos: Vector2 = Vector2.ZERO
	var adjustment: float
	
	if parent is PlayingList:
		adjustment = parent.par.global_position.y
	#I should adjust tutoring to remove the option popup
	else:
		adjustment = parent.global_position.y
	
	set_pos.y = %LeftSpawn.global_position.y - adjustment
	if %RightSpawn.global_position.x > float(get_window().size.x) / 2:
		set_pos.x = %LeftSpawn.position.x - option_offset.x
	else:
		set_pos.x = %RightSpawn.position.x
	
	return set_pos

func _gui_input(event):
	if not disabled:
		if event.is_action_pressed("A"):
			if stack_act == Consts.STACK_ACT.DISCARD or stack_act == Consts.STACK_ACT.ENSWAP\
			or stack_act == Consts.STACK_ACT.MIMIC:
				select.emit()
			elif stack_act != Consts.STACK_ACT.LOOK:
				if parent.options:
					SignalBus.remove_top_ui.emit()
					await SignalBus.finished_remove_top_ui
				if not Globals.checking:
					parent.options = show_options()
			elif stack_act == Consts.STACK_ACT.LOOK:
				Globals.show_card(card, self)
	if event.is_action_pressed("Check"):
		Globals.show_card(card, self)

#endregion
#--------------------------------------
