extends Node3D

@export_category("resource")
@export var resource: SellableResource
@export var max_count: int = 6
@export var min_count: int = 3

@export_category("health")
@export var max_health: int = 6
@export var min_health: int = 3
@onready var health_component: HealthComponent = %HealthComponent

@onready var hit_area_component_3d: HitAreaComponent3D = %HitAreaComponent3D

func _ready() -> void:
	health_component.max_health = randi_range(min_health, max_health)
	health_component.health = health_component.max_health
	health_component.health_end.connect(on_health_end)
	
	health_component.health_changed.connect(on_health_changed)

func on_health_end():
	resource


func on_health_changed(delta):
	pass
