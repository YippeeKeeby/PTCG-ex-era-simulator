@icon("res://Art/Energy/48px-Water-attack.png")
extends MarginContainer

@export var body_icon: CompressedTexture2D
@export var ability: Ability
@export var slot: PokeSlot
@export var card_name: String

@onready var ability_button: Button = $AbilityButton

# Called when the node enters the scene tree for the first time.
func _ready():
	%Name.clear()
	%Name.append_text("[center]")
	
	if ability.category == "Body":
		%Icon.texture = body_icon
		%Name.push_color(Color(0.639, 0.875, 0.447))
		ability_button.set_theme_type_variation("BodyButton")
	else:
		%Name.push_color(Color(0.895, 0.583, 0.625))
	
	%Name.append_text(ability.name)
	%EffectText.clear()
	if ability.description != "":
		var using: String = ability.description
		if ability.affected_by_condition:
			using += Convert.reformat(Consts.condition_power_txt, card_name)
		
		var final_text: String = Convert.reformat(using, card_name)
		%EffectText.append_text(final_text)
		%EffectText.show()
	
	check_pressable()

func check_pressable():
	if ability.occurance or ability.category == "Body":
		ability_button.disabled = true
		return
	else:
		print(slot.power_ready, slot.power_exhaust)
		ability_button.disabled = not slot.power_ready or slot.power_exhaust

func check_allowed():
	if ability.prompt:
		return ability.prompt.check_prompt()

func _on_focus_entered():
	ability_button.grab_focus()

func _on_ability_button_pressed() -> void:
	print("Press!")
	SignalBus.remove_top_ui.emit()
	slot.use_ability(ability)
