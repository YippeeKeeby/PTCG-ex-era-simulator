extends Node

#For any node that can bring up the check card display
var checking: bool = false
var dragging: bool = false
var checked_card: Control
var fundies: Fundies
var full_ui: FullBoardUI
var coinflip: Control
var board_state: BoardState
var removing: bool = false

signal enter_check
signal exit_check

func show_card(card: Base_Card, parent: Node):
	if checked_card:
		remove_card()
	
	var considered: String = card.card_display()
	var card_display: Node
	match considered:
		"Pokemon":
			card_display = Consts.poke_card.instantiate()
			card_display.checking = true
		"Trainer":
			if card.fossil:
				card_display = Consts.fossil_card.instantiate()
			else:
				card_display = Consts.trainer_card.instantiate()
		"Energy":
			card_display = Consts.energy_card.instantiate()
	
	card_setup(card, card_display, parent)

func show_slot_card(slot: PokeSlot):
	if checked_card:
		remove_card()
	var card_display
	if slot.current_card.fossil:
		card_display = Consts.fossil_card.instantiate()
	else:
		card_display = Consts.poke_card.instantiate()
	card_display.checking = true
	card_display.old_pos = slot.ui_slot.global_position
	card_display.poke_slot = slot
	
	card_setup(slot.current_card, card_display, slot.ui_slot)

func card_setup(card: Base_Card, card_display: Node, parent: Node):
	var node_tween: Tween = get_tree().create_tween().set_parallel(true)
	
	card_display.card = card
	card_display.top_level = true
	card_display.scale = Vector2(.05, .05)
	card_display.modulate = Color.TRANSPARENT
	card_display.name = str(card.name, " Card")
	if full_ui.ui_stack.size() > 1:
		card_display.position = full_ui.ui_stack[-1].global_position
	
	full_ui.set_top_ui(card_display)
	
	node_tween.tween_property(card_display, "scale", Vector2.ONE, .1)
	node_tween.tween_property(card_display, "modulate", Color.WHITE, .1)
	checked_card = card_display
	checked_card.connect("tree_exiting", reset_check)
	checking_card()

func remove_card():
	control_disapear(checked_card, .1, checked_card.global_position)

func checking_card():
	checking = true
	enter_check.emit()

func reset_check():
	checking = false
	exit_check.emit()

func control_hide(node: Node, timing: float = .1):
	var hide_tween: Tween = get_tree().create_tween()
	
	hide_tween.tween_property(node, "modulate", Color.TRANSPARENT, timing)

func control_disapear(node: Node, timing: float, old_position: Vector2 = Vector2.ZERO):
	var disapear_tween: Tween = get_tree().create_tween().set_parallel()
	
	disapear_tween.tween_property(node, "position", old_position, timing)
	disapear_tween.tween_property(node, "modulate", Color.TRANSPARENT, timing)
	disapear_tween.tween_property(node, "scale", Vector2(.1,.1), timing)
	
	await disapear_tween.finished
	
	node.queue_free()

func make_can_evo_from(evo: Base_Card) -> Callable:
	var evo_func: Callable = func can_evo_from(slot: PokeSlot):
		if slot.is_filled():
			if slot.check_override_evo(evo):
				return true
			return slot.current_card.name == evo.pokemon_properties.evolves_from
		else:
			return false
	return evo_func
