extends Resource
class_name Placement

@export_category("Location")
##Will the chosen cards be placed in a stack or in a pokeslot
@export_enum("Stack", "Slot") var which: int = 0
##This variable dtermines where deck placements should go[br]
##Keep this as false if the deck is going to be shuffled regardless
@export var top_deck: bool = false
@export var stack: Consts.STACKS = Consts.STACKS.DECK
##What choices does the user have when placing in slots
@export var slot_ask: SlotAsk
@export var anyway_u_like: bool = false

@export_group("And then")
#Might not be necessary
@export_flags("Basic", "Evolution", 
"Item", "Supporter","Stadium", "Tool", "TM", "RSM",
 "Fossil", "Energy") var use_as: int = 0

##Which cards are sent to be reoerdered?
@export_enum("None", "Reorder Chosen", "Reorder Nonchosen", "Both") var reorder_type: int = 0
@export var shuffle: bool = true
##Apply the effects of evolution on this card,
##otherwise it'll just swap current card
@export var evolve: bool = false
@export var mini_effect: MiniEffect

@warning_ignore("unused_signal")
signal finished
