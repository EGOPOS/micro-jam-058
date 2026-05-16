extends Node

var cash: int = 400:
	set(value):
		cash = value
		cash_changed.emit()


signal cash_changed
