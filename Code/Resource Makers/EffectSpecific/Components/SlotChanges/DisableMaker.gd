@icon("res://Art/ProjectSpecific/disabled.png")
@tool
extends SlotChange
class_name Disable

@export_group("Side Functions")
@export var card_type: Identifier
@export_group("Mon Functions")
@export var disable_body: bool  = false
@export var disable_power: bool = false
@export var disable_retreat: bool = false
@export_group("Attack")
##If this isn't -1, then the user must choose x ammount of attacks to disable,
##[br]if they have that many or less then disable all
@export var choose_num: int = -1
##[enum]Can[/enum] - Change nothing on the target's attacking ability
##[br][enum]Flip[/enum] - Target must now win a coinflip to attack
##[br][enum]Cant[/enum] - Target cannot attack
@export var attack: Consts.DIS_ATK = Consts.DIS_ATK.CAN
##If this is disabled it should be false
@export var disable_atk_effect: bool = false
##If this is filled with anything the disable will only work on specified attacks
@export var attack_names: Array[String]

func choose_atk_disable(slot: PokeSlot) -> void:
	var disable_box = Consts.mimic_box.instantiate()
	SignalBus.disable_attack.connect(create_attack_disable)
	disable_box.mimic = false
	disable_box.attacks = slot.get_pokedata().attacks
	disable_box.poke_slot = slot
	disable_box.position = Vector2(slot.ui_slot.global_position.x,0)
	Globals.full_ui.set_top_ui(disable_box)
	
	await SignalBus.disable_attack

func create_attack_disable(slot: PokeSlot, atk: Attack) -> void:
	var dis: Disable = self.duplicate()
	dis.attack_names.append(atk.name)
	
	slot.apply_slot_change(dis)

func check_bool(which: Consts.MON_DISABL) -> bool:
	match which:
		Consts.MON_DISABL.POWER:
			return disable_power
		Consts.MON_DISABL.BODY:
			return disable_body
		Consts.MON_DISABL.RETREAT:
			return disable_retreat
		Consts.MON_DISABL.ATTACK:
			return attack == Consts.DIS_ATK.CANT
		Consts.MON_DISABL.ATK_EFCT:
			return disable_atk_effect
	
	return false

func check_attack(which: Consts.DIS_ATK, atk_name: String) -> bool:
	if attack == Consts.DIS_ATK.CAN: return which == attack
	
	if attack_names.size() != 0:
		if atk_name in attack_names:
			return which == attack
		return false
	return which == attack

func check_atk_efct(atk_name: String):
	if attack_names.size() != 0:
		if atk_name in attack_names:
			return disable_atk_effect
		return false
	return disable_atk_effect

func how_display() -> Dictionary[String, bool]:
	return {"Disable" : true}

func describe() -> String:
	var final: String = str(recieves.print_ask(false)," get ")\
		if self.application == "Side" else ""
	var disables: Array[String]
	
	if card_type:
		disables.append(str("play ", card_type.description, "s"))
	
	if disable_power or disable_body or disable_retreat:
		var specific: Array[String]
		if disable_power and disable_body:
			specific.append("use poke-powers or poke-bodies")
		elif disable_power:
			specific.append("use poke-powers")
		elif disable_body:
			specific.append("use poke-bodies")
		if disable_retreat:
			specific.append("retreat")
		
		disables.append(Convert.combine_strings(specific, "or"))
	
	if attack != Consts.DIS_ATK.CAN:
		var attack_str: String
		
		attack_str = str("use", Convert.combine_strings(attack_names, "or")
			if attack_names.size() != 0 else " attacks")
		if attack == Consts.DIS_ATK.FLIP:
			attack_str += " unless you flip heads"
		
		disables.append(attack_str)
	
	if disable_atk_effect:
		if attack_names.size() == 0:
			disables.append("use attack effects")
		else:
			disables.append(str("use the effect of ",
				Convert.combine_strings(attack_names, "or")))
	
	print_rich(disables)
	final = str("Cannot ", Convert.combine_strings(disables))
	print_rich(final)
	return final
