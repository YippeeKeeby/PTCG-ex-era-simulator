@icon("res://Art/ExpansionIcons/40px-SetSymbolFireRed_and_LeafGreen.png")
extends Control
class_name UI_Slot

#--------------------------------------
#region VARIABLES
@export var active: bool = true
@export var player: bool = true
@export var home: bool = true
@export_enum("Left","Right","Up","Down") var list_direction: int = 0

@onready var name_section: RichTextLabel = %Name
@onready var max_hp: RichTextLabel = %MaxHP
@onready var tool: TextureRect = %Tool
@onready var tm: TextureRect = %TM
@onready var changes_display: Control = %ChangeDisplay
@onready var cond_display: ConditionDisplay = %Conditions
@onready var damage_counter: DamageCounter = %DamageCounter
@onready var typeContainer: Array[Node] = %TypeContainer.get_children()
@onready var energy_container: Array[Node] = %EnergyTypes.get_children()
@onready var list_offsets: Array[Vector2] = [Vector2(-size.x / 2, 0),
 Vector2(size.x / 2,0), Vector2(0,-size.y / 2), Vector2(0,size.y / 2)]

#Unfinished, doesn't account for special energy
var connected_slot: PokeSlot = PokeSlot.new()
var current_display: Node

#endregion
#--------------------------------------
# Called when the node enters the scene tree for the first time.
func _ready():
	%ArtButton.spawn_direction = list_direction
	if %ArtButton.benched: %ArtButton/PanelContainer.size = Vector2(149, 96)
	clear()
	connected_slot.slot_into(self)
	%ArtButton.connected_ui = self
	%Conditions.move_child(%ChangeDisplay, 0)

#--------------------------------------
#region ATTATCH
func attatch_pokeslot(slot: PokeSlot, initalize: bool):
	connected_slot = slot
	slot.slot_into(self, initalize)

func attatch_tool(tool_card: Base_Card):
	if tool_card:
		tool.show()
		tool.texture = tool_card.image

func attatch_tms(tms: Array[Base_Card]):
	tm.hide()
	
	if tms.size() > 0: #Show the latest attatched
		tm.show()
		tm.texture = tms[-1].image
	
	if tms.size() > 1:
		tm.get_child(0).show()
	else:
		tm.get_child(0).hide()

#endregion
#--------------------------------------

#--------------------------------------
#region ENERGY DISPLAY
func display_types(types: Array[String]):
	for node in typeContainer:
		node.hide()
	
	for i in range(types.size()):
		typeContainer[i].display_type(types[i])
		typeContainer[i].show()

func display_energy(energy_arr: Array, energy_dict: Dictionary):
	%EnergyTypes.display_energy(energy_arr, energy_dict)

#endregion
#--------------------------------------

#--------------------------------------
#region CONDITION DISPLAY
func display_condition():
	if connected_slot.is_filled():
		cond_display.show()
		cond_display.condition = connected_slot.applied_condition
	else: cond_display.hide()

#endregion
#--------------------------------------

func display_hp(current_max: int) -> void:
	var typical_max: int = connected_slot.get_pokedata().HP
	var hp_color: String
	
	if current_max != typical_max:
		hp_color = str("[color=",Color.AQUA.to_html() if current_max > typical_max else Color.RED.to_html(),"]")
	
	max_hp.clear()
	max_hp.append_text(str(hp_color, "HP: ", current_max,
	 "[/color]" if hp_color != null else ""))

#--------------------------------------
#region ART BUTTON FUNCTIONS
func check_ability_activation():
	%ArtButton.ability_show(connected_slot)

func ability_occured(is_body: bool, time: float):
	%ArtButton.ability_occur(is_body, time)

func switch_shine(value: bool):
	%ArtButton.material.set_shader_parameter("shine_bool", value)

func make_allowed(is_allowed: bool):
	if connected_slot.current_card == null and home:
		print()
	%ArtButton.disabled = not is_allowed

func display_image(card: Base_Card):
	%ArtButton.current_card = card
#endregion
#--------------------------------------

func clear():
	name_section.clear()
	max_hp.clear()
	display_image(null)
	display_types([])
	display_energy([],{})
	tm.hide()
	tool.hide()
	cond_display.condition = Condition.new()
	damage_counter.set_damage(0)
	display_condition()
	check_ability_activation()
