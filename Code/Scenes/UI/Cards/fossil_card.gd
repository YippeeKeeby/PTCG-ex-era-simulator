@icon("res://Art/ExpansionIcons/40px-SetSymbolSandstorm.png")
extends Control

#--------------------------------------
#region VARIABLES
@export var card: Base_Card
@export var checking: bool

@onready var pokeData: Pokemon = card.pokemon_properties
@onready var trainerData: Trainer = card.trainer_properties
@onready var display_name: RichTextLabel = %Name
@onready var extra_identifier: RichTextLabel = %Extra
@onready var max_hp = %HP
@onready var default_type = %DefaultType
@onready var art: TextureRect = %Art
@onready var class_text: RichTextLabel = %ClassText
@onready var effect_text: RichTextLabel = %Effect
@onready var illustrator: RichTextLabel = %Illustrator
@onready var number: RichTextLabel = %Number
@onready var rarity: TabContainer = %Rarity
@onready var set_type: TabContainer = %Set
@onready var attack_scroll: AttackScrollContainer = %AttackScrollBox
@onready var close_button: Close_Button = %CloseButton

var old_pos: Vector2
var poke_slot: PokeSlot
#endregion
#--------------------------------------
# Called when the node enters the scene tree for the first time.
func _ready():
	if poke_slot: 
		card = poke_slot.current_card
		SignalBus.force_disapear.connect(force_disapear)
	
	make_text(display_name, card.name)
	make_text(extra_identifier, "Fossil")
	make_text(max_hp, str("HP: ",pokeData.HP))
	default_type.display_type(Convert.flags_to_type_array(pokeData.type)[0])
	
	art.texture = card.image
	
	if card.illustrator != "":
		make_text(illustrator, str("Illus. ", card.illustrator))
	
	#What kind of class text should be input if any
	var final_class_txt: String
	if trainerData.specific_requirement == "":
		var index: int = Consts.trainer_classes.find(trainerData.considered)
		final_class_txt = Consts.class_texts[index]
	final_class_txt += Convert.reformat(trainerData.specific_requirement, card.name)
	make_text(class_text, final_class_txt)
	
	var final_text: String = Convert.reformat(trainerData.description, card.name)
	make_text(effect_text, final_text)
	
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
	
	make_text(number, str(card.number, "/", Consts.expansion_counts[card.expansion]))
	rarity.current_tab = card.rarity
	set_type.current_tab = card.expansion
	
	if checking: %Movable.show()

func edit_attack_size(final_size: float) -> void:
	%Attacks.get_parent().custom_minimum_size.y = final_size

func make_text(node: RichTextLabel, text: String):
	node.clear()
	node.append_text(text)

func _on_tree_exiting() -> void:
	Globals.checking = false

func force_disapear():
	SignalBus.remove_top_ui.emit()
