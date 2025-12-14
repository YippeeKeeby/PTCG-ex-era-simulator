extends Control
class_name Tutor_Box

@export var stack_act: Consts.STACK_ACT
@export var stack: Consts.STACKS = Consts.STACKS.DECK

@onready var tutor_dock: Tutor_Dock = %tutor_dock
@onready var playing_list: PlayingList = %PlayingList

var header_txt: String
var footer_txt: String
var old_pos: Vector2
var search_dict: Dictionary [Identifier, Dictionary]
var allowed_dict: Dictionary[Dictionary, bool]
var choices_left: Dictionary[Dictionary, int]

func _ready() -> void:
	%Header.setup("[center]Tutor Box")
	%Footer.setup(footer_txt)

func setup_tutor(search: Search):
	if not (stack_act == Consts.STACK_ACT.TUTOR or stack_act == Consts.STACK_ACT.DISCARD):
		printerr("Why is setup tutor being called when there's no tutor on right now?")
		return
	
	#This will help the tutor list enable and disable the necessary cards
	for i in range(playing_list.all_lists.size()):
		var num_allowed: int = 0
		for item in playing_list.all_lists[i]:
			if playing_list.all_lists[i][item]:
				num_allowed += 1
		search_dict[search.of_this[i]] = playing_list.all_lists[i]
		allowed_dict[playing_list.all_lists[i]] = true
		choices_left[playing_list.all_lists[i]] = num_allowed
	
	#tutor = par.tutor_box.instantiate()
	tutor_dock.search = search
	tutor_dock.set_up_tutor()
	
	playing_list.set_items()

func list_allowed(card: Base_Card) -> bool:
	for list in playing_list.all_lists:
		if allowed_dict[list] and list[card]: return true
	
	return false

func check_lists(id: Identifier, allowed: bool, choices_made: int):
	allowed_dict[search_dict[id]] = allowed and choices_made < choices_left[search_dict[id]]
	playing_list.refresh_allowance()

func diff_tutor_blacklist(card: Base_Card, adding: bool = true):
	if adding:
		playing_list.black_list.append(card.name)
	else:
		playing_list.black_list.erase(card.name)
	playing_list.refresh_allowance()

func _on_tutor_dock_disapear() -> void:
	SignalBus.remove_top_ui.emit()
