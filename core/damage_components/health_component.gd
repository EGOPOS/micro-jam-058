class_name HealthComponent extends Node

@export var max_health: int
@onready var health: int = max_health:
	set(value):
		health = value
		health_value_changed.emit(health)
		if not health:
			health_end.emit()

signal health_value_changed(value)
signal health_changed(delta)
signal health_end()

func damage(attack: Attack):
	if not health: return
	
	health = max(health-attack.damage, 0)
	
	if health != 0:
		health_changed.emit(attack.damage) 
