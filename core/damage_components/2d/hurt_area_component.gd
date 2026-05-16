class_name HurtAreaComponent2D extends Area2D

@export var attack: Attack
@export var exceptions: Array[HitAreaComponent2D]

var attack_owner_id: int:
	set(value):
		attack_owner_id = value

signal hurted(area)

func _ready():
	var on_entered = (
	func(area):
		if area is HitAreaComponent2D and not exceptions.has(area):
			area.damage(attack)
			hurted.emit(area)
	)
	
	area_entered.connect(on_entered)

func add_exception(hit_area: HitAreaComponent2D):
	if exceptions.has(hit_area): return
	exceptions.append(hit_area)

func erase_exception(hit_area: HitAreaComponent2D):
	exceptions.erase(hit_area)

func clear_exceptions():
	exceptions.clear()
