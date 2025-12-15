@icon("res://Art/Energy/48px-Lightning-attack.png")
extends ScrollContainer

@export var check: bool = true
@export var attackItem: PackedScene
@export var ability_item: PackedScene
@export var poke_slot: PokeSlot
@export var current_card: Base_Card
@export var max_size: Vector2 = Vector2(420, 400)

@onready var current_height: float = 55

signal readied(current_size)

var resized_container: bool = false
var items: Array[Node] = []
var display_text: String = ""
var final_size: int = 0
var attacks: Array[Attack] = []

func _ready() -> void:
	#So it can be sued on a poke slot or not
	attacks = (poke_slot.get_pokedata().attacks if poke_slot 
	else current_card.pokemon_properties.attacks)
	
	set_items()
	size_default()

#Once every item is readied, wait before seeking final size
func _draw():
	await get_tree().process_frame
	if not resized_container:
		for item in items:
			current_height += item.size.y
		
		current_height = clamp(current_height, current_height, max_size.y)
		size.y = current_height
		resized_container = true
		readied.emit(current_height)

# Called when the node enters the scene tree for the first time.
func reset_items() -> void:
	for item in items:
		item.queue_free()

func set_items() -> void:
	#Get PokeBody
	if poke_slot:
		set_ability(poke_slot.get_pokedata().pokebody)
		set_ability(poke_slot.get_pokedata().pokepower)
	else:
		set_ability(current_card.pokemon_properties.pokebody)
		set_ability(current_card.pokemon_properties.pokepower)
	
	for item in attacks:
		set_attack(item)
	
	if poke_slot:
		for tm in poke_slot.tm_cards:
			set_attack(tm.trainer_properties.provided_attack, true)
	
	items = %CardList.get_children()

func set_attack(attack: Attack, tm: bool = false):
	var making = attackItem.instantiate()
	making.attack = attack
	making.slot = poke_slot
	making.card_name = poke_slot.get_card_name() if poke_slot else current_card.name
	%CardList.add_child(making)
	if check: making.focus_mode = FocusMode.FOCUS_NONE
	if poke_slot and poke_slot.is_active(): #only try this when attatched to a pokeslot
		making.check_usability()
	else: making.make_usable(false)
	if tm:
		making.attackButton.theme_type_variation = "TrainerButton"

func set_ability(ability: Ability):
	if ability:
		var ability_making = ability_item.instantiate()
		ability_making.ability = ability
		ability_making.slot = poke_slot
		ability_making.card_name = poke_slot.get_card_name() if poke_slot else current_card.name
		if check: ability_making.focus_mode = FocusMode.FOCUS_NONE
		%CardList.add_child(ability_making)

func size_default() -> void:
	size = Vector2(max_size.x, current_height)
