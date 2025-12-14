@icon("res://Art/Energy/48px-Colorless-attack.png")
extends Control

@onready var retreat_display: Array[Node] = %RetreatContainer.get_children()
@onready var button: Button = $PanelContainer/Button

var slot: PokeSlot
var attatched: bool = false
var retreat: int 

func set_retreat(new_slot: PokeSlot):
	attatched = true
	slot = new_slot
	retreat = slot.get_retreat()
	
	for i in range(retreat_display.size()):
		if i < retreat:
			retreat_display[i].show()
		else: retreat_display[i].hide()
	
	allow_retreat()

func allow_retreat():
	Globals.fundies.record_single_src_trg(slot)
	
	var result: bool = not slot.is_attacker() or not slot.is_active() or \
	slot.get_total_energy() < retreat or \
	slot.has_condition([Consts.TURN_COND.PARALYSIS, Consts.TURN_COND.ASLEEP])\
	or slot.check_bool_disable(Consts.MON_DISABL.RETREAT)
	
	button.disabled = result 
	Globals.fundies.remove_top_source_target()

func _on_button_pressed() -> void:
	if attatched:
		SignalBus.remove_top_ui.emit()
		SignalBus.retreat.emit(slot)
	else:
		printerr("This node apart of anything")

# May 8th 2025: I found the Emotacon section of the godot editor ᕦò_óˇ)ᕤ lol
