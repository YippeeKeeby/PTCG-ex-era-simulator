extends Resource
class_name BoardState

@export_enum("Win by taking", "Lose by Taking") var prize_rules: int = 0
@export var coin_rules: Consts.COIN_RULES = Consts.COIN_RULES.REG
@export_enum("Default", "Discard to Lost Zone", "Discard to Deck") var discard_rules: int = 0
@export_enum("Home", "Away", "Flip") var who_starts_first: int = 0
@export_flags("Home", "Away") var doubles: int = 3
@export var burn_rules: Consts.COND_RULES = Consts.COND_RULES.FLIP
@export var sleep_rules: Consts.COND_RULES = Consts.COND_RULES.FLIP
@export var confusion_rules: Consts.COND_RULES = Consts.COND_RULES.FLIP
@export var confusion_damage: int = 10
##Should the two players go through regular rules start?
##[br] Add a basic to active after drawing 7 cards
@export var default_start: bool = false
@export var debug_unlimit: bool = false
@export var stadium: Base_Card

@export var home_side: Consts.PLAYER_TYPES = Consts.PLAYER_TYPES.PLAYER
@export var home: SideState
@export var away_side: Consts.PLAYER_TYPES = Consts.PLAYER_TYPES.CPU
@export var away: SideState

func duplicate_sides():
	home = home.duplicate_deep(DeepDuplicateMode.DEEP_DUPLICATE_ALL)
	home.duplicate_slots()
	away = away.duplicate_deep(DeepDuplicateMode.DEEP_DUPLICATE_ALL)
	away.duplicate_slots()

func get_player_type(home_bool: bool) -> Consts.PLAYER_TYPES:
	return home_side if home_bool else away_side

func get_side(home_bool: bool) -> SideState:
	return home if home_bool else away
