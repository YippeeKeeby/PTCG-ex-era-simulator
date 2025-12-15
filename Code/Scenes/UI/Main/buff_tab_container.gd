extends TabContainer

func display_change(change: SlotChange):
	var dict: Dictionary[String, bool] = change.how_display()
	var key: String = dict.keys()[0]
	
	match key:
		"Atk":
			current_tab = 0
		"Def":
			current_tab = 1
		"HP":
			current_tab = 2
		"Cost":
			current_tab = 3
		"Disable":
			current_tab = 4
		"Override":
			current_tab = 5
		"TypeChange":
			current_tab = 3
		"RuleChange":
			current_tab = 5
		_:
			push_error("I don't know what kind of change this is")
	
	if key not in ["Atk", "Def", "HP", "Cost"]:
		modulate = Color.RED if dict[key] else Color.WHITE
	else:
		modulate = Color.AQUA if dict[key] else Color.ORANGE
