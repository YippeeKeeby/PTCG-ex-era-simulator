extends Control

@export var item_scene: PackedScene
@export var changes: Array[SlotChange]

func _ready():
	set_up()
	$PanelContainer/VBoxContainer.show()

func set_up():
	%Header.setup("CHANGES")
	%Footer.setup()
	for change in changes:
		var item = item_scene.instantiate()
		
		item.determine_change(change)
		
		%ChangeList.add_child(item)
