extends Node

#--------------------------------------
#region TEXT
const condition_power_txt: String = " This power can't be used if [name]\
 is affected by a Special Condition."
const supporter_txt: String = "You can play only one Supporter card each turn.\
 When you play this card, put it next to your Active Pokémon.\
 When your turn ends, discard this card."
const tool_txt: String = "to 1 of your Pokémon that doesn't already have a Pokémon Tool\
 attached to it. If that Pokémon is Knocked Out, discard this card."
const tm_txt: String = "Attach this card to 1 of your Evolved Pokémon\
 (excluding Pokémon-ex and Pokémon that has an owner in its name) in play.\
 That Pokémon may use this card's attack instead of its own. At the end of your turn, discard "
const stadium_txt: String = "This card stays in play when you play it.\
 Discard this card if another Stadium card comes into play."
const trainer_classes: Array[String] = ["Item", "Supporter", "Tool", "Stadium", "TM",
 "Rocket's Secret Machine"]
#Items and RSM don't have class text
const class_texts: Array[String] = ["", supporter_txt, tool_txt, stadium_txt, tm_txt, ""]
#endregion
#--------------------------------------

#--------------------------------------
#region EXPANSIONS
#Order goes from the 16 ex expansions, 5 POP Series then Black star
const expansion_abbreviations: Array[String] = ["RS","SS","DR","MA","HL",
"RG","TRR","DX","EM","UF","DS","LM","HP","CG","DF","PK",
"POP1","POP2","POP3","POP4","POP5","NP"]
const expansion_counts: Array[int] = [109, 100, 97, 95, 101, 112, 109, 107,
106, 115, 113, 92, 110, 110, 101, 108, 17, 17, 17, 17, 17, 40]
const expansion_secrets: Array[int] = [0,0,3,2,1,4,2,1,1,2,1,1,1,0,0,0,0,0,0,0,0,0]
const unknown_number: int = 28
#endregion
#--------------------------------------

#--------------------------------------
#region ENERGY
const energy_types: Array[String] = ["Grass", "Fire", "Water", "Lightning",
 "Psychic", "Fighting", "Darkness", "Metal", "Colorless", "Rainbow", "Magma",
 "Aqua", "Dark Metal","FF", "GL", "WP", "React"]
const energy_character: Array[String] = ["G","R","W","L","P","F","D","M","C"]
#const energy_icons = ["uid://cujjluirx6yyu", "uid://dd1ywu5fsfsq1",
 #"uid://dj2lgcygk1ups","uid://bqqg7qjfq0wqb", "uid://bnpgukh0in14j",
 #"uid://chqgfpirjsldj", "uid://bkb5vi5elppq1","uid://gom7mkykamch",
 #"uid://dht4h5jns71o5"]
const energy_icons: Array[String] = ["uid://c20k4b4y15w3x","uid://dtnnvkljeid2t",
"uid://wpjiv54hdt5b","uid://ci2r25wupuafk","uid://bffmv3e0yprej","uid://okr70los20g3",
"uid://b8n2mui1fj4ii", "uid://bscav8ynwl2g3", "uid://dprdtmqbaot04"]

const energy_colors: Array[Color] = [Color.GREEN, Color.RED, Color.AQUA,
 Color.YELLOW, Color.PURPLE, Color.ORANGE_RED, Color.DARK_SLATE_GRAY,
 Color.GRAY, Color.WHITE_SMOKE, Color.VIOLET, Color.WEB_MAROON,
 Color.DARK_BLUE, Color.CRIMSON, Color.ORANGE_RED, Color.YELLOW_GREEN,
 Color.MEDIUM_SLATE_BLUE, Color.DEEP_SKY_BLUE]
#endregion
#--------------------------------------

#--------------------------------------
#region SCENES
var playing_button: PackedScene = load("uid://dnk7pe6vmdplw")
var reg_list: PackedScene = load("uid://db62dvlhio3c1")
const attack_list_comp: PackedScene = preload("uid://cj0k023dhlha")
const poke_card : PackedScene = preload("uid://crecmsup0hxcr")
const trainer_card: PackedScene = preload("uid://b6b86gpw8bfpk")
const energy_card: PackedScene = preload("uid://ttnrn3dc8bsv")
const fossil_card: PackedScene = preload("uid://cuk0xlukc37h7")
const tutor_box: PackedScene = preload("uid://ctqlcem1xc7v3")
const reorder_list: PackedScene = preload("uid://u1576g11rakh")
var swap_box: PackedScene = load("uid://mkvxdbo067mv")
const attatch_box: PackedScene = preload("uid://de4ao144ctqav")
const discard_box: PackedScene = preload("uid://bkg68bp6fvny")
const reg_flip_box: PackedScene = preload("uid://de0rjixsixmm6")
const until_flip_box: PackedScene = preload("res://Scenes/UI/Coins/until_box.tscn")
const prompt_answer: PackedScene = preload("uid://cu6ufo2qfh3pr")
const cpu_scene: PackedScene = preload("uid://us8t6lxi3vvn")
const dmg_manip_box: PackedScene = preload("uid://b6nlwnw1moteh")
const mimic_box: PackedScene = preload("uid://cvh086w8yapm0")
const mimic_card_box: PackedScene = preload("uid://dgns62nhwgtvq")
const input_number: PackedScene = preload("uid://bihasri21bdv")
var input_condition: PackedScene = load("uid://7cdjjog7dndn")
#endregion
#--------------------------------------

#--------------------------------------
#region ENUMS
enum PLAYER_TYPES{PLAYER, ##HUMAN CONTROLLED 
 CPU, ## CPU CONTROLLED
 DUMMY ## SPECIFIC CPU THAT ALWAYS CHOOSES EASIEST OPTION FOR DEBUGGING
}
enum SIDES {NONE, ##IGNORE FIELD AND TAKE DEFAULT
 ATTACKING,##IS FOR THE PLAYER WHOSE TURN IT IS
 DEFENDING,##IS THE OTHER GUY
 BOTH, ##TAKE IN EVERY SLOT THAT FITS SPECIFIERS
 SOURCE, ##ONLY TAKE IN WHOEVER CALLED EFFECT NO MATTER SIDE
 OTHER ##WHICHEVER SIDE DIDN'T CALL THE EFFECT
}
enum SLOTS {NONE,##Ignore and use the default
 TARGET,##Refers to  pokemon involved in attacks and effects
 ACTIVE,##Refers to the pokemon in the Active Slot
 BENCH,##Refers to pokemon in the bench
 ALL,##Refers to any pokemon in the dedicated side
 REST ##Refers to any pokemon not involves with attacks or effects
}
enum STACKS{HAND, ##CARDS HERE CAN BE PLAYED UNDER THE RIGHT CONDITIONS
  DECK, ##CARDS MUST EITHER BE DRAWN OR TUTORED. ALL CRADS BEGIN HERE
  DISCARD, ##AFTER A CARD IS USED, KO'd OR PAYS FOR ANY DISCARD COSTS
  PRIZE, ##AFTER SETTING UP, PUT X PRIZE CARDS HERE TO TAKE AFTER KO
  PLAY, ##ANY CARD THAT ISN'T IN A STACK
  LOST, ##THE LOST ZONE, NOT ANY CARD THAT CANNOT BE RETRIEVED FOR FUTURE USE
  ANY,
  NONE
}
enum STACK_ACT{PLAY,##ALLOWED CARDS CAN BE PLAYED ONTO THE BOARD
	TUTOR, ##ALLOWED CARDS WILL BE SENT TO ANOTHER DESTINATION
	DISCARD, ##ALLOWED CARDS WILL BE SENT TO DISCARD PILE
	LOOK, ##NOT ALLOWED TO INTERACT WITH CARDS
	REORDER, ##REARRANGE CARDS AS NECESSARY
	ENSWAP, ##SELECT CARDS TO SWAP IN THE SWAP BOX
	MIMIC
}
enum COIN_RULES{REG,
	HEADS,
	TAILS,
	ALTERNATE
}
enum TURN_COND{NONE,
	PARALYSIS,
	ASLEEP,
	CONFUSION
}
enum COND_RULES{NONE, ##Condition doesn't clear on it's own
	TURN_PASS, ##Condition clears at the end of the target side's turn
	FLIP, ##Coinflip heads once in order to clear condition
	TWOFLIP ##Coinflip heads twice in order to clear condition
}
enum EFFECTS{CONDITION, BUFF, DISRUPT, DISABLE, 
 ENMOV, DMGMANIP, SEARCH, SWAP, DRAW, ALLEVIATE, MIMIC, 
 OVERRIDE, CHEATPLAY, TYPECHANGE, RULECHANGE, OTHER}
#Buff
enum STAT_BUFFS{ATTACK, DEFENSE, HP, RETREAT}
enum IMMUNITIES{ATK_EFCT_OPP,
	PWR_EFCT_OPP,
	BDY_EFCT_OPP,
	TR_EFCT_OPP,
	DMG_OPP,
	EVEN,
	ODD
}
enum MON_DISABL{
	POWER,
	BODY,
	RETREAT,
	ATTACK,
	ATK_EFCT
}
enum DIS_ATK {CAN, CANT, FLIP}

enum CONDITIONS{
	POISION,
	BURN,
	PARALYZE,
	SLEEP,
	CONFUSION,
	IMPRISION,
	SHOCKWAVE
}

#endregion
#--------------------------------------

#--------------------------------------
#region ETC
const rarity: Array[String] = ["Common", "Uncommon", "Rare",
 "Holofoil Rare", "ex Rare", "Ultra Rare", "Star Rare", "Promo Rare"]
const allowed_list_flags: Array[String] = ["Basic", "Evolution",
 "Item", "Support","Stadium", "Tool", "TM", "RSM", "Fossil", "Energy"]
#endregion
#--------------------------------------
