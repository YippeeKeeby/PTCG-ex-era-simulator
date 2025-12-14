@icon("res://Art/Coins/BreloomFirst.png")
extends Control

@export var coin_scene: PackedScene
@export var base_cooldown: float = 1
@export var growth_rate: float = 20
@export var speedup: Curve

@onready var top: PanelContainer = $VBoxContainer/Footer
@onready var bottom: PanelContainer = $VBoxContainer/Footer2
@onready var cooldown: Timer = $Cooldown
#@onready var margin_container: MarginContainer = %MarginContainer

var flip_results: Array[bool]
var shown_results: Dictionary[bool, int] = {true: 0, false: 0}

func _ready() -> void:
	#For testing coinflips will be done here
	#flip_results = coinflip.get_flip_array(coinflip.activate_CF())
	#debug results for extreme test
	#flip_results.resize(50)
	#flip_results.fill(true)
	#flip_results.append(false)
	#on implementation the result should be found beforehand
	
	top.setup("[center]Coinflips")
	bottom.setup(str("[center]Heads: ", shown_results[true],
	 " Tails: ", shown_results[false]))

func display_results(result: bool):
	shown_results[result] += 1
	bottom.setup(str("[center]Heads: ", shown_results[true],
	 " Tails: ", shown_results[false]))

func _on_begin_timeout() -> void:
	print("SHOWING: ", flip_results)
	for i in range(flip_results.size()):
		var curve_pos: float = float(i+1) / growth_rate
		
		%Coin.animation_player.speed_scale = 1 * (speedup.sample(curve_pos) * 10)
		%Coin.result = flip_results[i]
		%Coin.play_result()
		await %Coin.shown
		
		cooldown.wait_time = base_cooldown * (1 - speedup.sample(curve_pos))
		cooldown.start()
		await cooldown.timeout
		
		%Coin.heads.hide()
		%Coin.reset()
		display_results(flip_results[i])
	
	await get_tree().create_timer(base_cooldown).timeout
	SignalBus.finished_coinflip.emit()
	SignalBus.remove_top_ui.emit()
