class_name RepeatedHurtAreaComponent3D extends HurtAreaComponent3D

@export var repeat_rate: float = 0.5

func _ready():
	super()
	hurted.connect(repeat)

func repeat(hurted_area):
	await get_tree().create_timer(repeat_rate).timeout
	if hurted_area in get_overlapping_areas():
		area_entered.emit(hurted_area)
