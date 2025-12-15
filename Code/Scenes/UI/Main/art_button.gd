extends Button

#--------------------------------------
#region VARIABLES
@export var pokemon: bool = true
@export var spawn_position: Vector2 = Vector2(230,25)
@export var benched: bool = false
@export_enum("Left","Right","Up","Down") var spawn_direction: int = 0

@onready var art: TextureRect = %Art
@onready var spawn_offsets: Array[Vector2] = [Vector2(-size.x / 2, 0),
 Vector2(size.x / 2,0), Vector2(0,-size.y / 2), Vector2(0,size.y / 2)]

var connected_ui: UI_Slot
var current_card: Base_Card:
	set(value):
		var old = current_card
		current_card = value
		disabled = value == null
		if value != old and value != null:
			%Art.texture = value.image
			var art_tween: Tween = create_tween().set_parallel()
			art.scale = Vector2.ZERO
			art_tween.tween_property(%Art, "scale", Vector2.ONE, .1)
		elif value == null:
			%Art.texture = null
#endregion
#--------------------------------------

#--------------------------------------
#region INITALIZATION & PROCESSING
func _ready():
	get_child(0).size = size
	if benched: 
		custom_minimum_size = Vector2(149, 96)
		art.custom_minimum_size = Vector2(142, 87)
		art.position = Vector2(4,3)

# Called when the node enters the scene tree for the first time.
func _gui_input(event):
	if event.is_action_pressed("A") and not disabled:
		if connected_ui and connected_ui.z_index > 0:
			SignalBus.chosen_slot.emit(connected_ui.connected_slot)
		elif current_card:
			Globals.show_slot_card(connected_ui.connected_slot)
	elif event.is_action_pressed("A"):
		pass

func _on_pressed() -> void:
	if pokemon:
		SignalBus.chosen_slot.emit(owner.connected_slot)
#endregion
#--------------------------------------

func ability_show(slot: PokeSlot):
	if not slot.is_filled():
		theme_type_variation = ""
		material.set_shader_parameter("base_color", Color(0.181, 0.121, 0.35))
		%AnimationPlayer.play("RESET")
	else:
		var poke_data: Pokemon = slot.get_pokedata()
		if poke_data.pokebody:
			theme_type_variation = "BodyButton"
			material.set_shader_parameter("base_color", Color(0.119, 0.263, 0.247))
			
			if slot.body_activated:
				%AnimationPlayer.play("BodyLoop")
			else:
				%AnimationPlayer.play("RESET")
		
		elif poke_data.pokepower:
			theme_type_variation = "PowerButton"
			material.set_shader_parameter("base_color", Color(0.267, 0.0, 0.024))
			
			if slot.is_attacker() and poke_data.pokepower.does_press_activate(slot):
				%AnimationPlayer.play("PowerLoop")
			else:
				%AnimationPlayer.play("RESET")
		else:
			theme_type_variation = ""
			material.set_shader_parameter("base_color", Color(0.181, 0.121, 0.35))
			%AnimationPlayer.play("RESET")

func ability_occur(body: bool, time: float):
	%AnimationPlayer.speed_scale = 6.0
	if body:
		%AnimationPlayer.play("BodyLoop")
	else:
		%AnimationPlayer.play("PowerLoop")
	
	await get_tree().create_timer(time).timeout
	
	%AnimationPlayer.speed_scale = 1.0
	%AnimationPlayer.play("RESET")
