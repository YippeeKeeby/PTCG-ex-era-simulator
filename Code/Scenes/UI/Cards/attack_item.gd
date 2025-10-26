@icon("uid://dtnnvkljeid2t")
extends MarginContainer

@export var attack: Attack
@export var card_name: String

@onready var energy_icons: Array[Node] = %Types.get_children()
@onready var attackButton: Button = $AttackButton

var slot: PokeSlot

signal attack_with(attack: Attack)

# Called when the node enters the scene tree for the first time.
func _ready():
	%Types.scale = Vector2(.75, .75)
	if attack:
		set_attack()
	else:
		#for some reason preloading this stuff doesn't really work out
		attack = load("res://Resources/Components/Pokemon/Attacks/CommonAttacks/Bubble.tres")
		print(attack.name)
		set_attack()

func set_attack():
	%Name.clear()
	%Name.append_text(str("[center]",attack.name))
	
	%EffectText.clear()
	if attack.attack_data.description != "":
		var final_text: String = Convert.reformat(attack.attack_data.description, card_name)
		%EffectText.append_text(final_text)
		%EffectText.show()
	
	var final_cost = attack.get_energy_cost(slot)
	print("Current final Cost: ", final_cost)
	
	for icon in energy_icons:
		icon.hide()
	for i in range(final_cost.size()):
		energy_icons[i].display_type(final_cost[i])
		energy_icons[i].show()
	
	%Damage.clear()
	print(attack.attack_data.initial_main_DMG, attack.attack_data.modifier)
	if attack.attack_data.initial_main_DMG > 0:
		%Damage.append_text(str(attack.attack_data.initial_main_DMG))
		match attack.attack_data.modifier:
			1: %Damage.append_text("+")
			2: %Damage.append_text("x")
			3:
				%Damage.clear()
				%Damage.append_text(str("-",attack.attack_data.initial_main_DMG))

func check_usability():
	var result: bool = attack.condition_prevents(slot.applied_condition.turn_cond)\
	or not slot.is_attacker() or not attack.can_pay(slot) or \
	slot.check_attack_disable(Consts.DIS_ATK.CANT, attack.name)
	
	attackButton.disabled = result

func make_usable(value: bool):
	attackButton.disabled = not value

func make_unusable():
	attackButton.disabled = true

func _on_focus_entered():
	attackButton.grab_focus()

func _on_attack_button_pressed() -> void:
	Globals.full_ui.remove_top_ui()
	attack_with.emit(attack)
