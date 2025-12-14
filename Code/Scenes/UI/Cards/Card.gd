@icon("res://Art/ExpansionIcons/40px-SetSymbolFireRed_and_LeafGreen.png")
extends Control

@export var poke_slot: PokeSlot
@export var card: Base_Card
@export var checking: bool = true

#--------------------------------------
#region ONREADY VARIABLES
@onready var pokedata: Pokemon = card.pokemon_properties

@onready var default_types: Array[Control] = [%DefaultType, %DefaultType2]
@onready var weakness_nodes: Array[Node] = %Weaknesses.get_children()
@onready var resistance_nodes: Array[Node] = %Resistances.get_children()
@onready var ruleboxes: Array[Node] = %Ruleboxes.get_children()
@onready var display_name: RichTextLabel = %Name
@onready var extra_identifier: RichTextLabel = %Extra
@onready var max_hp: RichTextLabel = %HP
@onready var evoFrom: RichTextLabel = %EvoFrom
@onready var illustrator: RichTextLabel = %Illustrator
@onready var number: RichTextLabel = %Number
@onready var rarity: TabContainer = %Rarity
@onready var set_type: TabContainer = %Set
@onready var retreat_button: Control = %RetreatButton
@onready var retreat_container: HBoxContainer = %RetreatContainer
@onready var art: TextureRect = %Art
@onready var use_as_energy: PanelContainer = %UseAsEnergy
@onready var attack_scroll =  %AttackBox
@onready var movable: Button = %Movable
@onready var close_button: Close_Button = %CloseButton

var old_pos: Vector2
var attack_size: int
var on_card: bool = false

#endregion
#--------------------------------------

func _ready():
	if poke_slot: 
		card = poke_slot.current_card
		SignalBus.force_disapear.connect(force_disapear)
	pokedata = card.pokemon_properties
	#To fit multiple types in
	#--------------------------------------
	#region ENERGY SYMBOL MANAGEMENT
	var types: Array[String] = Convert.flags_to_type_array(pokedata.type)
	var weaknesses: Array[String] = Convert.flags_to_type_array(pokedata.weak)
	var resistances: Array[String] = Convert.flags_to_type_array(pokedata.resist)
	
	for i in range(types.size()):
		default_types[i].display_type(types[i])
		default_types[i].show()
	
	for i in range(weaknesses.size()):
		weakness_nodes[i].display_type(weaknesses[i])
		weakness_nodes[i].show()
	
	for i in range(resistances.size()):
		resistance_nodes[i].display_type(resistances[i])
		resistance_nodes[i].show()
	
	if poke_slot:
		retreat_button.set_retreat(poke_slot)
		retreat_button.allow_retreat()
	else:
		retreat_button.hide()
		%RetreatCost.show()
		for i in range(pokedata.retreat):
			retreat_container.get_child(i).show()
	#endregion
	#--------------------------------------
	
	#--------------------------------------
	#region ATTACK NODE
	if poke_slot:
		attack_scroll.poke_slot = poke_slot
	attack_scroll.current_card = card
	attack_scroll.check = checking
	attack_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	attack_scroll.set_items()
	
	#endregion
	#--------------------------------------
	
	if card.energy_properties:
		use_as_energy.show()
		use_as_energy.setup(card.energy_properties)
	else: use_as_energy.hide()
	
	#--------------------------------------
	#region SIMPLE EDITS
	make_text(display_name, card.name)
	make_text(max_hp, str("HP: ",pokedata.HP))
	
	if pokedata.considered & 2: ruleboxes[0].show()
	if pokedata.considered & 4: make_text(extra_identifier, "Baby")
	if pokedata.considered & 8: make_text(extra_identifier, "Delta")
	if pokedata.considered & 16: ruleboxes[1].show()
	
	art.texture = card.image
	
	make_text(illustrator, str("[right]Illus. ", card.illustrator))
	if pokedata.evolves_from != "":
		make_text(evoFrom, str("Evolves from ", pokedata.evolves_from))
	else: evoFrom.clear()
	
	make_text(number, str("[right]",card.number, "/", Consts.expansion_counts[card.expansion]))
	rarity.current_tab = card.rarity
	set_type.current_tab = card.expansion
	
	if checking: %Movable.show()
	
	#endregion
	#--------------------------------------
	
	pivot_offset = size / 2

#--------------------------------------
#region HELPER FUNCTIONS
func edit_attack_size(final_size: float) -> void:
	%Attacks.get_parent().custom_minimum_size.y = final_size

func make_text(node: RichTextLabel, text: String):
	node.clear()
	node.append_text(text)

#endregion
#--------------------------------------

func force_disapear():
	SignalBus.remove_top_ui.emit()
