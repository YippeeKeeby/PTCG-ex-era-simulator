extends PanelContainer

@onready var reorder_button: PanelContainer = get_child(0).get_child(1)
var index: int = 1:
	set(value):
		index = value
		%Index.clear()
		%Index.append_text(str(index,"."))
var card: Base_Card:
	set(value):
		if value != null:
			card = value
			reorder_button.card = value
			reorder_button.show_card()

signal check_reorder(node: Node)
signal drop_reorder()

func _ready() -> void:
	reorder_button.movable.drag.connect(emit_check)
	reorder_button.movable.drop.connect(emit_drop)

func emit_check() -> void:
	check_reorder.emit(self)

func emit_drop() -> void:
	drop_reorder.emit()
