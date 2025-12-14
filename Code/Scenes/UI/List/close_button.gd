@icon("res://Art/ExpansionIcons/SetSymbolTeam_Magma_vs_Team_Aqua.png")
extends Button
class_name Close_Button

func _on_pressed() -> void:
	if get_parent() != get_tree().get_root():
		SignalBus.remove_top_ui.emit()
	else:
		printerr("The close button isn't a child of anything")

func closing_animation() -> void:
	disabled = true
	var closing_tween: Tween = create_tween().set_parallel()
	
	closing_tween.tween_property(owner, "scale", Vector2.ZERO, .1)
	closing_tween.tween_property(owner, "modulate", Color.TRANSPARENT, .1)
	
	await closing_tween.finished
