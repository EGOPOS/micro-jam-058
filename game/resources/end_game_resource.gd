extends SellableResource

func on_visibility_changed():
	super()
	Global.endgame_founded.emit()
