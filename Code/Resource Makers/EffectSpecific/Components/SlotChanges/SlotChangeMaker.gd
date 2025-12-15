@tool
extends Resource
class_name SlotChange

#Shared by: Buff, Disable, Override, TypeChange, RuleChange

##How will this change be applied?[br]
##[enum Slot] Apply change to slots that meet [member recieves].[br]
##*Best for attacks that only apply chnages at the very moment they attack[br]
##*Energy which only apply to the slot that has them[br]
##[enum Side] Apply the change to a side so it only clears after conditions for making it fail.
##[br]Best for ability passives which are active as long as thier condition are met

@export_enum("Slot", "Side") var application: String = "Slot"
##Who recieves this change
@export var recieves: SlotAsk
##-1 means ignore duration, check a prompt/ask to see if the effect should continue
##[br]-2 means forever, no conditions need to be checked afterwards
##[br]otherwise the effect lasts for this many turns 
@export var duration: int = -1
@export_tool_button("Describe") var button: Callable = describe

signal finished

func _init():
	print(describe())
	#button = Callable(self, "describe")

func play_effect(reversable: bool = false, replace_num: int = -1) -> void:
	print("PLAY ", self.get_script().get_global_name())
	
	#Who should have this effects applied?
	if application == "Slot":
		var apply_to: Array[PokeSlot] = Globals.full_ui.get_ask_minus_immune(recieves, Consts.IMMUNITIES.ATK_EFCT_OPP)
		
		if self is Disable and self.choose_num != -1:
			var dis = self as Disable
			for slot in apply_to:
				await dis.choose_atk_disable(slot)
		else:
			for slot in apply_to:
				slot.apply_slot_change(self)
		
	else:
		Globals.fundies.apply_change(recieves, self)
	
	finished.emit()

func how_display() -> Dictionary[String, bool]:
	match get_script().get_global_name():
		"Disable":
			return {"Disable" : true}
		"Override":
			return {"Override" : false}
		"TypeChange":
			return {"TypeeChange" : false}
	
	return {"RuleChange" : true}

func describe() -> String:
	print("HUH?")
	return "huh?"
